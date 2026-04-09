"""
Unified exchange adapter using ccxt library.
Supports: Binance, OKX, Bybit, Coinbase, Gate.io, Bitget.
"""
import logging
from typing import Optional

import ccxt.async_support as ccxt

# Stablecoins that are always pegged to 1 USD
_STABLECOINS = {"USDT", "USDC", "DAI", "BUSD", "TUSD", "USDP", "FDUSD"}

from .base import ExchangeAdapter

logger = logging.getLogger(__name__)

# Exchanges that do NOT support futures/swap
_NO_FUTURES_EXCHANGES = {"coinbase"}

# Type parameter variants to try for futures balance
_FUTURES_TYPE_VARIANTS = ["swap", "future"]


class CcxtAdapter(ExchangeAdapter):
    """Unified exchange adapter powered by ccxt, covering 6 major exchanges."""

    EXCHANGE_MAP: dict[str, type] = {
        "binance": ccxt.binance,
        "okx": ccxt.okx,
        "bybit": ccxt.bybit,
        "coinbase": ccxt.coinbase,
        "gateio": ccxt.gateio,
        "gate_io": ccxt.gateio,
        "bitget": ccxt.bitget,
    }

    def __init__(self, exchange_name: str):
        if exchange_name not in self.EXCHANGE_MAP:
            raise ValueError(
                f"Unsupported exchange: {exchange_name}. "
                f"Supported: {list(self.EXCHANGE_MAP.keys())}"
            )
        self._exchange_name = exchange_name

    @property
    def exchange_name(self) -> str:
        return self._exchange_name

    # ------------------------------------------------------------------
    # Internal helpers
    # ------------------------------------------------------------------

    def _create_instance(
        self,
        api_key: str,
        api_secret: str,
        passphrase: Optional[str] = None,
    ) -> ccxt.Exchange:
        """Create a ccxt exchange instance with credentials."""
        cls = self.EXCHANGE_MAP[self._exchange_name]
        config: dict = {
            "apiKey": api_key,
            "secret": api_secret,
            "enableRateLimit": True,
        }
        if passphrase:
            config["password"] = passphrase
        return cls(config)

    # ------------------------------------------------------------------
    # Public interface (ExchangeAdapter)
    # ------------------------------------------------------------------

    async def verify_connection(
        self,
        api_key: str,
        api_secret: str,
        passphrase: Optional[str] = None,
    ) -> bool:
        """Verify API credentials by attempting to fetch the account balance."""
        exchange = self._create_instance(api_key, api_secret, passphrase)
        try:
            await exchange.fetch_balance()
            return True
        except ccxt.AuthenticationError:
            logger.warning("Authentication failed for %s", self._exchange_name)
            return False
        except ccxt.NetworkError as exc:
            logger.error("Network error verifying %s: %s", self._exchange_name, exc)
            return False
        except ccxt.ExchangeError as exc:
            logger.error("Exchange error verifying %s: %s", self._exchange_name, exc)
            return False
        finally:
            await exchange.close()

    async def get_spot_balance(
        self,
        api_key: str,
        api_secret: str,
        passphrase: Optional[str] = None,
    ) -> list[dict]:
        """
        Fetch spot account balances.

        Returns:
            List of dicts: [{"symbol": "BTC", "free": 8.49, "locked": 0.1}, ...]
            Only assets with non-zero balance are included.
        """
        exchange = self._create_instance(api_key, api_secret, passphrase)
        try:
            balance = await exchange.fetch_balance()
            return self._parse_balance(balance)
        except ccxt.AuthenticationError:
            raise ValueError(f"Invalid API credentials for {self._exchange_name}")
        except ccxt.NetworkError as exc:
            raise ConnectionError(
                f"Network error fetching spot balance from {self._exchange_name}: {exc}"
            )
        except ccxt.ExchangeError as exc:
            raise RuntimeError(
                f"Exchange error fetching spot balance from {self._exchange_name}: {exc}"
            )
        finally:
            await exchange.close()

    async def get_futures_balance(
        self,
        api_key: str,
        api_secret: str,
        passphrase: Optional[str] = None,
    ) -> list[dict]:
        """
        Fetch futures/swap account balances.

        Coinbase does not support futures — returns [].
        For other exchanges, tries 'swap' first, then 'future'.
        """
        if self._exchange_name in _NO_FUTURES_EXCHANGES:
            return []

        exchange = self._create_instance(api_key, api_secret, passphrase)
        try:
            balance = await self._fetch_futures_balance(exchange)
            return self._parse_balance(balance)
        except ccxt.AuthenticationError:
            raise ValueError(
                f"Invalid API credentials for {self._exchange_name} futures"
            )
        except ccxt.NetworkError as exc:
            raise ConnectionError(
                f"Network error fetching futures balance from {self._exchange_name}: {exc}"
            )
        except ccxt.ExchangeError as exc:
            logger.warning(
                "Futures not available for %s: %s", self._exchange_name, exc
            )
            return []
        finally:
            await exchange.close()

    async def get_ticker_data(
        self,
        api_key: str,
        api_secret: str,
        passphrase: Optional[str] = None,
        symbols: Optional[list[str]] = None,
    ) -> dict[str, dict]:
        """
        从交易所获取币种的 USDT 价格和 24h 涨跌。

        通过 fetch_tickers() 获取 XXX/USDT 交易对的最新价格。
        对于没有 USDT 交易对的币种，尝试 XXX/BTC 再乘以 BTC 价格。
        稳定币直接返回 1.0。

        Returns:
            {"BTC": {"price": 64281.0, "change_24h_percent": -2.3}, ...}
        """
        exchange = self._create_instance(api_key, api_secret, passphrase)
        try:
            return await self._fetch_ticker_data(exchange, symbols)
        except Exception as exc:
            logger.warning(
                "Failed to get ticker data from %s: %s", self._exchange_name, exc
            )
            return {}
        finally:
            await exchange.close()

    async def _fetch_ticker_data(
        self,
        exchange: ccxt.Exchange,
        symbols: Optional[list[str]] = None,
    ) -> dict[str, dict]:
        """Internal: fetch and parse ticker data."""
        result: dict[str, dict] = {}

        if symbols is None:
            symbols = []

        # 1. Separate stablecoins — they don't need a ticker lookup
        non_stable = []
        for sym in symbols:
            if sym.upper() in _STABLECOINS:
                result[sym] = {"price": 1.0, "change_24h_percent": 0.0}
            else:
                non_stable.append(sym)

        if not non_stable:
            return result

        # 2. Build USDT pairs to fetch
        usdt_pairs = [f"{s}/USDT" for s in non_stable]

        try:
            tickers = await exchange.fetch_tickers(usdt_pairs)
        except Exception:
            # Some exchanges reject unknown symbols; fall back to fetch all
            tickers = await exchange.fetch_tickers()

        # 3. Parse USDT-pair tickers
        missing_usdt: list[str] = []  # symbols without a USDT pair
        btc_price: Optional[float] = None

        for sym in non_stable:
            pair = f"{sym}/USDT"
            ticker = tickers.get(pair)
            if ticker and ticker.get("last") is not None:
                price = float(ticker["last"])
                change_pct = float(ticker.get("percentage") or 0.0)
                result[sym] = {"price": price, "change_24h_percent": change_pct}
                if sym == "BTC":
                    btc_price = price
            else:
                missing_usdt.append(sym)

        # 4. For missing symbols, try XXX/BTC pairs
        if missing_usdt:
            # Make sure we have the BTC price
            if btc_price is None:
                btc_ticker = tickers.get("BTC/USDT")
                if btc_ticker and btc_ticker.get("last"):
                    btc_price = float(btc_ticker["last"])
                else:
                    try:
                        btc_ticker = await exchange.fetch_ticker("BTC/USDT")
                        btc_price = float(btc_ticker["last"]) if btc_ticker else None
                    except Exception:
                        btc_price = None

            if btc_price and btc_price > 0:
                btc_pairs = [f"{s}/BTC" for s in missing_usdt]
                try:
                    btc_tickers = await exchange.fetch_tickers(btc_pairs)
                except Exception:
                    btc_tickers = {}

                for sym in missing_usdt:
                    pair = f"{sym}/BTC"
                    ticker = btc_tickers.get(pair)
                    if ticker and ticker.get("last") is not None:
                        btc_qty_price = float(ticker["last"])
                        usd_price = btc_qty_price * btc_price
                        change_pct = float(ticker.get("percentage") or 0.0)
                        result[sym] = {
                            "price": usd_price,
                            "change_24h_percent": change_pct,
                        }

        return result

    async def get_trade_history(
        self,
        api_key: str,
        api_secret: str,
        passphrase: Optional[str] = None,
        since_ms: Optional[int] = None,
    ) -> list[dict]:
        """
        Fetch trade history.
        Returns: [{"symbol": "BTC", "side": "buy", "amount": 0.1, "timestamp": ...}, ...]
        """
        exchange = self._create_instance(api_key, api_secret, passphrase)
        try:
            # Try fetching trades for common USDT pairs
            all_trades: list[dict] = []
            # Some exchanges support fetching all trades with symbol=None
            try:
                raw_trades = await exchange.fetch_my_trades(symbol=None, since=since_ms, limit=200)
                for t in raw_trades:
                    base = (t.get("symbol") or "").split("/")[0]
                    if not base:
                        continue
                    all_trades.append({
                        "symbol": base,
                        "side": t.get("side", "buy"),
                        "amount": float(t.get("amount", 0)),
                        "timestamp": t.get("timestamp", 0),
                    })
            except Exception:
                # Fallback: try major pairs individually
                major_pairs = ["BTC/USDT", "ETH/USDT", "BNB/USDT", "SOL/USDT", "XRP/USDT"]
                for pair in major_pairs:
                    try:
                        raw_trades = await exchange.fetch_my_trades(
                            symbol=pair, since=since_ms, limit=100
                        )
                        base = pair.split("/")[0]
                        for t in raw_trades:
                            all_trades.append({
                                "symbol": base,
                                "side": t.get("side", "buy"),
                                "amount": float(t.get("amount", 0)),
                                "timestamp": t.get("timestamp", 0),
                            })
                    except Exception:
                        continue
            return all_trades
        except Exception as exc:
            logger.warning("Failed to fetch trade history from %s: %s", self._exchange_name, exc)
            return []
        finally:
            await exchange.close()

    async def get_transfer_history(
        self,
        api_key: str,
        api_secret: str,
        passphrase: Optional[str] = None,
        since_ms: Optional[int] = None,
    ) -> list[dict]:
        """
        Fetch deposit and withdrawal history.
        Returns: [{"symbol": "BTC", "type": "deposit"/"withdrawal", "amount": 0.5, "timestamp": ...}, ...]
        """
        exchange = self._create_instance(api_key, api_secret, passphrase)
        try:
            results: list[dict] = []

            # Fetch deposits
            try:
                deposits = await exchange.fetch_deposits(code=None, since=since_ms, limit=200)
                for d in deposits:
                    currency = d.get("currency", "")
                    if not currency:
                        continue
                    results.append({
                        "symbol": currency,
                        "type": "deposit",
                        "amount": float(d.get("amount", 0)),
                        "timestamp": d.get("timestamp", 0),
                    })
            except Exception as exc:
                logger.debug("fetch_deposits not supported for %s: %s", self._exchange_name, exc)

            # Fetch withdrawals
            try:
                withdrawals = await exchange.fetch_withdrawals(code=None, since=since_ms, limit=200)
                for w in withdrawals:
                    currency = w.get("currency", "")
                    if not currency:
                        continue
                    results.append({
                        "symbol": currency,
                        "type": "withdrawal",
                        "amount": float(w.get("amount", 0)),
                        "timestamp": w.get("timestamp", 0),
                    })
            except Exception as exc:
                logger.debug("fetch_withdrawals not supported for %s: %s", self._exchange_name, exc)

            return results
        except Exception as exc:
            logger.warning("Failed to fetch transfer history from %s: %s", self._exchange_name, exc)
            return []
        finally:
            await exchange.close()

    # ------------------------------------------------------------------
    # Private helpers
    # ------------------------------------------------------------------

    @staticmethod
    async def _fetch_futures_balance(exchange: ccxt.Exchange) -> dict:
        """Try fetching futures balance with different type params."""
        last_exc: Optional[Exception] = None
        for variant in _FUTURES_TYPE_VARIANTS:
            try:
                return await exchange.fetch_balance({"type": variant})
            except ccxt.ExchangeError as exc:
                last_exc = exc
                continue
        # If all variants failed, raise the last exception
        raise last_exc  # type: ignore[misc]

    @staticmethod
    def _parse_balance(balance: dict) -> list[dict]:
        """
        Parse ccxt balance response into a flat list.

        ccxt returns:
            { 'BTC': {'free': 8.49, 'used': 0.1, 'total': 8.59}, ... }
        We convert to:
            [{'symbol': 'BTC', 'free': 8.49, 'locked': 0.1}, ...]
        """
        results: list[dict] = []
        for symbol, amounts in balance.items():
            # Skip metadata keys that ccxt adds (info, free, used, total, ...)
            if not isinstance(amounts, dict):
                continue
            free = float(amounts.get("free", 0) or 0)
            locked = float(amounts.get("used", 0) or 0)
            if free + locked > 0:
                results.append({
                    "symbol": symbol,
                    "free": free,
                    "locked": locked,
                })
        return results
