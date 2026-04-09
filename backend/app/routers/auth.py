import httpx
from fastapi import APIRouter, Depends
from jose import jwk, jwt
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.dependencies import get_current_user
from app.models.user import User
from app.schemas.auth import (
    RegisterRequest,
    LoginRequest,
    TokenResponse,
    UserResponse,
    RefreshTokenRequest,
    OAuthRequest,
)
from app.schemas.common import APIResponse
from app.config import settings
from app.services.auth_service import AuthService
from app.services.user_service import UserService
from app.utils.exceptions import AuthenticationError

router = APIRouter(prefix="/auth", tags=["Authentication"])


@router.post("/register", response_model=APIResponse[TokenResponse])
async def register(
    request: RegisterRequest,
    db: AsyncSession = Depends(get_db)
) -> APIResponse[TokenResponse]:
    """
    Register a new user with email and password.

    - **email**: Valid email address (must be unique)
    - **password**: Password (minimum 8 characters)
    - **name**: Optional display name
    """
    auth_service = AuthService(db)
    user, access_token, refresh_token = await auth_service.register(
        email=request.email,
        password=request.password,
        name=request.name,
    )

    return APIResponse(
        success=True,
        data=TokenResponse(
            access_token=access_token,
            refresh_token=refresh_token,
            token_type="bearer",
        ),
        message="User registered successfully",
    )


@router.post("/login", response_model=APIResponse[TokenResponse])
async def login(
    request: LoginRequest,
    db: AsyncSession = Depends(get_db)
) -> APIResponse[TokenResponse]:
    """
    Login user with email and password.

    - **email**: Registered email address
    - **password**: User's password
    """
    auth_service = AuthService(db)
    user, access_token, refresh_token = await auth_service.login(
        email=request.email,
        password=request.password,
    )

    return APIResponse(
        success=True,
        data=TokenResponse(
            access_token=access_token,
            refresh_token=refresh_token,
            token_type="bearer",
        ),
        message="Login successful",
    )


@router.post("/refresh", response_model=APIResponse[TokenResponse])
async def refresh_token(
    request: RefreshTokenRequest,
    db: AsyncSession = Depends(get_db)
) -> APIResponse[TokenResponse]:
    """
    Refresh access token using a valid refresh token.

    - **refresh_token**: Valid refresh token from login/register
    """
    auth_service = AuthService(db)
    access_token, new_refresh_token = await auth_service.refresh_token(
        refresh_token=request.refresh_token,
    )

    return APIResponse(
        success=True,
        data=TokenResponse(
            access_token=access_token,
            refresh_token=new_refresh_token,
            token_type="bearer",
        ),
        message="Token refreshed successfully",
    )


@router.get("/me", response_model=APIResponse[UserResponse])
async def get_me(
    current_user: User = Depends(get_current_user)
) -> APIResponse[UserResponse]:
    """
    Get current authenticated user's information.
    Requires valid access token in Authorization header.
    """
    return APIResponse(
        success=True,
        data=UserResponse.model_validate(current_user),
        message="User retrieved successfully",
    )


@router.post("/logout", response_model=APIResponse)
async def logout(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
) -> APIResponse:
    """
    Logout user by invalidating refresh token.
    Requires valid access token in Authorization header.
    """
    auth_service = AuthService(db)
    await auth_service.logout(current_user.id)

    return APIResponse(
        success=True,
        message="Logout successful",
    )


@router.post("/logout-all", response_model=APIResponse)
async def logout_all_devices(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
) -> APIResponse:
    """
    Logout from all devices by invalidating all refresh tokens.
    Requires valid access token in Authorization header.
    
    This will sign out the user from all devices including the current one.
    """
    user_service = UserService(db)
    await user_service.logout_all_devices(current_user.id)

    return APIResponse(
        success=True,
        message="Logged out from all devices",
    )


