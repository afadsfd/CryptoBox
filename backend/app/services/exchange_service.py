"""
Exchange service for managing exchange connections and operations.
"""
import logging
from datetime import datetime, timezone
from typing import Optional
from uuid import UUID

from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.exchange_account import ExchangeAccount
from app.models.holding import Holding
from app.schemas.exchange import (
    ConnectedExchange,
    ConnectExchangeResponse,
    DisconnectExchangeResponse,
    ExchangeStatus,
    SupportedExchange,
    SyncResponse,
)
from app.services.exchange_adapters import get_exchange_adapter
from app.utils.exceptions import NotFoundError, ValidationError
from app.utils.security import encrypt_api_key

logger = logging.getLogger(__name__)


def _parse_uuid(value: str, label: str = "ID") -> UUID:
    """Safely parse a UUID string, raising ValidationError on failure."""
    try:
        return UUID(value)
    except (ValueError, AttributeError):
        raise ValidationError(f"Invalid {label}: {value}")


class ExchangeService:
    """Service for handling exchange-related operations."""

    # Hardcoded list of supported exchanges
    SUPPORTED_EXCHANGES = [
        SupportedExchange(
            id="binance",
            name="Binance",
            description="World's largest exchange",
            logo_color="#F3BA2F",
            supports_spot=True,
            supports_futures=True,
            requires_passphrase=False,
            is_featured=True,
            status="available",
        ),
        SupportedExchange(
            id="bybit",
            name="Bybit",
            description="Derivatives optimized",
            logo_color="#000000",
            supports_spot=True,
            supports_futures=True,
            requires_passphrase=False,
            is_featured=False,
            status="available",
        ),
        SupportedExchange(
            id="okx",
            name="OKX",
            description="Unified trading engine",
            logo_color="#FFFFFF",
            supports_spot=True,
            supports_futures=True,
            requires_passphrase=True,
            is_featured=False,
            status="available",
        ),
        SupportedExchange(
            id="coinbase",
            name="Coinbase",
            description="OAuth & API support",
            logo_color="#0052FF",
            supports_spot=True,
            supports_futures=False,
            requires_passphrase=False,
            is_featured=False,
            status="available",
        ),
        SupportedExchange(
            id="gateio",
            name="Gate.io",
            description="Multi-asset exchange",
            logo_color="#2354E6",
            supports_spot=True,
            supports_futures=True,
            requires_passphrase=False,
            is_featured=False,
            status="available",
        ),
        SupportedExchange(
            id="bitget",
            name="Bitget",
            description="Copy trading leader",
            logo_color="#00F0FF",
            supports_spot=True,
            supports_futures=True,
            requires_passphrase=False,
            is_featured=False,
            status="available",
        ),
    ]

    def __init__(self, db: AsyncSession):
        self.db = db

    @classmethod
    def get_supported_exchanges(cls) -> list[SupportedExchange]:
        """
        Get list of all supported exchanges.
        
        Returns:
            List of SupportedExchange objects.
        """
        return cls.SUPPORTED_EXCHANGES

    @classmethod
    def get_exchange_by_id(cls, exchange_id: str) -> Optional[SupportedExchange]:
        """
        Get a specific exchange by its ID.
        
        Args:
            exchange_id: The exchange identifier.
            
        Returns:
            SupportedExchange if found, None otherwise.
        """
        for exchange in cls.SUPPORTED_EXCHANGES:
            if exchange.id == exchange_id:
                return exchange
        return None

    async def get_connected_exchanges(self, user_id: UUID) -> list[ConnectedExchange]:
        """
        Get all active connected exchanges for a user.
        
        Args:
            user_id: The user's UUID.
            
        Returns:
            List of ConnectedExchange objects.
        """
        result = await self.db.execute(
            select(ExchangeAccount).where(
                ExchangeAccount.user_id == user_id,
                ExchangeAccount.is_active.is_(True),
            )
        )
        accounts = result.scalars().all()

        return [
            ConnectedExchange(
                id=str(account.id),
                exchange_name=account.exchange_name,
                label=account.label,
                is_active=account.is_active,
                last_sync_at=account.last_sync_at,
                sync_status=account.sync_status,
            )
            for account in accounts
        ]

    async def get_connected_exchange(
        self, user_id: UUID, account_id: str
    ) -> Optional[ConnectedExchange]:
        """
        Get a specific connected exchange by account ID.
        
        Args:
            user_id: The user's UUID.
            account_id: The account UUID string.
            
        Returns:
            ConnectedExchange if found, None otherwise.
        """
        parsed_id = _parse_uuid(account_id, "exchange account ID")
        result = await self.db.execute(
            select(ExchangeAccount).where(
                ExchangeAccount.user_id == user_id,
                ExchangeAccount.id == parsed_id,
                ExchangeAccount.is_active.is_(True),
            )
        )
        account = result.scalar_one_or_none()

        if not account:
            return None

        return ConnectedExchange(
            id=str(account.id),
            exchange_name=account.exchange_name,
            label=account.label,
            is_active=account.is_active,
            last_sync_at=account.last_sync_at,
            sync_status=account.sync_status,
        )

    async def disconnect_exchange(
        self, user_id: UUID, account_id: str
    ) -> DisconnectExchangeResponse:
        """
        Soft delete (disconnect) an exchange connection.
        
        Args:
            user_id: The user's UUID.
            account_id: The account UUID string.
            
        Returns:
            DisconnectExchangeResponse with success status.
            
        Raises:
            NotFoundError: If the exchange connection is not found.
        """
        parsed_id = _parse_uuid(account_id, "exchange account ID")
        result = await self.db.execute(
            select(ExchangeAccount).where(
                ExchangeAccount.user_id == user_id,
                ExchangeAccount.id == parsed_id,
            )
        )
        account = result.scalar_one_or_none()

        if not account:
            raise NotFoundError("Exchange connection")

        # Soft delete: set is_active to False
        account.is_active = False
        account.updated_at = datetime.now(timezone.utc)

        await self.db.commit()
        await self.db.refresh(account)

        return DisconnectExchangeResponse(
            success=True,
            message="Exchange disconnected successfully"
        )

    async def connect_exchange(
        self,
        user_id: UUID,
        exchange_id: str,
        label: Optional[str],
        api_key: str,
        api_secret: str,
        passphrase: Optional[str] = None,
    ) -> ConnectExchangeResponse:
        """
        Connect a new exchange with API key validation and encryption.
        
        Args:
            user_id: The user's UUID.
            exchange_id: The exchange identifier.
            label: Optional label for the connection.
            api_key: The API key.
            api_secret: The API secret.
            passphrase: Optional passphrase.
            
        Returns:
            ConnectExchangeResponse with connection details.
            
        Raises:
            ValidationError: If the exchange is not supported or credentials are invalid.
        """
        # Validate exchange is supported
        exchange = self.get_exchange_by_id(exchange_id)
        if not exchange:
            raise ValidationError(f"Exchange '{exchange_id}' is not supported")

        dup = await self.db.execute(
            select(ExchangeAccount).where(
                ExchangeAccount.user_id == user_id,
                ExchangeAccount.exchange_name == exchange_id,
                ExchangeAccount.is_active.is_(True),
            )
        )
        if dup.scalar_one_or_none() is not None:
            raise ValidationError(
                f"You already have an active connection to {exchange.name}. "
                "Disconnect it first or use a different account."
            )

        # Check if passphrase is required but not provided
        if exchange.requires_passphrase and not passphrase:
            raise ValidationError(f"Passphrase is required for {exchange.name}")

        # Verify connection using adapter
        adapter = get_exchange_adapter(exchange_id)
        is_valid = await adapter.verify_connection(api_key, api_secret, passphrase)
        
        if not is_valid:
            raise ValidationError("Invalid API credentials. Please check your API key and secret.")

        # Encrypt credentials
        encrypted_api_key = encrypt_api_key(api_key)
        encrypted_api_secret = encrypt_api_key(api_secret)
        encrypted_passphrase = encrypt_api_key(passphrase) if passphrase else None

        # Create account record
        new_account = ExchangeAccount(
            user_id=user_id,
            exchange_name=exchange_id,
            label=label or f"{exchange.name} Account",
            api_key_encrypted=encrypted_api_key,
            api_secret_encrypted=encrypted_api_secret,
            passphrase_encrypted=encrypted_passphrase,
            is_active=True,
            sync_status="pending",
        )

        self.db.add(new_account)
        await self.db.commit()
        await self.db.refresh(new_account)

        return ConnectExchangeResponse(
            id=str(new_account.id),
            exchange_name=exchange_id,
            label=new_account.label,
            is_active=True,
            sync_status="pending",
            created_at=new_account.created_at,
        )

    async def trigger_sync(
        self,
        user_id: UUID,
        account_id: str,
    ) -> SyncResponse:
        """
        Manually trigger a sync for an exchange connection.

        Args:
            user_id: The user's UUID.
            account_id: The UUID string of the exchange account (connection) row.

        Returns:
            SyncResponse with success status.

        Raises:
            NotFoundError: If the exchange connection is not found.
        """
        parsed_id = _parse_uuid(account_id, "exchange account ID")

        result = await self.db.execute(
            select(ExchangeAccount).where(
                ExchangeAccount.user_id == user_id,
                ExchangeAccount.id == parsed_id,
                ExchangeAccount.is_active.is_(True),
            )
        )
        account = result.scalar_one_or_none()

        if not account:
            raise NotFoundError("Exchange connection")

        # Use PortfolioService to do real sync
        from app.services.portfolio_service import PortfolioService

        portfolio_service = PortfolioService(self.db)
        result = await portfolio_service.sync_account(
            user_id,
            account.id,
        )

        return SyncResponse(
            success=result.get("success", False),
            message=result.get("message", "Sync completed"),
        )

    async def get_exchange_status(
        self,
        user_id: UUID,
        account_id: str,
    ) -> ExchangeStatus:
        """
        Get the connection status of an exchange connection.

        Args:
            user_id: The user's UUID.
            account_id: The UUID string of the exchange account (connection) row.

        Returns:
            ExchangeStatus with connection details.

        Raises:
            NotFoundError: If the exchange connection is not found.
        """
        parsed_id = _parse_uuid(account_id, "exchange account ID")

        result = await self.db.execute(
            select(ExchangeAccount).where(
                ExchangeAccount.user_id == user_id,
                ExchangeAccount.id == parsed_id,
                ExchangeAccount.is_active.is_(True),
            )
        )
        account = result.scalar_one_or_none()

        if not account:
            raise NotFoundError("Exchange connection")

        # Query real balances count from holdings table
        count_result = await self.db.execute(
            select(func.count()).select_from(Holding).where(
                Holding.exchange_account_id == parsed_id
            )
        )
        balances_count = count_result.scalar() or 0

        return ExchangeStatus(
            id=str(account.id),
            exchange_name=account.exchange_name,
            is_active=account.is_active,
            sync_status=account.sync_status,
            last_sync_at=account.last_sync_at,
            balances_count=balances_count,
        )

    async def is_exchange_connected(self, user_id: UUID, exchange_id: str) -> bool:
        """
        Check if a user has an active connection to a specific exchange.
        
        Args:
            user_id: The user's UUID.
            exchange_id: The exchange identifier.
            
        Returns:
            True if connected, False otherwise.
        """
        result = await self.db.execute(
            select(ExchangeAccount).where(
                ExchangeAccount.user_id == user_id,
                ExchangeAccount.exchange_name == exchange_id,
                ExchangeAccount.is_active.is_(True),
            )
        )
        return result.scalar_one_or_none() is not None
