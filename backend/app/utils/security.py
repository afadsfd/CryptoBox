import base64
import hashlib
import hmac
import os
import secrets
from datetime import datetime, timedelta, timezone
from typing import Optional

from cryptography.hazmat.primitives.ciphers.aead import AESGCM
from cryptography.hazmat.primitives.kdf.hkdf import HKDF
from cryptography.hazmat.primitives import hashes
from jose import JWTError, jwt
from passlib.context import CryptContext

from app.config import settings

# Password hashing context
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


def hash_password(password: str) -> str:
    """Hash a password using bcrypt."""
    return pwd_context.hash(password)


def verify_password(plain: str, hashed: str) -> bool:
    """Verify a password against its hash."""
    return pwd_context.verify(plain, hashed)


def hash_refresh_token(token: str) -> str:
    """
    Derive a stored fingerprint for a refresh JWT (or any string) using HMAC-SHA256.
    Avoids bcrypt's 72-byte input limit on long JWTs.
    """
    digest = hmac.new(
        settings.JWT_SECRET_KEY.encode("utf-8"),
        token.encode("utf-8"),
        hashlib.sha256,
    ).hexdigest()
    return digest


def verify_refresh_token_hmac(token: str, stored: str) -> bool:
    """Constant-time compare of refresh token to stored HMAC hex."""
    if not stored:
        return False
    expected = hash_refresh_token(token)
    return secrets.compare_digest(expected, stored)


def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    """Create a JWT access token."""
    to_encode = data.copy()
    
    if expires_delta:
        expire = datetime.now(timezone.utc) + expires_delta
    else:
        expire = datetime.now(timezone.utc) + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    
    to_encode.update({"exp": expire, "type": "access"})
    encoded_jwt = jwt.encode(to_encode, settings.JWT_SECRET_KEY, algorithm=settings.JWT_ALGORITHM)
    return encoded_jwt


def create_refresh_token(data: dict) -> str:
    """Create a JWT refresh token."""
    to_encode = data.copy()
    expire = datetime.now(timezone.utc) + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)
    
    to_encode.update({"exp": expire, "type": "refresh"})
    encoded_jwt = jwt.encode(to_encode, settings.JWT_SECRET_KEY, algorithm=settings.JWT_ALGORITHM)
    return encoded_jwt


def verify_token(token: str) -> Optional[dict]:
    """Verify and decode a JWT token."""
    try:
        payload = jwt.decode(token, settings.JWT_SECRET_KEY, algorithms=[settings.JWT_ALGORITHM])
        return payload
    except JWTError:
        return None


def _derive_key(key_material: bytes) -> bytes:
    """使用 HKDF 从任意长度密钥材料派生 32 字节密钥"""
    hkdf = HKDF(
        algorithm=hashes.SHA256(),
        length=32,
        salt=None,
        info=b"cryptofolio-api-key-encryption",
    )
    return hkdf.derive(key_material)


# 模块级缓存，避免每次加解密都重新派生
_cached_encryption_key: Optional[bytes] = None


def _get_encryption_key() -> bytes:
    """Get or derive encryption key from settings (cached)."""
    global _cached_encryption_key
    if _cached_encryption_key is None:
        key = settings.ENCRYPTION_KEY.encode('utf-8')
        _cached_encryption_key = _derive_key(key)
    return _cached_encryption_key


def encrypt_api_key(key: str) -> str:
    """Encrypt an API key using AES-256-GCM."""
    aesgcm = AESGCM(_get_encryption_key())
    nonce = os.urandom(12)  # 96-bit nonce for GCM
    plaintext = key.encode('utf-8')
    ciphertext = aesgcm.encrypt(nonce, plaintext, None)
    # Combine nonce and ciphertext, then base64 encode
    encrypted = base64.b64encode(nonce + ciphertext).decode('utf-8')
    return encrypted


def decrypt_api_key(encrypted: str) -> str:
    """Decrypt an API key using AES-256-GCM."""
    aesgcm = AESGCM(_get_encryption_key())
    data = base64.b64decode(encrypted.encode('utf-8'))
    nonce = data[:12]
    ciphertext = data[12:]
    plaintext = aesgcm.decrypt(nonce, ciphertext, None)
    return plaintext.decode('utf-8')
