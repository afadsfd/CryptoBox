from pydantic_settings import BaseSettings
from pydantic import model_validator


class Settings(BaseSettings):
    # App
    APP_NAME: str = "CryptoBox API"
    DEBUG: bool = True
    API_V1_PREFIX: str = "/api/v1"
    
    # Database
    DATABASE_URL: str = "postgresql+asyncpg://postgres:postgres@localhost:5432/cryptofolio"
    
    # Redis
    REDIS_URL: str = "redis://localhost:6379/0"
    
    # JWT
    JWT_SECRET_KEY: str = ""
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7

    # OAuth (set in .env for production; optional in dev — verification skips audience if empty)
    GOOGLE_CLIENT_ID: str = ""
    APPLE_CLIENT_ID: str = ""
    
    # Encryption (for API keys)
    ENCRYPTION_KEY: str = ""
    
    # CORS
    ALLOWED_ORIGINS: str = "http://localhost:3000,http://localhost:8000"
    
    # CoinGecko
    COINGECKO_API_URL: str = "https://api.coingecko.com/api/v3"

    @model_validator(mode='after')
    def validate_secrets(self):
        if not self.JWT_SECRET_KEY:
            if self.DEBUG:
                self.JWT_SECRET_KEY = "dev-only-jwt-secret-do-not-use-in-production"
            else:
                raise ValueError("JWT_SECRET_KEY must be set via environment variable in production!")
        if not self.ENCRYPTION_KEY:
            if self.DEBUG:
                self.ENCRYPTION_KEY = "dev-only-encrypt-key-32bytes!!"  # dev-only key (HKDF derives actual key)
            else:
                raise ValueError("ENCRYPTION_KEY must be set via environment variable in production!")
        return self

    class Config:
        env_file = ".env"


settings = Settings()
