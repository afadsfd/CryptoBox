"""
Portfolio API Schemas
"""
from datetime import datetime
from typing import List, Optional
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


# =============================================================================
# Source Distribution
# =============================================================================

class SourceDistribution(BaseModel):
    """资产来源分布"""
    source: str = Field(..., description="来源名称 (如 Binance, Coinbase)")
    value: float = Field(..., description="该来源的资产价值 (USD)")
    percent: float = Field(..., description="占比百分比")

    model_config = ConfigDict(from_attributes=True)


# =============================================================================
# Portfolio Summary
# =============================================================================

class PortfolioSummary(BaseModel):
    """总资产概览"""
    total_value_usd: float = Field(..., description="总资产价值 (USD)")
    change_24h_usd: float = Field(..., description="24小时涨跌额 (USD)")
    change_24h_percent: float = Field(..., description="24小时涨跌幅百分比")
    source_distribution: List[SourceDistribution] = Field(
        default_factory=list,
        description="各来源资产分布"
    )

    model_config = ConfigDict(from_attributes=True)


# =============================================================================
# Portfolio History
# =============================================================================

class HistoryDataPoint(BaseModel):
    """历史数据点"""
    timestamp: datetime = Field(..., description="数据点时间点")
    value: float = Field(..., description="该时间点的资产总值")

    model_config = ConfigDict(from_attributes=True)


class PortfolioHistory(BaseModel):
    """资产历史净值数据"""
    period: str = Field(..., description="时间周期 (1d, 1w, 1m, 3m, all)")
    data_points: List[HistoryDataPoint] = Field(
        default_factory=list,
        description="历史数据点列表"
    )
    high: float = Field(..., description="周期内最高值")
    low: float = Field(..., description="周期内最低值")
    average: float = Field(..., description="周期内平均值")

    model_config = ConfigDict(from_attributes=True)


# =============================================================================
# Holdings
# =============================================================================

class HoldingItem(BaseModel):
    """单个持仓项"""
    symbol: str = Field(..., description="币种代码 (如 BTC, ETH)")
    name: str = Field(..., description="币种全称")
    quantity: float = Field(..., description="持仓数量")
    price_usd: float = Field(..., description="当前价格 (USD)")
    value_usd: float = Field(..., description="持仓市值 (USD)")
    change_24h_percent: float = Field(..., description="24小时涨跌幅百分比")
    portfolio_percent: float = Field(..., description="占投资组合百分比")

    model_config = ConfigDict(from_attributes=True)


class HoldingsList(BaseModel):
    """持仓列表"""
    holdings: List[HoldingItem] = Field(default_factory=list)
    total_count: int = Field(default=0, description="总持仓数量")

    model_config = ConfigDict(from_attributes=True)


# =============================================================================
# Connected Sources
# =============================================================================

class ConnectedSource(BaseModel):
    """已连接的数据源"""
    id: UUID = Field(..., description="数据源唯一标识")
    name: str = Field(..., description="数据源名称")
    type: str = Field(..., description="类型: api 或 web3")
    exchange: Optional[str] = Field(None, description="交易所名称 (type=api 时)")
    chain: Optional[str] = Field(None, description="区块链名称 (type=web3 时)")
    status: str = Field(..., description="状态: active, inactive, syncing")
    last_sync: datetime = Field(..., description="最后同步时间")

    model_config = ConfigDict(from_attributes=True)


class SourcesList(BaseModel):
    """数据源列表"""
    sources: List[ConnectedSource] = Field(default_factory=list)
    total_count: int = Field(default=0, description="总数据源数量")
    active_count: int = Field(default=0, description="活跃数据源数量")

    model_config = ConfigDict(from_attributes=True)


# =============================================================================
# API Response Wrappers
# =============================================================================

class PortfolioSummaryResponse(BaseModel):
    """资产概览响应"""
    success: bool = True
    data: PortfolioSummary


class PortfolioHistoryResponse(BaseModel):
    """资产历史响应"""
    success: bool = True
    data: PortfolioHistory


class HoldingsListResponse(BaseModel):
    """持仓列表响应"""
    success: bool = True
    data: HoldingsList


class SourcesListResponse(BaseModel):
    """数据源列表响应"""
    success: bool = True
    data: SourcesList
