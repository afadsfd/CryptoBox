from uuid import uuid4

from sqlalchemy import Column, Float, Numeric, DateTime, ForeignKey, func
from sqlalchemy.dialects.postgresql import UUID

from app.database import Base


class PortfolioSnapshot(Base):
    __tablename__ = "portfolio_snapshots"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    total_value_usd = Column(Numeric(precision=20, scale=2), nullable=False)
    btc_value = Column(Float, nullable=True)  # 可选：BTC 计价总值
    snapshot_at = Column(DateTime(timezone=True), server_default=func.now(), index=True)

    def __repr__(self):
        return f"<PortfolioSnapshot(id={self.id}, total_value_usd={self.total_value_usd})>"
