from datetime import datetime
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, ConfigDict, EmailStr, Field


# ============== 用户偏好设置 ==============

class UserPreferences(BaseModel):
    """用户偏好设置"""
    base_currency: str = Field(default="USD", description="基础货币")
    refresh_interval_minutes: int = Field(default=5, ge=1, le=60, description="刷新间隔(分钟)")
    biometric_enabled: bool = Field(default=True, description="生物识别认证开关")
    market_alerts_enabled: bool = Field(default=True, description="市场提醒开关")

    model_config = ConfigDict(from_attributes=True)


class UpdatePreferencesRequest(BaseModel):
    """更新偏好设置请求"""
    base_currency: Optional[str] = Field(None, description="基础货币")
    refresh_interval_minutes: Optional[int] = Field(None, ge=1, le=60, description="刷新间隔(分钟)")
    biometric_enabled: Optional[bool] = Field(None, description="生物识别认证开关")
    market_alerts_enabled: Optional[bool] = Field(None, description="市场提醒开关")


# ============== 安全设置 ==============

class SecuritySettings(BaseModel):
    """安全设置"""
    biometric_enabled: bool = Field(default=True, description="生物识别认证开关")
    two_factor_enabled: bool = Field(default=False, description="双因素认证开关")
    two_factor_methods: list[str] = Field(default_factory=lambda: ["sms", "email"], description="2FA方法")

    model_config = ConfigDict(from_attributes=True)


class UpdateSecurityRequest(BaseModel):
    """更新安全设置请求"""
    biometric_enabled: Optional[bool] = Field(None, description="生物识别认证开关")
    two_factor_enabled: Optional[bool] = Field(None, description="双因素认证开关")


# ============== 用户资料 ==============

class UserProfile(BaseModel):
    """完整用户资料（含偏好设置）"""
    id: UUID
    email: EmailStr
    name: Optional[str] = None
    avatar: Optional[str] = None
    subscription_tier: str = Field(default="free", description="订阅等级")
    auth_provider: str = Field(default="email", description="认证方式")
    is_verified: bool = Field(default=False, description="是否已验证")
    created_at: datetime
    preferences: UserPreferences = Field(default_factory=UserPreferences, description="用户偏好设置")

    model_config = ConfigDict(from_attributes=True)


class UpdateProfileRequest(BaseModel):
    """更新用户资料请求"""
    name: Optional[str] = Field(None, max_length=100, description="用户姓名")
    avatar: Optional[str] = Field(None, max_length=500, description="头像URL")


# ============== API 管理 ==============

class ConnectedApiInfo(BaseModel):
    """已连接的 API 信息"""
    id: str
    name: str
    exchange: str
    last_active: str
    is_active: bool

    model_config = ConfigDict(from_attributes=True)


class GenerateApiKeyRequest(BaseModel):
    """生成 API Key 请求"""
    name: str = Field(..., min_length=1, max_length=100, description="API Key 名称")
    exchange_id: Optional[str] = Field(None, description="交易所ID")


class ApiKeyResponse(BaseModel):
    """API Key 响应"""
    id: str
    name: str
    api_key: str
    api_secret: str
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)
