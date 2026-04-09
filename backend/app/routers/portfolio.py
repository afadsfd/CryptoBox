"""
Portfolio API Router

资产组合相关 API 端点：
- GET /portfolio/summary - 获取资产概览
- GET /portfolio/history - 获取历史净值数据
- GET /portfolio/holdings - 获取持仓列表
- GET /portfolio/sources - 获取已连接数据源
"""
from typing import Literal

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.dependencies import get_current_user
from app.models.user import User
from app.schemas.common import APIResponse
from app.schemas.portfolio import (
    HoldingsListResponse,
    PortfolioHistoryResponse,
    PortfolioSummaryResponse,
    SourcesListResponse,
)
from app.services.portfolio_service import PortfolioService

router = APIRouter(prefix="/portfolio", tags=["Portfolio"])


# =============================================================================
# Portfolio Summary
# =============================================================================

@router.get(
    "/summary",
    response_model=PortfolioSummaryResponse,
    summary="获取资产概览",
    description="返回用户总资产价值、24小时涨跌幅及各来源分布"
)
async def get_portfolio_summary(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
) -> PortfolioSummaryResponse:
    """
    获取用户资产组合概览
    
    Returns:
        PortfolioSummaryResponse 包含:
        - total_value_usd: 总资产价值 (USD)
        - change_24h_usd: 24小时涨跌额
        - change_24h_percent: 24小时涨跌幅百分比
        - source_distribution: 各来源资产分布列表
    """
    service = PortfolioService(db)
    summary = await service.get_portfolio_summary(current_user)
    
    return PortfolioSummaryResponse(
        success=True,
        data=summary
    )


# =============================================================================
# Portfolio History
# =============================================================================

@router.get(
    "/history",
    response_model=PortfolioHistoryResponse,
    summary="获取历史净值数据",
    description="返回指定时间周期内的资产净值历史数据"
)
async def get_portfolio_history(
    period: Literal["1d", "1w", "1m", "3m", "all"] = Query(
        default="1m",
        description="时间周期: 1d=1天, 1w=1周, 1m=1月, 3m=3月, all=全部"
    ),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
) -> PortfolioHistoryResponse:
    """
    获取资产历史净值数据
    
    Args:
        period: 时间周期 (1d, 1w, 1m, 3m, all)
    
    Returns:
        PortfolioHistoryResponse 包含:
        - period: 请求的时间周期
        - data_points: 历史数据点列表 (timestamp, value)
        - high: 周期内最高值
        - low: 周期内最低值
        - average: 周期内平均值
    """
    service = PortfolioService(db)
    history = await service.get_portfolio_history(current_user, period)
    
    return PortfolioHistoryResponse(
        success=True,
        data=history
    )


# =============================================================================
# Holdings
# =============================================================================

@router.get(
    "/holdings",
    response_model=HoldingsListResponse,
    summary="获取持仓列表",
    description="返回用户所有币种持仓详情"
)
async def get_holdings(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
) -> HoldingsListResponse:
    """
    获取用户持仓列表
    
    Returns:
        HoldingsListResponse 包含:
        - holdings: 持仓列表，每项包含:
          - symbol: 币种代码
          - name: 币种全称
          - quantity: 持仓数量
          - price_usd: 当前价格
          - value_usd: 持仓市值
          - change_24h_percent: 24小时涨跌幅
          - portfolio_percent: 占投资组合百分比
        - total_count: 总持仓数量
    """
    service = PortfolioService(db)
    holdings = await service.get_holdings(current_user)
    
    return HoldingsListResponse(
        success=True,
        data=holdings
    )


# =============================================================================
# Connected Sources
# =============================================================================

@router.get(
    "/sources",
    response_model=SourcesListResponse,
    summary="获取已连接数据源",
    description="返回用户已连接的交易所和钱包列表"
)
async def get_connected_sources(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
) -> SourcesListResponse:
    """
    获取已连接的数据源列表
    
    Returns:
        SourcesListResponse 包含:
        - sources: 数据源列表，每项包含:
          - id: 数据源唯一标识
          - name: 数据源名称
          - type: 类型 (api/web3)
          - exchange/chain: 交易所或链名称
          - status: 状态 (active/inactive/syncing)
          - last_sync: 最后同步时间
        - total_count: 总数据源数量
        - active_count: 活跃数据源数量
    """
    service = PortfolioService(db)
    sources = await service.get_connected_sources(current_user)
    
    return SourcesListResponse(
        success=True,
        data=sources
    )


# =============================================================================
# Sync Portfolio Data
# =============================================================================

@router.post(
    "/sync",
    response_model=APIResponse,
    summary="同步资产数据",
    description="触发同步所有已连接交易所的资产数据"
)
async def sync_portfolio(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
) -> dict:
    """
    同步所有已连接交易所的余额数据
    
    Returns:
        同步结果，包含同步成功的数据源数量
    """
    service = PortfolioService(db)
    result = await service.sync_portfolio_data(current_user)
    
    return {
        "success": result.get("success", False),
        "data": {"synced_sources": result.get("synced_sources", 0)},
        "message": result.get("message", ""),
    }


# =============================================================================
# Legacy Endpoints (保持向后兼容)
# =============================================================================

@router.get(
    "/assets",
    response_model=HoldingsListResponse,
    summary="获取资产列表 (兼容旧接口)",
    description="/holdings 的别名，返回相同数据"
)
async def get_assets(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
) -> HoldingsListResponse:
    """
    获取资产列表（/holdings 的别名）
    
    保持向后兼容，返回与 /holdings 相同的数据
    """
    return await get_holdings(current_user, db)


@router.get(
    "/distribution",
    response_model=PortfolioSummaryResponse,
    summary="获取资产分布 (兼容旧接口)",
    description="返回资产概览数据，包含来源分布"
)
async def get_asset_distribution(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
) -> PortfolioSummaryResponse:
    """
    获取资产分布（返回与 /summary 相同的数据）
    
    保持向后兼容
    """
    return await get_portfolio_summary(current_user, db)
