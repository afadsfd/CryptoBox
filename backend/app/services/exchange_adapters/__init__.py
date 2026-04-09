"""
Exchange adapter factory.

Uses CcxtAdapter by default. Set environment variable USE_MOCK_EXCHANGE=true
to fall back to MockExchangeAdapter (useful for local development / testing).
"""
import os

from .base import ExchangeAdapter
from .ccxt_adapter import CcxtAdapter
from .mock_adapter import MockExchangeAdapter

__all__ = [
    "ExchangeAdapter",
    "CcxtAdapter",
    "MockExchangeAdapter",
    "get_exchange_adapter",
]


def get_exchange_adapter(exchange_name: str) -> ExchangeAdapter:
    """
    Get an exchange adapter for the specified exchange.

    Args:
        exchange_name: The name of the exchange (e.g., 'binance', 'okx')

    Returns:
        An ExchangeAdapter instance (CcxtAdapter or MockExchangeAdapter).
    """
    use_mock = os.getenv("USE_MOCK_EXCHANGE", "false").lower() in ("true", "1", "yes")

    if use_mock:
        return MockExchangeAdapter(exchange_name)

    # Default: real ccxt adapter
    return CcxtAdapter(exchange_name)
