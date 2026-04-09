from datetime import datetime
from uuid import uuid4

from sqlalchemy import Column, String, Boolean, DateTime, func, JSON
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from app.database import Base


class User(Base):
    __tablename__ = "users"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid4)
    email = Column(String(255), unique=True, nullable=False, index=True)
    password_hash = Column(String(255), nullable=True)  # nullable for OAuth users
    name = Column(String(100), nullable=True)
    avatar = Column(String(500), nullable=True)
    auth_provider = Column(String(50), default="email")  # email/google/apple
    subscription_tier = Column(String(50), default="free")  # free/pro
    is_active = Column(Boolean, default=True)
    is_verified = Column(Boolean, default=False)  # 邮箱是否已验证
    preferences = Column(JSON, default=lambda: {})  # 用户偏好设置
    refresh_token_hash = Column(String(255), nullable=True)  # HMAC-SHA256 hex of current refresh JWT
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    # Relationships
    exchange_accounts = relationship("ExchangeAccount", back_populates="user", cascade="all, delete-orphan")

    def __repr__(self):
        return f"<User(id={self.id}, email={self.email})>"
