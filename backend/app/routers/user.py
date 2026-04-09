from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.dependencies import get_current_user
from app.models.user import User
from app.schemas.common import APIResponse
from app.schemas.user import (
    UserProfile,
    UpdateProfileRequest,
    UserPreferences,
    UpdatePreferencesRequest,
    SecuritySettings,
    UpdateSecurityRequest,
    ConnectedApiInfo,
)
from app.services.user_service import UserService

router = APIRouter(prefix="/user", tags=["Users"])


# ============== 用户资料 ==============

@router.get("/profile", response_model=APIResponse[UserProfile])
async def get_user_profile(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
) -> APIResponse[UserProfile]:
    """
    获取当前用户完整资料（含偏好设置）
    
    需要认证，返回用户资料包括：
    - 基本信息（id, email, name, avatar）
    - 订阅等级
    - 认证方式
    - 偏好设置（基础货币、刷新间隔等）
    """
    user_service = UserService(db)
    profile = await user_service.get_user_profile(current_user.id)
    
    return APIResponse(
        success=True,
        data=profile,
        message="User profile retrieved successfully"
    )


@router.put("/profile", response_model=APIResponse[UserProfile])
async def update_user_profile(
    request: UpdateProfileRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
) -> APIResponse[UserProfile]:
    """
    更新当前用户资料
    
    可更新字段：
    - name: 用户姓名
    - avatar: 头像URL
    """
    user_service = UserService(db)
    updated_profile = await user_service.update_user_profile(
        current_user.id, request
    )
    
    return APIResponse(
        success=True,
        data=updated_profile,
        message="User profile updated successfully"
    )


# ============== 偏好设置 ==============

@router.get("/preferences", response_model=APIResponse[UserPreferences])
async def get_user_preferences(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
) -> APIResponse[UserPreferences]:
    """
    获取当前用户偏好设置
    
    返回：
    - base_currency: 基础货币（默认 USD）
    - refresh_interval_minutes: 刷新间隔（默认 5 分钟）
    - biometric_enabled: 生物识别认证开关
    - market_alerts_enabled: 市场提醒开关
    """
    user_service = UserService(db)
    profile = await user_service.get_user_profile(current_user.id)
    
    return APIResponse(
        success=True,
        data=profile.preferences,
        message="User preferences retrieved successfully"
    )


@router.put("/preferences", response_model=APIResponse[UserPreferences])
async def update_user_preferences(
    request: UpdatePreferencesRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
) -> APIResponse[UserPreferences]:
    """
    更新当前用户偏好设置
    
    可更新字段：
    - base_currency: 基础货币（USD/EUR/GBP/JPY/CNY）
    - refresh_interval_minutes: 刷新间隔（1-60 分钟）
    - biometric_enabled: 生物识别认证开关
    - market_alerts_enabled: 市场提醒开关
    """
    user_service = UserService(db)
    updated_prefs = await user_service.update_preferences(current_user.id, request)
    
    return APIResponse(
        success=True,
        data=updated_prefs,
        message="User preferences updated successfully"
    )


# ============== 安全设置 ==============

@router.get("/security", response_model=APIResponse[SecuritySettings])
async def get_security_settings(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
) -> APIResponse[SecuritySettings]:
    """
    获取当前用户安全设置
    
    返回：
    - biometric_enabled: 生物识别认证开关
    - two_factor_enabled: 双因素认证开关
    - two_factor_methods: 已启用的 2FA 方法列表
    """
    user_service = UserService(db)
    security_settings = await user_service.get_security_settings(current_user.id)

    return APIResponse(
        success=True,
        data=security_settings,
        message="Security settings retrieved successfully"
    )


@router.put("/security", response_model=APIResponse[SecuritySettings])
async def update_security_settings(
    request: UpdateSecurityRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
) -> APIResponse[SecuritySettings]:
    """
    更新当前用户安全设置
    
    可更新字段：
    - biometric_enabled: 生物识别认证开关
    - two_factor_enabled: 双因素认证开关
    """
    user_service = UserService(db)
    updated_security = await user_service.update_security(current_user.id, request)
    
    return APIResponse(
        success=True,
        data=updated_security,
        message="Security settings updated successfully"
    )


# ============== API 管理 ==============

@router.get("/apis", response_model=APIResponse[list[ConnectedApiInfo]])
async def get_connected_apis(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
) -> APIResponse[list[ConnectedApiInfo]]:
    """
    获取当前用户已连接的 API 列表
    
    返回交易所 API 连接信息列表
    """
    return APIResponse(success=True, data=[], message="API management coming soon")


# ============== 旧端点（保持兼容性） ==============

@router.get("/me", response_model=APIResponse[UserProfile])
async def get_current_user_info(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
) -> APIResponse[UserProfile]:
    """
    获取当前用户信息（兼容旧端点，推荐使用 /profile）
    """
    return await get_user_profile(current_user, db)


@router.put("/me", response_model=APIResponse[UserProfile])
async def update_current_user_info(
    request: UpdateProfileRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
) -> APIResponse[UserProfile]:
    """
    更新当前用户信息（兼容旧端点，推荐使用 /profile）
    """
    return await update_user_profile(request, current_user, db)


@router.put("/me/password", response_model=APIResponse)
async def change_password(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
) -> APIResponse:
    """
    修改用户密码（暂未实现）
    """
    return APIResponse(
        success=False,
        message="Password change not implemented yet"
    )


@router.delete("/me", response_model=APIResponse)
async def delete_account(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
) -> APIResponse:
    """
    删除用户账户（暂未实现）
    """
    return APIResponse(
        success=False,
        message="Account deletion not implemented yet"
    )


@router.get("/me/subscription", response_model=APIResponse)
async def get_subscription_info(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
) -> APIResponse:
    """
    获取订阅信息（暂未实现）
    """
    return APIResponse(
        success=True,
        data={
            "tier": current_user.subscription_tier or "free",
            "status": "active"
        },
        message="Subscription info retrieved"
    )
