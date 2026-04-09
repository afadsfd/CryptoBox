from datetime import timedelta
from typing import Optional
from uuid import UUID

from sqlalchemy import func, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.user import User
from app.utils.security import (
    hash_password,
    verify_password,
    create_access_token,
    create_refresh_token,
    verify_token,
    hash_refresh_token,
    verify_refresh_token_hmac,
)
from app.utils.exceptions import (
    AuthenticationError,
    ValidationError,
    ConflictError,
)
from app.config import settings


class AuthService:
    """Authentication service for user registration, login, and token management."""

    def __init__(self, db: AsyncSession):
        self.db = db

    async def register(
        self, email: str, password: str, name: Optional[str] = None
    ) -> tuple[User, str, str]:
        """
        Register a new user.

        Args:
            email: User's email address
            password: User's password (plain text)
            name: User's display name (optional)

        Returns:
            tuple: (user, access_token, refresh_token)

        Raises:
            ValidationError: If email already exists
        """
        email = email.strip().lower()

        existing_user = await self.get_user_by_email(email)
        if existing_user:
            raise ConflictError("Email already registered")

        password_hash = hash_password(password)

        user = User(
            email=email,
            password_hash=password_hash,
            name=name,
            auth_provider="email",
        )
        self.db.add(user)
        try:
            await self.db.commit()
        except IntegrityError:
            await self.db.rollback()
            raise ConflictError("Email already registered")
        await self.db.refresh(user)

        # Generate tokens
        access_token, refresh_token = await self._generate_and_store_tokens(user)

        return user, access_token, refresh_token

    async def login(self, email: str, password: str) -> tuple[User, str, str]:
        """
        Authenticate user with email and password.

        Args:
            email: User's email address
            password: User's password (plain text)

        Returns:
            tuple: (user, access_token, refresh_token)

        Raises:
            AuthenticationError: If credentials are invalid
        """
        # Find user by email
        user = await self.get_user_by_email(email)
        if not user:
            raise AuthenticationError("Invalid email or password")

        # Check if user is active
        if not user.is_active:
            raise AuthenticationError("Account is disabled")

        # Verify password
        if not user.password_hash or not verify_password(password, user.password_hash):
            raise AuthenticationError("Invalid email or password")

        # Generate tokens
        access_token, refresh_token = await self._generate_and_store_tokens(user)

        return user, access_token, refresh_token

    async def refresh_token(self, refresh_token: str) -> tuple[str, str]:
        """
        Refresh access token using a valid refresh token.

        Args:
            refresh_token: The refresh token

        Returns:
            tuple: (new_access_token, new_refresh_token)

        Raises:
            AuthenticationError: If refresh token is invalid or expired
        """
        # Verify refresh token
        payload = verify_token(refresh_token)
        if not payload:
            raise AuthenticationError("Invalid or expired refresh token")

        # Check token type
        if payload.get("type") != "refresh":
            raise AuthenticationError("Invalid token type")

        user_id = payload.get("sub")
        if not user_id:
            raise AuthenticationError("Invalid token payload")

        try:
            parsed_id = UUID(user_id)
        except (ValueError, AttributeError):
            raise AuthenticationError("Invalid token payload")

        # Lock row to serialize concurrent refreshes for the same user (token rotation)
        result = await self.db.execute(
            select(User).where(User.id == parsed_id).with_for_update()
        )
        user = result.scalar_one_or_none()
        if not user or not user.is_active:
            raise AuthenticationError("User not found or inactive")

        # Verify that the refresh token fingerprint matches (token rotation)
        if not user.refresh_token_hash:
            raise AuthenticationError("Refresh token revoked")

        if not verify_refresh_token_hmac(refresh_token, user.refresh_token_hash):
            raise AuthenticationError("Refresh token revoked or invalid")

        # Generate new tokens
        access_token, new_refresh_token = await self._generate_and_store_tokens(user)

        return access_token, new_refresh_token

    async def logout(self, user_id: UUID) -> None:
        """
        Logout user by invalidating refresh token.

        Args:
            user_id: User's UUID
        """
        user = await self.get_user_by_id(user_id)
        if user:
            user.refresh_token_hash = None
            await self.db.commit()

    async def get_user_by_id(self, user_id: UUID) -> Optional[User]:
        """
        Get user by ID.

        Args:
            user_id: User's UUID

        Returns:
            User object or None
        """
        result = await self.db.execute(select(User).where(User.id == user_id))
        return result.scalar_one_or_none()

    async def get_user_by_email(self, email: str) -> Optional[User]:
        """
        Get user by email.

        Args:
            email: User's email address

        Returns:
            User object or None
        """
        result = await self.db.execute(
            select(User).where(func.lower(User.email) == email.lower())
        )
        return result.scalar_one_or_none()

    async def _generate_and_store_tokens(self, user: User) -> tuple[str, str]:
        """
        Generate access and refresh tokens, and store refresh token hash.

        Args:
            user: User object

        Returns:
            tuple: (access_token, refresh_token)
        """
        # Create token payload
        token_data = {"sub": str(user.id), "email": user.email}

        # Generate tokens
        access_token = create_access_token(token_data)
        refresh_token = create_refresh_token(token_data)

        # Store refresh token fingerprint (HMAC; avoids bcrypt 72-byte truncation on long JWTs)
        # 单字段仍表示「当前唯一有效 refresh」；with_for_update 缓解并发刷新竞态。
        user.refresh_token_hash = hash_refresh_token(refresh_token)
        await self.db.commit()

        return access_token, refresh_token

    async def create_oauth_user(
        self,
        email: str,
        name: Optional[str],
        auth_provider: str,
        provider_id: Optional[str] = None,
    ) -> tuple[User, str, str]:
        """
        Create or get user from OAuth provider (Google/Apple).

        Args:
            email: User's email from OAuth provider
            name: User's name from OAuth provider
            auth_provider: "google" or "apple"
            provider_id: Provider-specific user ID

        Returns:
            tuple: (user, access_token, refresh_token)
        """
        # Check if user already exists
        user = await self.get_user_by_email(email)

        if user:
            if user.password_hash and (user.auth_provider or "email") == "email":
                raise ValidationError(
                    "This email is already registered with a password. "
                    "Sign in with email and password."
                )
            if user.auth_provider and user.auth_provider != auth_provider and user.auth_provider != "email":
                raise ValidationError(
                    f"This email is already registered via {user.auth_provider}. "
                    f"Please sign in with {user.auth_provider}."
                )
            if user.auth_provider == "email" and not user.password_hash:
                user.auth_provider = auth_provider
                await self.db.commit()
        else:
            # Create new user without password (OAuth)
            user = User(
                email=email,
                name=name,
                auth_provider=auth_provider,
                password_hash=None,
            )
            self.db.add(user)
            try:
                await self.db.commit()
            except IntegrityError:
                await self.db.rollback()
                user = await self.get_user_by_email(email)
                if not user:
                    raise AuthenticationError("Registration failed, please try again")
            await self.db.refresh(user)

        # Generate tokens
        access_token, refresh_token = await self._generate_and_store_tokens(user)

        return user, access_token, refresh_token
