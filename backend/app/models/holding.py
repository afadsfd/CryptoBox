from uuid import uuid4

from sqlalchemy import Column, String, Numeric, DateTime, ForeignKey, UniqueConstraint, func
from sqlalchemy.dialects.postgresql import UUID

from app.database import Base


class Holding(Base):
    __tablename__ = "holdings"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    exchange_account_id = Column(UUID(as_uuid=True), ForeignKey("exchange_accounts.id", ondelete="CASCADE"), nullable=False, index=True)
    symbol = Column(String(20), nullable=False)  # 如 BTC, ETH, USDT
    quantity = Column(Numeric(precision=30, scale=12), nullable=False, default=0.0)
    free = Column(Numeric(precision=30, scale=12), nullable=False, default=0.0)
    locked = Column(Numeric(precision=30, scale=12), nullable=False, default=0.0)
    price_usd = Column(Numeric(precision=20, scale=8), nullable=True)
    value_usd = Column(Numeric(precision=20, scale=8), nullable=True)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    __table_args__ = (
        UniqueConstraint('exchange_account_id', 'symbol', name='uq_holding_account_symbol'),
    )

    def __repr__(self):
        return f"<Holding(id={self.id}, symbol={self.symbol}, quantity={self.quantity})>"
