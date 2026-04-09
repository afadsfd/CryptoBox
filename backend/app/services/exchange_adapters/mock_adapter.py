"""
Mock exchange adapter for development and testing.
Always returns success with sample data.
"""
from typing import Optional

from .base import ExchangeAdapter


class MockExchangeAdapter(ExchangeAdapter):
    """Mock adapter for development - always returns success."""

    def __init__(self, exchange_name: str = "mock"):
        self._exchange_name = exchange_name

    @property
    def exchange_name(self) -> str:
        """Return the name of the exchange."""
        return self._exchange_name

    async def verify_connection(
        self,
        api_key: str,
        api_secret: str,
        passphrase: Optional[str] = None
    ) -> bool:
        """
        Verify connection to the exchange with provided credentials.
        Mock implementation always returns True.
        
        Args:
            api_key: The API key for the exchange
            api_secret: The API secret for the exchange
            passphrase: Optional passphrase (required for some exchanges like OKX)
            
        Returns:
            True if connection is successful, False otherwise
        """
        # Mock: Always return success
        # In production, this would make an actual API call to verify credentials
        return True

    async def get_spot_balance(
        self,
        api_key: str,
        api_secret: str,
        passphrase: Optional[str] = None
    ) -> list[dict]:
        """
        Get spot wallet balance.
        Mock implementation returns sample data.
        
        Args:
            api_key: The API key for the exchange
            api_secret: The API secret for the exchange
            passphrase: Optional passphrase
            
        Returns:
            List of balance items with asset, free, and locked amounts
        """
        # Mock: Return sample spot balances
        return [
            {"symbol": "BTC", "free": 8.49, "locked": 0.0},
            {"symbol": "ETH", "free": 105.7, "locked": 2.3},
            {"symbol": "USDT", "free": 15000.0, "locked": 0.0},
            {"symbol": "BNB", "free": 150.5, "locked": 10.0},
            {"symbol": "SOL", "free": 250.0, "locked": 0.0},
        ]

    async def get_futures_balance(
        self,
        api_key: str,
        api_secret: str,
        passphrase: Optional[str] = None
    ) -> list[dict]:
        """
        Get futures/perpetual wallet balance.
        Mock implementation returns sample data.
        """
        return [
            {"symbol": "USDT", "free": 5000.0, "locked": 0.0},
            {"symbol": "BTC", "free": 2.5, "locked": 0.0},
            {"symbol": "ETH", "free": 25.0, "locked": 0.0},
        ]

    async def get_ticker_data(
        self,
        api_key: str,
        api_secret: str,
        passphrase: Optional[str] = None,
        symbols: Optional[list[str]] = None,
    ) -> dict[str, dict]:
        """
        Get ticker data. Mock implementation returns sample prices.
        """
        mock_data = {
            "BTC": {"price": 64281.0, "change_24h_percent": -2.3},
            "ETH": {"price": 3412.18, "change_24h_percent": 1.5},
            "BNB": {"price": 580.0, "change_24h_percent": 0.8},
            "SOL": {"price": 142.5, "change_24h_percent": 3.2},
            "USDT": {"price": 1.0, "change_24h_percent": 0.0},
            "USDC": {"price": 1.0, "change_24h_percent": 0.0},
        }
        if symbols:
            return {s: mock_data.get(s, {"price": 1.0, "change_24h_percent": 0.0}) for s in symbols}
        return mock_data

    async def get_trade_history(
        self,
        api_key: str,
        api_secret: str,
        passphrase: Optional[str] = None,
        since_ms: Optional[int] = None,
    ) -> list[dict]:
        """Mock: return empty trade history."""
        return []

    async def get_transfer_history(
        self,
        api_key: str,
        api_secret: str,
        passphrase: Optional[str] = None,
        since_ms: Optional[int] = None,
    ) -> list[dict]:
        """Mock: return empty transfer history."""
        return []

