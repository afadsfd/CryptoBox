from typing import Optional
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.user import User
from app.schemas.user import (
    UserPreferences,
    UpdatePreferencesRequest,
    SecuritySettings,
    UpdateSecurityRequest,
    UpdateProfileRequest,
    UserProfile,
)
from app.utils.exceptions import NotFoundError, ValidationError


class UserService:
    """用户服务类"""

    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_user_by_id(self, user_id: UUID) -> Optional[User]:
        """根据 ID 获取用户"""
        result = await self.db.execute(
            select(User).where(User.id == user_id)
        )
        return result.scalar_one_or_none()

    async def get_user_profile(self, user_id: UUID) -> UserProfile:
        """
        获取用户完整资料
        
        Args:
            user_id: 用户 ID
            
        Returns:
            UserProfile: 用户完整资料
            
        Raises:
            NotFoundError: 用户不存在
        """
        user = await self.get_user_by_id(user_id)
        if not user:
            raise NotFoundError("User")

        # 解析用户偏好设置
        preferences = self._parse_preferences(user.preferences or {})

        return UserProfile(
            id=user.id,
            email=user.email,
            name=user.name,
            avatar=user.avatar,
            subscription_tier=user.subscription_tier or "free",
            auth_provider=user.auth_provider or "email",
            is_verified=user.is_verified,
            created_at=user.created_at,
            preferences=preferences,
        )

    async def update_user_profile(
        self,
        user_id: UUID,
        data: UpdateProfileRequest
    ) -> UserProfile:
        """
        更新用户资料
        
        Args:
            user_id: 用户 ID
            data: 更新数据
            
        Returns:
            UserProfile: 更新后的用户资料
            
        Raises:
            NotFoundError: 用户不存在
        """
        user = await self.get_user_by_id(user_id)
        if not user:
            raise NotFoundError("User")

        # 更新字段
        if data.name is not None:
            user.name = data.name
        if data.avatar is not None:
            user.avatar = data.avatar

        await self.db.commit()
        await self.db.refresh(user)

        return await self.get_user_profile(user_id)

    async def update_preferences(
        self,
        user_id: UUID,
        prefs_request: UpdatePreferencesRequest
    ) -> UserPreferences:
        """
        更新用户偏好设置

        Args:
            user_id: 用户 ID
            prefs_request: 偏好设置更新请求

        Returns:
            UserPreferences: 更新后的偏好设置

        Raises:
            NotFoundError: 用户不存在
        """
        user = await self.get_user_by_id(user_id)
        if not user:
            raise NotFoundError("User")

        # 浅拷贝以确保 SQLAlchemy 检测到变更
        current_prefs = dict(user.preferences or {})

        # 更新字段
        if prefs_request.base_currency is not None:
            current_prefs["base_currency"] = prefs_request.base_currency
        if prefs_request.refresh_interval_minutes is not None:
            current_prefs["refresh_interval_minutes"] = prefs_request.refresh_interval_minutes
        if prefs_request.biometric_enabled is not None:
            current_prefs["biometric_enabled"] = prefs_request.biometric_enabled
        if prefs_request.market_alerts_enabled is not None:
            current_prefs["market_alerts_enabled"] = prefs_request.market_alerts_enabled

        # 赋值新对象触发 SQLAlchemy dirty 检测
        user.preferences = current_prefs

        await self.db.commit()
        await self.db.refresh(user)

        return self._parse_preferences(current_prefs)

    async def get_security_settings(self, user_id: UUID) -> SecuritySettings:
        """
        获取用户安全设置（直接从 preferences JSON 读取 2FA 字段）

        Args:
            user_id: 用户 ID

        Returns:
            SecuritySettings

        Raises:
            NotFoundError: 用户不存在
        """
        user = await self.get_user_by_id(user_id)
        if not user:
            raise NotFoundError("User")

        return self._parse_security_settings(user.preferences or {})

    async def update_security(
        self,
        user_id: UUID,
        security_request: UpdateSecurityRequest
    ) -> SecuritySettings:
        """
        更新用户安全设置
        
        Args:
            user_id: 用户 ID
            security_request: 安全设置更新请求
            
        Returns:
            SecuritySettings: 更新后的安全设置
            
        Raises:
            NotFoundError: 用户不存在
        """
        user = await self.get_user_by_id(user_id)
        if not user:
            raise NotFoundError("User")

        # 浅拷贝以确保 SQLAlchemy 检测到变更
        current_prefs = dict(user.preferences or {})

        # 更新字段
        if security_request.biometric_enabled is not None:
            current_prefs["biometric_enabled"] = security_request.biometric_enabled
        if security_request.two_factor_enabled is not None:
            current_prefs["two_factor_enabled"] = security_request.two_factor_enabled

        # 赋值新对象触发 SQLAlchemy dirty 检测
        user.preferences = current_prefs

        await self.db.commit()
        await self.db.refresh(user)

        return self._parse_security_settings(current_prefs)

    async def logout_all_devices(self, user_id: UUID) -> bool:
        """
        登出所有设备
        
        通过清除用户的 refresh_token_hash 来实现，
        这样所有现有的 refresh token 都将失效。
        
        Args:
            user_id: 用户 ID
            
        Returns:
            bool: 是否成功
            
        Raises:
            NotFoundError: 用户不存在
        """
        user = await self.get_user_by_id(user_id)
        if not user:
            raise NotFoundError("User")

        # 清除 refresh token hash，使所有 refresh token 失效
        user.refresh_token_hash = None

        await self.db.commit()
        await self.db.refresh(user)

        return True

    def _parse_preferences(self, prefs_dict: dict) -> UserPreferences:
        """从字典解析用户偏好设置"""
        return UserPreferences(
            base_currency=prefs_dict.get("base_currency", "USD"),
            refresh_interval_minutes=prefs_dict.get("refresh_interval_minutes", 5),
            biometric_enabled=prefs_dict.get("biometric_enabled", True),
            market_alerts_enabled=prefs_dict.get("market_alerts_enabled", True),
        )

    def _parse_security_settings(self, prefs_dict: dict) -> SecuritySettings:
        """从字典解析安全设置"""
        return SecuritySettings(
            biometric_enabled=prefs_dict.get("biometric_enabled", True),
            two_factor_enabled=prefs_dict.get("two_factor_enabled", False),
            two_factor_methods=prefs_dict.get("two_factor_methods", ["sms", "email"]),
        )