@router.post("/google", response_model=APIResponse[TokenResponse])
async def google_oauth(
    request: OAuthRequest,
    db: AsyncSession = Depends(get_db)
) -> APIResponse[TokenResponse]:
    """
    Google OAuth login.

    Verifies Google ID token with Google's tokeninfo endpoint,
    then creates or updates user in database.

    - **token**: Google ID token from client
    """
    # Verify Google ID token via POST (avoids leaking token in server logs / URL)
    async with httpx.AsyncClient() as client:
        google_response = await client.post(
            "https://oauth2.googleapis.com/tokeninfo",
            data={"id_token": request.token},
        )
        if google_response.status_code != 200:
            raise AuthenticationError("Invalid Google token")
        google_data = google_response.json()
        if settings.GOOGLE_CLIENT_ID:
            aud = google_data.get("aud", "")
            if settings.GOOGLE_CLIENT_ID != aud:
                raise AuthenticationError("Invalid Google token audience")
        email = google_data.get("email")
        google_id = google_data.get("sub")
        name = google_data.get("name", "")
        if not email:
            raise AuthenticationError("Google token does not contain email")
        if google_data.get("email_verified") not in (True, "true"):
            raise AuthenticationError("Google email not verified")

    auth_service = AuthService(db)

    user, access_token, refresh_token = await auth_service.create_oauth_user(
        email=email,
        name=name,
        auth_provider="google",
        provider_id=google_id,
    )

    return APIResponse(
        success=True,
        data=TokenResponse(
            access_token=access_token,
            refresh_token=refresh_token,
            token_type="bearer",
        ),
        message="Google OAuth login successful",
    )


@router.post("/apple", response_model=APIResponse[TokenResponse])
async def apple_oauth(
    request: OAuthRequest,
    db: AsyncSession = Depends(get_db)
) -> APIResponse[TokenResponse]:
    """
    Apple OAuth login.

    Verifies Apple identity token signature using Apple's public keys,
    then creates or updates user in database.

    - **token**: Apple identity token from client
    """
    # 从 Apple 获取公钥并验证 token 签名
    try:
        # Step 1: 获取 Apple 公钥
        async with httpx.AsyncClient() as client:
            apple_response = await client.get("https://appleid.apple.com/auth/keys")
            if apple_response.status_code != 200:
                raise AuthenticationError("Failed to fetch Apple public keys")
            apple_keys = apple_response.json()

        # Step 2: 获取 token header 中的 kid，匹配对应公钥
        header = jwt.get_unverified_header(request.token)
        kid = header.get("kid")
        if not kid:
            raise AuthenticationError("Invalid Apple token: missing kid")

        matching_key = None
        for key in apple_keys.get("keys", []):
            if key.get("kid") == kid:
                matching_key = key
                break

        if not matching_key:
            raise AuthenticationError("Invalid Apple token: key not found")

        public_key = jwk.construct(matching_key, algorithm="RS256")

        verify_aud = bool(settings.APPLE_CLIENT_ID)
        claims = jwt.decode(
            request.token,
            public_key,
            algorithms=["RS256"],
            audience=settings.APPLE_CLIENT_ID or None,
            issuer="https://appleid.apple.com",
            options={
                "verify_aud": verify_aud,
            },
        )

        email = claims.get("email")
        apple_id = claims.get("sub")
        if not email or not apple_id:
            raise AuthenticationError("Invalid Apple token: missing email or sub")

    except AuthenticationError:
        raise
    except Exception:
        raise AuthenticationError("Failed to verify Apple token")

    auth_service = AuthService(db)

    user, access_token, refresh_token = await auth_service.create_oauth_user(
        email=email,
        name=claims.get("name", ""),
        auth_provider="apple",
        provider_id=apple_id,
    )

    return APIResponse(
        success=True,
        data=TokenResponse(
            access_token=access_token,
            refresh_token=refresh_token,
            token_type="bearer",
        ),
        message="Apple OAuth login successful",
    )
