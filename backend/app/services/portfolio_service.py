"""
Portfolio Service

处理资产组合相关的业务逻辑，包括：
- 总资产计算与聚合（真实数据）
- 持仓明细查询
- 历史趋势数据
- 单账户同步
- 已连接数据源管理
"""
import asyncio
import logging
from datetime import datetime, timedelta, timezone
from typing import List, Optional
from uuid import UUID

from sqlalchemy import select, delete, and_
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.exchange_account import ExchangeAccount
from app.models.holding import Holding
from app.models.portfolio_snapshot import PortfolioSnapshot
from app.models.user import User
from app.schemas.portfolio import (
    ConnectedSource,
    HistoryDataPoint,
    HoldingItem,
    HoldingsList,
    PortfolioHistory,
    PortfolioSummary,
    SourceDistribution,
    SourcesList,
)
from app.services.exchange_adapters import get_exchange_adapter
from app.services.price_service import PriceService
from app.utils.security import decrypt_api_key

logger = logging.getLogger(__name__)

# Symbol -> human-readable name mapping (common coins)
_COIN_NAMES: dict[str, str] = {
    "BTC": "Bitcoin",
    "ETH": "Ethereum",
    "BNB": "BNB",
    "SOL": "Solana",
    "XRP": "Ripple",
    "DOGE": "Dogecoin",
    "ADA": "Cardano",
    "AVAX": "Avalanche",
    "DOT": "Polkadot",
    "MATIC": "Polygon",
    "LINK": "Chainlink",
    "UNI": "Uniswap",
    "ATOM": "Cosmos",
    "LTC": "Litecoin",
    "FIL": "Filecoin",
    "NEAR": "NEAR Protocol",
    "APT": "Aptos",
    "ARB": "Arbitrum",
    "OP": "Optimism",
    "SUI": "Sui",
    "USDT": "Tether",
    "USDC": "USD Coin",
    "DAI": "Dai",
    "BUSD": "Binance USD",
    "TRX": "TRON",
    "SHIB": "Shiba Inu",
    "PEPE": "Pepe",
    "WIF": "dogwifhat",
    "TON": "Toncoin",
    "OKB": "OKB",
    "GT": "GateToken",
    "BGB": "Bitget Token",
}

# Snapshot cooldown: only save a new snapshot if the previous one is older than this
_SNAPSHOT_COOLDOWN = timedelta(hours=1)


