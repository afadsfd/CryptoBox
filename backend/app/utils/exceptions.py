from typing import Any, Optional


class AppException(Exception):
    """Base application exception."""
    
    def __init__(
        self,
        status_code: int = 500,
        message: str = "Internal server error",
        error_code: Optional[str] = None,
        details: Optional[Any] = None
    ):
        self.status_code = status_code
        self.message = message
        self.error_code = error_code or "INTERNAL_ERROR"
        self.details = details
        super().__init__(self.message)


class AuthenticationError(AppException):
    """Raised when authentication fails."""
    
    def __init__(self, message: str = "Authentication failed", details: Optional[Any] = None):
        super().__init__(
            status_code=401,
            message=message,
            error_code="AUTHENTICATION_ERROR",
            details=details
        )


class NotFoundError(AppException):
    """Raised when a resource is not found."""
    
    def __init__(self, resource: str = "Resource", details: Optional[Any] = None):
        super().__init__(
            status_code=404,
            message=f"{resource} not found",
            error_code="NOT_FOUND",
            details=details
        )


class ValidationError(AppException):
    """Raised when validation fails."""
    
    def __init__(self, message: str = "Validation failed", details: Optional[Any] = None):
        super().__init__(
            status_code=422,
            message=message,
            error_code="VALIDATION_ERROR",
            details=details
        )


class ConflictError(AppException):
    """Raised when a resource conflicts with the current state (e.g. duplicate email)."""

    def __init__(self, message: str = "Conflict", details: Optional[Any] = None):
        super().__init__(
            status_code=409,
            message=message,
            error_code="CONFLICT",
            details=details,
        )


class ExchangeConnectionError(AppException):
    """Raised when exchange connection fails."""
    
    def __init__(self, exchange: str = "Exchange", details: Optional[Any] = None):
        super().__init__(
            status_code=502,
            message=f"Failed to connect to {exchange}",
            error_code="EXCHANGE_CONNECTION_ERROR",
            details=details
        )
