import logging
from uuid import UUID

from fastapi import APIRouter, Depends, Path
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.dependencies import get_current_user
from app.models.user import User
from app.schemas.common import APIResponse
from app.schemas.exchange import (
    ConnectExchangeRequest,
    ConnectExchangeResponse,
    ConnectedExchangesList,
    DisconnectExchangeResponse,
    ExchangeStatus,
    ExchangesList,
    SyncResponse,
)
from app.services.exchange_adapters import get_exchange_adapter
from app.services.exchange_service import ExchangeService
from app.services.portfolio_service import PortfolioService
from app.utils.exceptions import ValidationError
from app.utils.security import decrypt_api_key

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/exchanges", tags=["Exchanges"])


@router.get("", response_model=APIResponse)
async def get_exchanges():
    """
    Get list of all supported exchanges.
    
    Returns:
        List of supported exchanges with their details.
    """
    exchanges = ExchangeService.get_supported_exchanges()
    return {
        "success": True,
        "data": {
            "exchanges": [exchange.model_dump() for exchange in exchanges],
            "total": len(exchanges)
        }
    }


@router.get("/supported", response_model=APIResponse)
async def get_supported_exchanges():
    """
    Get list of supported exchanges (alias for GET /exchanges).
    
    Returns:
        List of supported exchanges with their details.
    """
    exchanges = ExchangeService.get_supported_exchanges()
    return {
        "success": True,
        "data": {
            "exchanges": [exchange.model_dump() for exchange in exchanges],
            "total": len(exchanges)
        }
    }


