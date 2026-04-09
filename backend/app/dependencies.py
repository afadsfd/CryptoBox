from typing import Optional
from uuid import UUID

from fastapi import Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models.user import User
from app.services.auth_service import AuthService
from app.utils.security import verify_token
from app.utils.exceptions import AuthenticationError

# Security scheme for JWT token
security = HTTPBearer(auto_error=False)


async def get_current_user(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(security),
    db: AsyncSession = Depends(get_db)
) -> User:
    """
    Get current authenticated user from JWT token.
    Returns User model instance.

    Raises:
        AuthenticationError: If token is invalid, expired, or user not found
    """
    if not credentials:
        raise AuthenticationError("Authentication required")

    token = credentials.credentials
    payload = verify_token(token)

    if not payload:
        raise AuthenticationError("Invalid or expired token")

    # Check token type
    if payload.get("type") != "access":
        raise AuthenticationError("Invalid token type")

    user_id = payload.get("sub")
    if not user_id:
        raise AuthenticationError("Invalid token payload")

    try:
        parsed_id = UUID(user_id)
    except (ValueError, AttributeError):
        raise AuthenticationError("Invalid token payload") from None

    # Get user from database
    auth_service = AuthService(db)
    user = await auth_service.get_user_by_id(parsed_id)

    if not user:
        raise AuthenticationError("User not found")

    if not user.is_active:
        raise AuthenticationError("Account is disabled")

    return user


async def get_optional_user(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(security),
    db: AsyncSession = Depends(get_db)
) -> Optional[User]:
    """
    Get current user if authenticated, otherwise return None.
    Useful for endpoints that work for both authenticated and anonymous users.
    """
    if not credentials:
        return None

    try:
        return await get_current_user(credentials, db)
    except AuthenticationError:
        return None
