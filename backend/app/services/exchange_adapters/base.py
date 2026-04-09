from abc import ABC, abstractmethod
from typing import Optional


class ExchangeAdapter(ABC):
    """Base class for exchange adapters."""
    
    @abstractmethod
    async def verify_connection(
        self, 
        api_key: str, 
        api_secret: str, 
        passphrase: Optional[str] = None
    ) -> bool:
        """
        Verify connection to the exchange with provided credentials.
        
        Args:
            api_key: The API key for the exchange
            api_secret: The API secret for the exchange
            passphrase: Optional passphrase (required for some exchanges like OKX)
            
        Returns:
            True if connection is successful, False otherwise
        """
        ...
    
    @abstractmethod
    async def get_spot_balance(
        self, 
        api_key: str, 
        api_secret: str, 
        passphrase: Optional[str] = None
    ) -> list[dict]:
        """
        Get spot wallet balance.
        
        Args:
            api_key: The API key for the exchange
            api_secret: The API secret for the exchange
            passphrase: Optional passphrase
            
        Returns:
            List of balance items with asset, free, and locked amounts
        """
        ...
    
    @abstractmethod
    async def get_futures_balance(
        self, 
        api_key: str, 
        api_secret: str, 
        passphrase: Optional[str] = None
    ) -> list[dict]:
        """
        Get futures/perpetual wallet balance.
        
        Args:
            api_key: The API key for the exchange
            api_secret: The API secret for the exchange
            passphrase: Optional passphrase
            
        Returns:
            List of balance items with asset, wallet balance, and unrealized PnL
        """
        ...
    
    @abstractmethod
    async def get_ticker_data(
        self,
        api_key: str,
        api_secret: str,
        passphrase: Optional[str] = None,
        symbols: Optional[list[str]] = None,
    ) -> dict[str, dict]:
        """
        Get ticker data (price + 24h change) from the exchange.

        Args:
            api_key: The API key for the exchange
            api_secret: The API secret for the exchange
            passphrase: Optional passphrase
            symbols: List of base symbols like ["BTC", "ETH"]. None = all.

        Returns:
            Dict of symbol -> {"price": float, "change_24h_percent": float}
            e.g. {"BTC": {"price": 64281.0, "change_24h_percent": -2.3}}
        """
        ...

    @abstractmethod
    async def get_trade_history(
        self,
        api_key: str,
        api_secret: str,
        passphrase: Optional[str] = None,
        since_ms: Optional[int] = None,
    ) -> list[dict]:
        """
        Get trade history.

        Args:
            api_key: The API key for the exchange
            api_secret: The API secret for the exchange
            passphrase: Optional passphrase
            since_ms: Fetch trades since this timestamp (milliseconds)

        Returns:
            List of trades: [{"symbol": "BTC", "side": "buy", "amount": 0.1, "timestamp": 1704067200000}, ...]
        """
        ...

    @abstractmethod
    async def get_transfer_history(
        self,
        api_key: str,
        api_secret: str,
        passphrase: Optional[str] = None,
        since_ms: Optional[int] = None,
    ) -> list[dict]:
        """
        Get deposit and withdrawal history.

        Args:
            api_key: The API key for the exchange
            api_secret: The API secret for the exchange
            passphrase: Optional passphrase
            since_ms: Fetch transfers since this timestamp (milliseconds)

        Returns:
            List of transfers: [{"symbol": "BTC", "type": "deposit"/"withdrawal", "amount": 0.5, "timestamp": 1704067200000}, ...]
        """
        ...

    @property
    @abstractmethod
    def exchange_name(self) -> str:
        """Return the name of the exchange."""
        ...