@router.get("/connected", response_model=APIResponse)
async def get_connected_exchanges(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Get user's connected exchanges.
    
    Requires authentication.
    
    Returns:
        List of user's active exchange connections.
    """
    service = ExchangeService(db)
    connected = await service.get_connected_exchanges(current_user.id)
    
    return {
        "success": True,
        "data": {
            "connected": [conn.model_dump() for conn in connected],
            "total": len(connected)
        }
    }


@router.post("/connect", response_model=APIResponse)
async def connect_exchange(
    request: ConnectExchangeRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Connect a new exchange.
    
    Requires authentication.
    Validates API credentials, encrypts them, and creates a new exchange connection.
    
    Args:
        request: ConnectExchangeRequest containing exchange_name, api_key, api_secret, etc.
        
    Returns:
        ConnectExchangeResponse with the newly created connection details.
        
    Raises:
        ValidationError: If the exchange is not supported or credentials are invalid.
    """
    service = ExchangeService(db)
    
    result = await service.connect_exchange(
        user_id=current_user.id,
        exchange_id=request.exchange_name,
        label=request.label,
        api_key=request.api_key,
        api_secret=request.api_secret,
        passphrase=request.passphrase,
    )
    
    # 绑定成功后，异步反推7天历史走势
    try:
        from uuid import UUID as _UUID
        portfolio_service = PortfolioService(db)
        account_id = _UUID(result.id) if isinstance(result.id, str) else result.id
        await portfolio_service.backfill_history(current_user, account_id, days=7)
    except Exception as e:
        logger.warning("Failed to backfill history: %s", e)
        # 反推失败不影响绑定成功
    
    return {
        "success": True,
        "data": result.model_dump()
    }


@router.delete("/{exchange_id}", response_model=APIResponse)
async def disconnect_exchange(
    exchange_id: UUID = Path(..., description="The UUID of the exchange account"),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Disconnect an exchange (soft delete).

    Requires authentication.
    Sets the exchange connection's is_active flag to False.

    Args:
        exchange_id: The UUID of the exchange account to disconnect.

    Returns:
        Success message on successful disconnection.
    """
    service = ExchangeService(db)
    result = await service.disconnect_exchange(current_user.id, str(exchange_id))
    
    return {
        "success": result.success,
        "message": result.message
    }


@router.post("/{exchange_id}/sync", response_model=APIResponse)
async def trigger_sync(
    exchange_id: UUID = Path(..., description="The UUID of the exchange account"),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Manually trigger a sync for an exchange connection.

    Requires authentication.

    Args:
        exchange_id: The UUID of the exchange account to sync.

    Returns:
        SyncResponse with success status.
    """
    service = ExchangeService(db)
    result = await service.trigger_sync(current_user.id, str(exchange_id))
    
    return {
        "success": result.success,
        "message": result.message
    }


@router.get("/{exchange_id}/status", response_model=APIResponse)
async def get_exchange_status(
    exchange_id: UUID = Path(..., description="The UUID of the exchange account"),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Get the connection status of an exchange.

    Requires authentication.

    Args:
        exchange_id: The UUID of the exchange account.

    Returns:
        ExchangeStatus with connection details including sync status and balances count.
    """
    service = ExchangeService(db)
    result = await service.get_exchange_status(current_user.id, str(exchange_id))
    
    return {
        "success": True,
        "data": result.model_dump()
    }


@router.post("/{exchange_id}/verify", response_model=APIResponse)
async def verify_exchange_connection(
    exchange_id: UUID = Path(..., description="The UUID of the exchange account"),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Verify that an existing exchange connection's API credentials are still valid.
    """
    from sqlalchemy import select, and_
    from app.models.exchange_account import ExchangeAccount

    result = await db.execute(
        select(ExchangeAccount).where(
            and_(
                ExchangeAccount.id == exchange_id,
                ExchangeAccount.user_id == current_user.id,
                ExchangeAccount.is_active.is_(True),
            )
        )
    )
    account = result.scalar_one_or_none()
    if not account:
        return {"success": False, "message": "Exchange connection not found"}

    try:
        api_key = decrypt_api_key(account.api_key_encrypted)
        api_secret = decrypt_api_key(account.api_secret_encrypted)
        passphrase = (
            decrypt_api_key(account.passphrase_encrypted)
            if account.passphrase_encrypted
            else None
        )
        adapter = get_exchange_adapter(account.exchange_name)
        is_valid = await adapter.verify_connection(api_key, api_secret, passphrase)

        return {
            "success": True,
            "data": {
                "verified": is_valid,
                "exchange_name": account.exchange_name,
            },
        }
    except Exception as e:
        logger.error("Verify connection failed for %s: %s", exchange_id, e)
        return {"success": False, "message": "Failed to verify exchange connection"}


@router.get("/{exchange_id}/balance", response_model=APIResponse)
async def get_exchange_balance(
    exchange_id: UUID = Path(..., description="The UUID of the exchange account"),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Get real-time balance from a specific exchange account.
    """
    from sqlalchemy import select, and_
    from app.models.exchange_account import ExchangeAccount

    result = await db.execute(
        select(ExchangeAccount).where(
            and_(
                ExchangeAccount.id == exchange_id,
                ExchangeAccount.user_id == current_user.id,
                ExchangeAccount.is_active.is_(True),
            )
        )
    )
    account = result.scalar_one_or_none()
    if not account:
        return {"success": False, "message": "Exchange connection not found"}

    try:
        portfolio_service = PortfolioService(db)
        balances = await portfolio_service.get_account_balance(account)

        from app.services.price_service import PriceService
        price_service = PriceService()
        symbols = [b["symbol"] for b in balances]
        prices = await price_service.get_prices(symbols) if symbols else {}

        balance_items = []
        total_usd = 0.0
        for b in balances:
            price = prices.get(b["symbol"], 0.0)
            usd_value = (b["free"] + b["locked"]) * price
            total_usd += usd_value
            balance_items.append({
                "asset": b["symbol"],
                "free": b["free"],
                "locked": b["locked"],
                "total": b["free"] + b["locked"],
                "usd_value": round(usd_value, 2),
            })

        return {
            "success": True,
            "data": {
                "exchange_id": str(account.id),
                "exchange_name": account.exchange_name,
                "balances": balance_items,
                "total_usd_value": round(total_usd, 2),
            },
        }
    except Exception as e:
        logger.error("Get balance failed for %s: %s", exchange_id, e)
        return {"success": False, "message": "Failed to retrieve balance"}