class PortfolioService:
    """资产组合服务 — 真实数据聚合"""

    def __init__(self, db: AsyncSession, redis_client=None):
        self.db = db
        self.price_service = PriceService(redis_client)

    # =========================================================================
    # Portfolio Summary
    # =========================================================================

    async def get_portfolio_summary(self, user: User) -> PortfolioSummary:
        """
        获取用户资产组合概览

        1. 查询所有 active 的 exchange_accounts
        2. 并发获取各交易所余额
        3. 合并相同 symbol
        4. 获取价格 & 24h 涨跌
        5. 计算总值
        6. upsert holdings
        7. 保存 snapshot（冷却 1h）
        """
        user_id: UUID = user.id  # type: ignore[assignment]

        # 1. 查询活跃账户
        accounts = await self._get_active_accounts(user_id)
        if not accounts:
            # 没有绑定交易所，返回零值
            return PortfolioSummary(
                total_value_usd=0.0,
                change_24h_usd=0.0,
                change_24h_percent=0.0,
                source_distribution=[],
            )

        # 2. 并发获取各交易所余额
        account_balances = await self._fetch_all_balances(accounts)

        # 3. 合并所有交易所余额 (symbol -> total quantity) & 按来源统计
        merged: dict[str, dict] = {}          # symbol -> {quantity, free, locked}
        source_values: dict[str, float] = {}  # exchange_label -> total_value_usd
        # 同时收集 per-account holdings 用于 upsert
        per_account_holdings: list[dict] = []

        for acct, balances in account_balances:
            for item in balances:
                sym = item["symbol"]
                free = item["free"]
                locked = item["locked"]
                qty = free + locked

                if sym not in merged:
                    merged[sym] = {"quantity": 0.0, "free": 0.0, "locked": 0.0}
                merged[sym]["quantity"] += qty
                merged[sym]["free"] += free
                merged[sym]["locked"] += locked

                per_account_holdings.append({
                    "user_id": user_id,
                    "exchange_account_id": acct.id,
                    "symbol": sym,
                    "quantity": qty,
                    "free": free,
                    "locked": locked,
                })

        if not merged:
            return PortfolioSummary(
                total_value_usd=0.0,
                change_24h_usd=0.0,
                change_24h_percent=0.0,
                source_distribution=[],
            )

        # 4. 获取价格 & 24h 涨跌（优先从交易所 ticker 获取）
        symbols = list(merged.keys())
        ticker_data = await self._get_ticker_data_from_exchanges(
            accounts, account_balances
        )

        # 从 ticker_data 提取 prices 和 changes
        exchange_prices = {s: d["price"] for s, d in ticker_data.items()}
        exchange_changes = {s: d["change_24h_percent"] for s, d in ticker_data.items()}

        # 找出交易所没覆盖到的币种，从 CoinGecko fallback
        missing_symbols = [s for s in symbols if s not in exchange_prices]
        fallback_prices: dict[str, float] = {}
        fallback_changes: dict[str, float] = {}
        if missing_symbols:
            fallback_prices, fallback_changes = await asyncio.gather(
                self.price_service.get_prices(missing_symbols),
                self.price_service.get_24h_change(missing_symbols),
            )

        # 合并（交易所优先）
        prices = {**fallback_prices, **exchange_prices}
        changes = {**fallback_changes, **exchange_changes}

        # 5. 计算每个币种 value_usd & 总值
        total_value_usd = 0.0
        for sym, info in merged.items():
            price = prices.get(sym, 0.0)
            val = info["quantity"] * price
            merged[sym]["price_usd"] = price
            merged[sym]["value_usd"] = val
            total_value_usd += val

        # 计算 per-account value & source_distribution
        for acct, balances in account_balances:
            label = acct.label or acct.exchange_name.capitalize()
            acct_value = 0.0
            for item in balances:
                price = prices.get(item["symbol"], 0.0)
                acct_value += (item["free"] + item["locked"]) * price
            source_values[label] = source_values.get(label, 0.0) + acct_value

        source_distribution: list[SourceDistribution] = []
        for src_name, src_val in sorted(source_values.items(), key=lambda x: -x[1]):
            pct = (src_val / total_value_usd * 100) if total_value_usd > 0 else 0.0
            source_distribution.append(SourceDistribution(
                source=src_name,
                value=round(src_val, 2),
                percent=round(pct, 1),
            ))

        # 6. 计算 24h 变化额 (加权)
        change_24h_usd = 0.0
        for sym, info in merged.items():
            chg_pct = changes.get(sym, 0.0)
            val = info["value_usd"]
            # value_yesterday ≈ val / (1 + chg_pct/100)
            if chg_pct != 0.0 and abs(1 + chg_pct / 100) > 1e-9:
                val_yesterday = val / (1 + chg_pct / 100)
                change_24h_usd += val - val_yesterday

        change_24h_percent = (
            (change_24h_usd / (total_value_usd - change_24h_usd) * 100)
            if total_value_usd > abs(change_24h_usd)
            else 0.0
        )

        # 7. Upsert holdings
        await self._upsert_holdings(user_id, per_account_holdings, prices)

        # 8. Save snapshot (with cooldown)
        btc_price = prices.get("BTC", 0.0)
        btc_value = (total_value_usd / btc_price) if btc_price > 0 else None
        await self._maybe_save_snapshot(user_id, total_value_usd, btc_value)

        await self.db.commit()

        return PortfolioSummary(
            total_value_usd=round(total_value_usd, 2),
            change_24h_usd=round(change_24h_usd, 2),
            change_24h_percent=round(change_24h_percent, 2),
            source_distribution=source_distribution,
        )

    # =========================================================================
    # Holdings
    # =========================================================================

    async def get_holdings(self, user: User) -> HoldingsList:
        """
        获取用户持仓明细（从 holdings 表读取，按 value_usd 降序）
        """
        user_id: UUID = user.id  # type: ignore[assignment]

        stmt = (
            select(Holding)
            .where(Holding.user_id == user_id)
            .order_by(Holding.value_usd.desc().nullslast())
        )
        result = await self.db.execute(stmt)
        rows: list[Holding] = list(result.scalars().all())

        if not rows:
            return HoldingsList(holdings=[], total_count=0)

        # 过滤掉 quantity <= 0 或 value_usd < $1 的币种
        rows = [h for h in rows if h.quantity > 0 and (h.value_usd or 0.0) >= 1]

        if not rows:
            return HoldingsList(holdings=[], total_count=0)

        total_value = sum((h.value_usd or 0.0) for h in rows)

        # 获取 24h 变化
        symbols = [h.symbol for h in rows]
        changes = await self.price_service.get_24h_change(symbols)

        holdings: list[HoldingItem] = []
        for h in rows:
            val = h.value_usd or 0.0
            pct = (val / total_value * 100) if total_value > 0 else 0.0
            holdings.append(HoldingItem(
                symbol=h.symbol,
                name=_COIN_NAMES.get(h.symbol, h.symbol),
                quantity=round(h.quantity, 8),
                price_usd=round(h.price_usd or 0.0, 2),
                value_usd=round(val, 2),
                change_24h_percent=round(changes.get(h.symbol, 0.0), 2),
                portfolio_percent=round(pct, 1),
            ))

        return HoldingsList(holdings=holdings, total_count=len(holdings))

    # =========================================================================
    # Portfolio History / Trend
    # =========================================================================

    async def get_portfolio_history(
        self,
        user: User,
        period: str = "1m",
    ) -> PortfolioHistory:
        """
        获取资产趋势数据（从 portfolio_snapshots 表查询）
        """
        user_id: UUID = user.id  # type: ignore[assignment]

        period_days = {"1d": 1, "1w": 7, "1m": 30, "3m": 90, "all": 365}
        days = period_days.get(period, 30)

        since = datetime.now(timezone.utc) - timedelta(days=days)

        stmt = (
            select(PortfolioSnapshot)
            .where(
                and_(
                    PortfolioSnapshot.user_id == user_id,
                    PortfolioSnapshot.snapshot_at >= since,
                )
            )
            .order_by(PortfolioSnapshot.snapshot_at.asc())
        )
        result = await self.db.execute(stmt)
        snapshots: list[PortfolioSnapshot] = list(result.scalars().all())

        if not snapshots:
            return PortfolioHistory(
                period=period,
                data_points=[],
                high=0.0,
                low=0.0,
                average=0.0,
            )

        data_points = [
            HistoryDataPoint(timestamp=s.snapshot_at, value=round(s.total_value_usd, 2))
            for s in snapshots
        ]
        values = [s.total_value_usd for s in snapshots]

        return PortfolioHistory(
            period=period,
            data_points=data_points,
            high=round(max(values), 2),
            low=round(min(values), 2),
            average=round(sum(values) / len(values), 2),
        )

    # =========================================================================
    # Backfill History (on exchange bind)
    # =========================================================================

    async def backfill_history(
        self,
        user,
        exchange_account_id: UUID,
        days: int = 7,
    ) -> dict:
        """
        绑定交易所后，反推过去 N 天的资产走势。

        算法：
        1. 获取当前余额 → current_holdings
        2. 获取过去 N 天的交易记录和充提记录
        3. 按天分组，从今天往前倒推每天的持仓
        4. 获取过去 N 天每天的币价（CoinGecko market_chart）
        5. 每天的持仓 × 当天价格 = 当天总资产
        6. 写入 portfolio_snapshots（每天一条）
        """
        user_id = user.id

        # 1. 获取当前余额
        stmt = select(ExchangeAccount).where(
            and_(
                ExchangeAccount.id == exchange_account_id,
                ExchangeAccount.user_id == user_id,
            )
        )
        result = await self.db.execute(stmt)
        acct = result.scalar_one_or_none()
        if not acct:
            return {"success": False, "message": "Exchange account not found"}

        try:
            current_balances = await self._fetch_account_balance(acct)
        except Exception as e:
            logger.warning("backfill_history: failed to fetch balance: %s", e)
            return {"success": False, "message": str(e)}

        # 构建当前持仓 dict
        holdings: dict[str, float] = {}
        for b in current_balances:
            sym = b["symbol"]
            holdings[sym] = holdings.get(sym, 0.0) + b["free"] + b["locked"]

        if not holdings:
            return {"success": True, "message": "No holdings to backfill", "points": 0}

        # 2. 获取交易和充提记录（过去 N 天）
        now = datetime.now(timezone.utc)
        since_ms = int((now - timedelta(days=days)).timestamp() * 1000)

        api_key = decrypt_api_key(acct.api_key_encrypted)
        api_secret = decrypt_api_key(acct.api_secret_encrypted)
        passphrase = (
            decrypt_api_key(acct.passphrase_encrypted)
            if acct.passphrase_encrypted
            else None
        )

        adapter = get_exchange_adapter(acct.exchange_name)

        trades_result, transfers_result = await asyncio.gather(
            adapter.get_trade_history(api_key, api_secret, passphrase, since_ms),
            adapter.get_transfer_history(api_key, api_secret, passphrase, since_ms),
            return_exceptions=True,
        )

        trades = trades_result if not isinstance(trades_result, Exception) else []
        transfers = transfers_result if not isinstance(transfers_result, Exception) else []

        # 3. 合并所有事件，按时间倒序
        events: list[dict] = []
        for t in trades:
            # buy 增加持仓, sell 减少持仓
            events.append({
                "timestamp": t["timestamp"],
                "symbol": t["symbol"],
                "delta": t["amount"] if t["side"] == "buy" else -t["amount"],
            })
        for t in transfers:
            # deposit 增加持仓, withdrawal 减少持仓
            delta = t["amount"] if t["type"] == "deposit" else -t["amount"]
            events.append({
                "timestamp": t["timestamp"],
                "symbol": t["symbol"],
                "delta": delta,
            })

        events.sort(key=lambda x: x["timestamp"], reverse=True)  # 最新在前

        # 4. 获取历史价格
        symbols = list(holdings.keys())
        price_history: dict[str, dict[str, float]] = {}  # symbol -> {date_str: price}
        for sym in symbols[:10]:  # 限制前10个主要币种
            try:
                history = await self.price_service.get_price_history(sym, days)
                for point in history:
                    date_key = point["timestamp"][:10]  # "2024-01-01"
                    if sym not in price_history:
                        price_history[sym] = {}
                    price_history[sym][date_key] = point["price"]
            except Exception:
                pass

        # 5. 从今天往前逐天倒推
        snapshots_to_create: list[dict] = []
        daily_holdings = dict(holdings)  # 复制当前持仓

        for day_offset in range(days + 1):
            date = now - timedelta(days=day_offset)
            date_str = date.strftime("%Y-%m-%d")
            date_start_ms = int(
                date.replace(hour=0, minute=0, second=0, microsecond=0).timestamp() * 1000
            )
            date_end_ms = date_start_ms + 86400000

            # 倒推：减去这一天发生的变动（因为我们从当前往过去推）
            if day_offset > 0:
                for ev in events:
                    if date_start_ms <= ev["timestamp"] < date_end_ms:
                        sym = ev["symbol"]
                        if sym in daily_holdings:
                            daily_holdings[sym] -= ev["delta"]  # 反向操作

            # 计算当天总资产
            total_value = 0.0
            for sym, qty in daily_holdings.items():
                if qty <= 0:
                    continue
                price = 0.0
                if sym in price_history and date_str in price_history[sym]:
                    price = price_history[sym][date_str]
                total_value += qty * price

            if total_value > 0:
                snapshots_to_create.append({
                    "user_id": user_id,
                    "total_value_usd": round(total_value, 2),
                    "btc_value": None,
                    "snapshot_at": date.replace(hour=12, minute=0, second=0, microsecond=0),
                })

        # 6. 检查是否已有快照数据（避免重复写入）
        since_date = now - timedelta(days=days + 1)
        existing = await self.db.execute(
            select(PortfolioSnapshot).where(
                and_(
                    PortfolioSnapshot.user_id == user_id,
                    PortfolioSnapshot.snapshot_at >= since_date,
                )
            )
        )
        existing_count = len(list(existing.scalars().all()))

        if existing_count >= days:
            return {
                "success": True,
                "message": "History already exists",
                "points": existing_count,
            }

        # 写入快照
        for s in snapshots_to_create:
            snapshot = PortfolioSnapshot(
                user_id=s["user_id"],
                total_value_usd=s["total_value_usd"],
                btc_value=s["btc_value"],
                snapshot_at=s["snapshot_at"],
            )
            self.db.add(snapshot)

        await self.db.commit()

        return {
            "success": True,
            "message": f"Backfilled {len(snapshots_to_create)} days of history",
            "points": len(snapshots_to_create),
        }

    # =========================================================================
    # Sync Single Account
    # =========================================================================

    async def sync_account(
        self,
        user_id: UUID,
        exchange_account_id: UUID,
    ) -> dict:
        """
        同步单个交易所账户的余额到 holdings 表
        """

        stmt = select(ExchangeAccount).where(
            and_(
                ExchangeAccount.id == exchange_account_id,
                ExchangeAccount.user_id == user_id,
            )
        )
        result = await self.db.execute(stmt)
        acct = result.scalar_one_or_none()

        if not acct:
            return {"success": False, "message": "Exchange account not found"}

        # Update sync status
        acct.sync_status = "syncing"
        await self.db.flush()

        try:
            balances = await self._fetch_account_balance(acct)
        except Exception as e:
            acct.sync_status = "failed"
            await self.db.commit()
            logger.error("Sync failed for account %s: %s", exchange_account_id, e)
            return {"success": False, "message": str(e)}

        # Get prices: prefer exchange ticker, CoinGecko as fallback
        symbols = [b["symbol"] for b in balances]
        prices: dict[str, float] = {}
        if symbols:
            try:
                api_key = decrypt_api_key(acct.api_key_encrypted)
                api_secret = decrypt_api_key(acct.api_secret_encrypted)
                passphrase = (
                    decrypt_api_key(acct.passphrase_encrypted)
                    if acct.passphrase_encrypted
                    else None
                )
                adapter = get_exchange_adapter(acct.exchange_name)
                ticker_data = await adapter.get_ticker_data(
                    api_key, api_secret, passphrase, symbols
                )
                prices = {s: d["price"] for s, d in ticker_data.items()}
            except Exception as e:
                logger.warning("Ticker fallback for sync_account: %s", e)

            # Fallback to CoinGecko for missing symbols
            missing = [s for s in symbols if s not in prices]
            if missing:
                fallback = await self.price_service.get_prices(missing)
                prices.update(fallback)

        # Build per-account holdings
        per_account = [
            {
                "user_id": user_id,
                "exchange_account_id": acct.id,
                "symbol": b["symbol"],
                "quantity": b["free"] + b["locked"],
                "free": b["free"],
                "locked": b["locked"],
            }
            for b in balances
        ]

        await self._upsert_holdings(user_id, per_account, prices)

        acct.sync_status = "success"
        acct.last_sync_at = datetime.now(timezone.utc)
        await self.db.commit()

        return {
            "success": True,
            "message": f"Synced {len(balances)} assets from {acct.exchange_name}",
            "synced_assets": len(balances),
        }

    # =========================================================================
    # Sync Portfolio Data (legacy compatible)
    # =========================================================================

    async def sync_portfolio_data(self, user: User) -> dict:
        """
        同步所有交易所账户数据（兼容旧接口）
        """
        user_id: UUID = user.id  # type: ignore[assignment]
        accounts = await self._get_active_accounts(user_id)

        if not accounts:
            return {"success": True, "message": "No active accounts", "synced_sources": 0}

        synced = 0
        for acct in accounts:
            result = await self.sync_account(user_id, acct.id)
            if result.get("success"):
                synced += 1

        return {
            "success": True,
            "message": f"Portfolio sync completed ({synced}/{len(accounts)} sources)",
            "synced_sources": synced,
        }

    # =========================================================================
    # Connected Sources
    # =========================================================================

    async def get_connected_sources(self, user: User) -> SourcesList:
        """
        获取用户已连接的数据源（从 exchange_accounts 表查询）
        """
        user_id: UUID = user.id  # type: ignore[assignment]

        stmt = (
            select(ExchangeAccount)
            .where(ExchangeAccount.user_id == user_id)
            .order_by(ExchangeAccount.created_at.desc())
        )
        result = await self.db.execute(stmt)
        accounts: list[ExchangeAccount] = list(result.scalars().all())

        sources: list[ConnectedSource] = []
        for acct in accounts:
            status = "active" if acct.is_active else "inactive"
            if acct.sync_status == "syncing":
                status = "syncing"

            sources.append(ConnectedSource(
                id=acct.id,
                name=acct.label or acct.exchange_name.capitalize(),
                type="api",
                exchange=acct.exchange_name,
                status=status,
                last_sync=acct.last_sync_at or acct.created_at,
            ))

        active_count = sum(1 for s in sources if s.status == "active")

        return SourcesList(
            sources=sources,
            total_count=len(sources),
            active_count=active_count,
        )

    # =========================================================================
    # Private helpers
    # =========================================================================

    async def _get_ticker_data_from_exchanges(
        self,
        accounts: list[ExchangeAccount],
        account_balances: list[tuple[ExchangeAccount, list[dict]]],
    ) -> dict[str, dict]:
        """
        从各交易所获取 ticker 数据（价格 + 24h 涨跌），去重后返回。
        同一交易所只请求一次。
        """
        all_data: dict[str, dict] = {}  # symbol -> {"price": ..., "change_24h_percent": ...}
        seen_exchanges: set[str] = set()

        for acct, balances in account_balances:
            if acct.exchange_name in seen_exchanges:
                continue
            seen_exchanges.add(acct.exchange_name)

            try:
                api_key = decrypt_api_key(acct.api_key_encrypted)
                api_secret = decrypt_api_key(acct.api_secret_encrypted)
                passphrase = (
                    decrypt_api_key(acct.passphrase_encrypted)
                    if acct.passphrase_encrypted
                    else None
                )

                adapter = get_exchange_adapter(acct.exchange_name)
                symbols = [b["symbol"] for b in balances]
                ticker_data = await adapter.get_ticker_data(
                    api_key, api_secret, passphrase, symbols
                )

                # 合并（先获取的优先保留）
                for sym, data in ticker_data.items():
                    if sym not in all_data:
                        all_data[sym] = data
            except Exception as e:
                logger.warning(
                    "Failed to get ticker data from %s: %s", acct.exchange_name, e
                )

        return all_data

    async def _get_active_accounts(self, user_id: UUID) -> list[ExchangeAccount]:
        """查询用户所有 active 的交易所账户"""
        stmt = select(ExchangeAccount).where(
            and_(
                ExchangeAccount.user_id == user_id,
                ExchangeAccount.is_active.is_(True),
            )
        )
        result = await self.db.execute(stmt)
        return list(result.scalars().all())

    async def get_account_balance(self, acct: ExchangeAccount) -> list[dict]:
        """Public wrapper for fetching a single exchange account's balance."""
        return await self._fetch_account_balance(acct)

    async def _fetch_account_balance(self, acct: ExchangeAccount) -> list[dict]:
        """获取单个交易所账户的现货 + 合约余额"""
        api_key = decrypt_api_key(acct.api_key_encrypted)
        api_secret = decrypt_api_key(acct.api_secret_encrypted)
        passphrase = (
            decrypt_api_key(acct.passphrase_encrypted)
            if acct.passphrase_encrypted
            else None
        )

        adapter = get_exchange_adapter(acct.exchange_name)

        # Spot balance
        spot = await adapter.get_spot_balance(api_key, api_secret, passphrase)

        # Futures balance (best-effort)
        futures: list[dict] = []
        try:
            futures = await adapter.get_futures_balance(api_key, api_secret, passphrase)
        except Exception as e:
            logger.warning("Failed to get futures balance for %s: %s", acct.exchange_name, e)

        # Merge spot + futures
        merged: dict[str, dict] = {}
        for item in spot + futures:
            sym = item["symbol"]
            if sym not in merged:
                merged[sym] = {"symbol": sym, "free": 0.0, "locked": 0.0}
            merged[sym]["free"] += item["free"]
            merged[sym]["locked"] += item["locked"]

        return list(merged.values())

    async def _fetch_all_balances(
        self, accounts: list[ExchangeAccount]
    ) -> list[tuple[ExchangeAccount, list[dict]]]:
        """并发获取所有账户余额，单个失败不影响其他"""

        async def _safe_fetch(acct: ExchangeAccount) -> tuple[ExchangeAccount, list[dict]]:
            try:
                balances = await self._fetch_account_balance(acct)
                # Update sync status
                acct.sync_status = "success"
                acct.last_sync_at = datetime.now(timezone.utc)
                return acct, balances
            except Exception as e:
                logger.error(
                    "Failed to fetch balance for account %s (%s): %s",
                    acct.id, acct.exchange_name, e,
                )
                acct.sync_status = "failed"
                # Fallback: use cached holdings from DB
                cached = await self._get_cached_holdings(acct)
                return acct, cached

        results = await asyncio.gather(
            *[_safe_fetch(acct) for acct in accounts],
            return_exceptions=True,
        )

        valid: list[tuple[ExchangeAccount, list[dict]]] = []
        for r in results:
            if isinstance(r, Exception):
                logger.error("Unexpected error in _fetch_all_balances: %s", r)
                continue
            valid.append(r)

        return valid

    async def _get_cached_holdings(self, acct: ExchangeAccount) -> list[dict]:
        """从 holdings 表获取缓存的余额数据（交易所 API 不可用时回退）"""
        stmt = select(Holding).where(Holding.exchange_account_id == acct.id)
        result = await self.db.execute(stmt)
        rows = result.scalars().all()
        return [
            {"symbol": h.symbol, "free": h.free, "locked": h.locked}
            for h in rows
        ]

    async def _upsert_holdings(
        self,
        user_id: UUID,
        per_account_holdings: list[dict],
        prices: dict[str, float],
    ) -> None:
        """
        更新 holdings 表 — 先删除该账户旧数据，再批量插入新数据。
        跨数据库兼容（不依赖 PostgreSQL ON CONFLICT）。
        """
        # Group by exchange_account_id
        by_account: dict[UUID, list[dict]] = {}
        for h in per_account_holdings:
            aid = h["exchange_account_id"]
            by_account.setdefault(aid, []).append(h)

        for account_id, items in by_account.items():
            # Delete old holdings for this account
            await self.db.execute(
                delete(Holding).where(Holding.exchange_account_id == account_id)
            )

            # Insert new
            for item in items:
                price = prices.get(item["symbol"], 0.0)
                qty = item["quantity"]
                holding = Holding(
                    user_id=user_id,
                    exchange_account_id=account_id,
                    symbol=item["symbol"],
                    quantity=qty,
                    free=item["free"],
                    locked=item["locked"],
                    price_usd=price,
                    value_usd=qty * price,
                )
                self.db.add(holding)

        await self.db.flush()

    async def _maybe_save_snapshot(
        self,
        user_id: UUID,
        total_value_usd: float,
        btc_value: Optional[float],
    ) -> None:
        """如果距上次快照超过 1 小时，保存一条新的 portfolio_snapshot"""
        stmt = (
            select(PortfolioSnapshot)
            .where(PortfolioSnapshot.user_id == user_id)
            .order_by(PortfolioSnapshot.snapshot_at.desc())
            .limit(1)
        )
        result = await self.db.execute(stmt)
        last_snapshot = result.scalar_one_or_none()

        now = datetime.now(timezone.utc)
        if last_snapshot:
            snapshot_time = last_snapshot.snapshot_at
            if snapshot_time.tzinfo is None:
                snapshot_time = snapshot_time.replace(tzinfo=timezone.utc)
            if (now - snapshot_time) < _SNAPSHOT_COOLDOWN:
                return

        snapshot = PortfolioSnapshot(
            user_id=user_id,
            total_value_usd=total_value_usd,
            btc_value=btc_value,
        )
        self.db.add(snapshot)
        await self.db.flush()
