from datetime import datetime
from uuid import uuid4

from sqlalchemy import Column, String, Boolean, DateTime, func, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from app.database import Base


class ExchangeAccount(Base):
    __tablename__ = "exchange_accounts"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    exchange_name = Column(String(50), nullable=False)  # binance/okx/bybit...
    label = Column(String(100), nullable=True)  # 用户备注名
    api_key_encrypted = Column(String(500), nullable=False)
    api_secret_encrypted = Column(String(500), nullable=False)
    passphrase_encrypted = Column(String(500), nullable=True)  # 部分交易所需要
    is_active = Column(Boolean, default=True)
    last_sync_at = Column(DateTime(timezone=True), nullable=True)
    sync_status = Column(String(50), default="pending")  # pending/syncing/success/failed
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    # Relationships
    user = relationship("User", back_populates="exchange_accounts")

    def __repr__(self):
        return f"<ExchangeAccount(id={self.id}, exchange={self.exchange_name}, user_id={self.user_id})>"
