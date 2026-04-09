import asyncio
import json
import logging
from datetime import datetime, timezone
from typing import Optional

import httpx

logger = logging.getLogger(__name__)


class PriceService:
    """CoinGecko 价格服务，带 Redis 缓存"""

    COINGECKO_URL = "https://api.coingecko.com/api/v3"
    CACHE_TTL = 60  # 秒
    HISTORY_CACHE_TTL = 300  # 秒

    # 稳定币列表，直接返回 1.0
    STABLECOINS = {"USDT", "USDC", "DAI", "BUSD"}

    # 常见加密货币 symbol -> CoinGecko ID 映射
    SYMBOL_MAP = {
        "BTC": "bitcoin",
        "ETH": "ethereum",
        "BNB": "binancecoin",
        "SOL": "solana",
        "XRP": "ripple",
        "DOGE": "dogecoin",
        "ADA": "cardano",
        "AVAX": "avalanche-2",
        "DOT": "polkadot",
        "MATIC": "matic-network",
        "LINK": "chainlink",
        "UNI": "uniswap",
        "ATOM": "cosmos",
        "LTC": "litecoin",
        "FIL": "filecoin",
        "NEAR": "near",
        "APT": "aptos",
        "ARB": "arbitrum",
        "OP": "optimism",
        "SUI": "sui",
        "USDT": "tether",
        "USDC": "usd-coin",
        "DAI": "dai",
        "BUSD": "binance-usd",
        "TRX": "tron",
        "SHIB": "shiba-inu",
        "PEPE": "pepe",
        "WIF": "dogwifcoin",
        "TON": "the-open-network",
        "OKB": "okb",
        "GT": "gatechain-token",
        "BGB": "bitget-token",
    }

    # 反向映射: coingecko_id -> symbol
    ID_TO_SYMBOL = {v: k for k, v in SYMBOL_MAP.items()}

    def __init__(self, redis_client=None):
        self.redis = redis_client

    # ── Redis helpers ──────────────────────────────────────────────

    async def _cache_get(self, key: str) -> Optional[str]:
        if self.redis is None:
            return None
        try:
            return await self.redis.get(key)
        except Exception as e:
            logger.warning("Redis GET failed for key=%s: %s", key, e)
            return None

    async def _cache_set(self, key: str, value: str, ttl: int) -> None:
        if self.redis is None:
            return
        try:
            await self.redis.set(key, value, ex=ttl)
        except Exception as e:
            logger.warning("Redis SET failed for key=%s: %s", key, e)

    # ── HTTP helper with 429 retry ─────────────────────────────────

    async def _request(self, url: str, params: Optional[dict] = None) -> Optional[dict]:
        async with httpx.AsyncClient(timeout=10.0) as client:
            for attempt in range(2):
                try:
                    resp = await client.get(url, params=params)
                    if resp.status_code == 429:
                        if attempt == 0:
                            retry_after = int(resp.headers.get("Retry-After", "5"))
                            logger.warning("CoinGecko rate limit hit, retrying after %ds", retry_after)
                            await asyncio.sleep(retry_after)
                            continue
                        logger.error("CoinGecko rate limit hit twice, giving up")
                        return None
                    resp.raise_for_status()
                    return resp.json()
                except httpx.HTTPStatusError as e:
                    logger.error("CoinGecko HTTP error: %s", e)
                    return None
                except httpx.RequestError as e:
                    logger.error("CoinGecko request error: %s", e)
                    return None
        return None

    # ── Public API ─────────────────────────────────────────────────

    async def get_prices(self, symbols: list[str]) -> dict[str, float]:
        """
        获取多个币种的 USD 价格。
        稳定币直接返回 1.0；其余先查缓存，未命中的批量请求 CoinGecko。
        """
        result: dict[str, float] = {}
        to_fetch: list[str] = []  # symbols that need API call

        for sym in symbols:
            sym_upper = sym.upper()

            # 稳定币
            if sym_upper in self.STABLECOINS:
                result[sym_upper] = 1.0
                continue

            # 未知 symbol
            if sym_upper not in self.SYMBOL_MAP:
                logger.warning("Unknown symbol: %s, skipping", sym_upper)
                continue

            # 查缓存
            cached = await self._cache_get(f"price:{sym_upper}")
            if cached is not None:
                try:
                    result[sym_upper] = float(cached)
                    continue
                except (ValueError, TypeError):
                    pass

            to_fetch.append(sym_upper)

        if not to_fetch:
            return result

        # 批量请求 CoinGecko
        ids = ",".join(self.SYMBOL_MAP[s] for s in to_fetch)
        data = await self._request(
            f"{self.COINGECKO_URL}/simple/price",
            params={"ids": ids, "vs_currencies": "usd"},
        )

        if data:
            for sym in to_fetch:
                cg_id = self.SYMBOL_MAP[sym]
                price = data.get(cg_id, {}).get("usd")
                if price is not None:
                    result[sym] = float(price)
                    await self._cache_set(f"price:{sym}", str(price), self.CACHE_TTL)

        return result

    async def get_price_history(
        self, symbol: str, days: int = 30
    ) -> list[dict]:
        """
        获取币种历史价格（USD）。
        返回 [{"timestamp": "2024-01-01T00:00:00Z", "price": 42000.0}, ...]
        """
        sym_upper = symbol.upper()
        if sym_upper not in self.SYMBOL_MAP:
            logger.warning("Unknown symbol for history: %s", sym_upper)
            return []

        # 查缓存
        cache_key = f"price_history:{sym_upper}:{days}"
        cached = await self._cache_get(cache_key)
        if cached is not None:
            try:
                return json.loads(cached)
            except (json.JSONDecodeError, TypeError):
                pass

        cg_id = self.SYMBOL_MAP[sym_upper]
        data = await self._request(
            f"{self.COINGECKO_URL}/coins/{cg_id}/market_chart",
            params={"vs_currency": "usd", "days": str(days)},
        )

        if not data or "prices" not in data:
            return []

        history = []
        for ts_ms, price in data["prices"]:
            dt = datetime.fromtimestamp(ts_ms / 1000, tz=timezone.utc)
            history.append({
                "timestamp": dt.strftime("%Y-%m-%dT%H:%M:%SZ"),
                "price": float(price),
            })

        await self._cache_set(cache_key, json.dumps(history), self.HISTORY_CACHE_TTL)
        return history

    async def get_24h_change(self, symbols: list[str]) -> dict[str, float]:
        """
        获取多个币种 24h 价格变动百分比。
        返回 {"BTC": -2.34, "ETH": 1.56}
        """
        valid_symbols = []
        for sym in symbols:
            sym_upper = sym.upper()
            if sym_upper in self.STABLECOINS:
                continue
            if sym_upper not in self.SYMBOL_MAP:
                logger.warning("Unknown symbol for 24h change: %s", sym_upper)
                continue
            valid_symbols.append(sym_upper)

        if not valid_symbols:
            return {}

        ids = ",".join(self.SYMBOL_MAP[s] for s in valid_symbols)
        data = await self._request(
            f"{self.COINGECKO_URL}/simple/price",
            params={
                "ids": ids,
                "vs_currencies": "usd",
                "include_24hr_change": "true",
            },
        )

        result: dict[str, float] = {}
        if data:
            for sym in valid_symbols:
                cg_id = self.SYMBOL_MAP[sym]
                change = data.get(cg_id, {}).get("usd_24h_change")
                if change is not None:
                    result[sym] = round(float(change), 2)

        return result
