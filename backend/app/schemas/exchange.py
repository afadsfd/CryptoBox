"""
Exchange schemas for API request/response validation.
"""
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict, Field


class SupportedExchange(BaseModel):
    """Schema for supported exchange information."""
    
    id: str = Field(..., description="Exchange identifier (e.g., binance, okx)")
    name: str = Field(..., description="Display name of the exchange")
    description: str = Field(..., description="Brief description of the exchange")
    logo_color: str = Field(..., description="Brand color hex code")
    supports_spot: bool = Field(default=True, description="Whether spot trading is supported")
    supports_futures: bool = Field(default=False, description="Whether futures trading is supported")
    requires_passphrase: bool = Field(default=False, description="Whether a passphrase is required")
    is_featured: bool = Field(default=False, description="Whether this is a featured exchange")
    status: str = Field(default="available", description="Exchange status: available/coming_soon/maintenance")
    
    model_config = ConfigDict(from_attributes=True)


class ConnectedExchange(BaseModel):
    """Schema for user's connected exchange account."""
    
    id: str = Field(..., description="Unique account ID")
    exchange_name: str = Field(..., description="Exchange identifier")
    label: Optional[str] = Field(default=None, description="User-defined label for this connection")
    is_active: bool = Field(default=True, description="Whether the connection is active")
    last_sync_at: Optional[datetime] = Field(default=None, description="Last successful sync timestamp")
    sync_status: str = Field(default="pending", description="Sync status: pending/syncing/success/failed")
    
    model_config = ConfigDict(from_attributes=True)


class ExchangeConnectionRequest(BaseModel):
    """Schema for connecting a new exchange."""
    
    exchange_id: str = Field(..., description="Exchange identifier")
    label: Optional[str] = Field(default=None, description="Optional label for this connection")
    api_key: str = Field(..., description="API key from the exchange")
    api_secret: str = Field(..., description="API secret from the exchange")
    passphrase: Optional[str] = Field(default=None, description="Passphrase if required by the exchange")


class ExchangeConnectionResponse(BaseModel):
    """Schema for exchange connection response."""
    
    success: bool
    message: str
    account_id: Optional[str] = None
    exchange_name: Optional[str] = None
    label: Optional[str] = None


class ExchangesList(BaseModel):
    """Schema for list of supported exchanges."""
    
    exchanges: list[SupportedExchange]
    total: int


class ConnectedExchangesList(BaseModel):
    """Schema for list of connected exchanges."""
    
    connected: list[ConnectedExchange]
    total: int


class DisconnectExchangeResponse(BaseModel):
    """Schema for disconnect exchange response."""
    
    success: bool
    message: str


class ExchangeBalance(BaseModel):
    """Schema for exchange balance information."""
    
    asset: str = Field(..., description="Asset symbol (e.g., BTC, ETH)")
    free: float = Field(..., description="Available balance")
    locked: float = Field(..., description="Locked/used balance")
    total: float = Field(..., description="Total balance")
    usd_value: Optional[float] = Field(default=None, description="USD value of the balance")


class ExchangeBalanceResponse(BaseModel):
    """Schema for exchange balance response."""
    
    exchange_id: str
    exchange_name: str
    balances: list[ExchangeBalance]
    total_usd_value: float
    last_updated: datetime


class ExchangeSyncStatus(BaseModel):
    """Schema for exchange sync status."""
    
    account_id: str
    exchange_name: str
    status: str
    last_sync_at: Optional[datetime]
    next_sync_at: Optional[datetime]
    error_message: Optional[str] = None


class ConnectExchangeRequest(BaseModel):
    """Schema for connecting a new exchange (simplified)."""
    
    exchange_name: str = Field(..., description="Exchange identifier (e.g., binance, okx)")
    api_key: str = Field(..., description="API key from the exchange")
    api_secret: str = Field(..., description="API secret from the exchange")
    passphrase: Optional[str] = Field(default=None, description="Passphrase if required by the exchange")
    label: Optional[str] = Field(default=None, description="Optional label for this connection")


class ConnectExchangeResponse(BaseModel):
    """Schema for connect exchange response."""
    
    id: str = Field(..., description="Unique account ID")
    exchange_name: str = Field(..., description="Exchange identifier")
    label: Optional[str] = Field(default=None, description="User-defined label")
    is_active: bool = Field(default=True, description="Whether the connection is active")
    sync_status: str = Field(default="pending", description="Sync status")
    created_at: datetime = Field(..., description="Creation timestamp")


class SyncResponse(BaseModel):
    """Schema for sync trigger response."""
    
    success: bool
    message: str


class ExchangeStatus(BaseModel):
    """Schema for exchange connection status."""
    
    id: str = Field(..., description="Unique account ID")
    exchange_name: str = Field(..., description="Exchange identifier")
    is_active: bool = Field(..., description="Whether the connection is active")
    sync_status: str = Field(..., description="Current sync status")
    last_sync_at: Optional[datetime] = Field(default=None, description="Last successful sync timestamp")
    balances_count: int = Field(default=0, description="Number of balance entries synced")
