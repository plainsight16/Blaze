import hashlib
import hmac
import secrets
from datetime import datetime, timedelta, timezone

from jose import JWTError, jwt
from passlib.context import CryptContext

from app.config import ACCESS_TOKEN_EXPIRE_MINUTES, REFRESH_TOKEN_EXPIRE_DAYS, SECRET_KEY

_pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
ALGORITHM = "HS256"


# -- Passwords -------------------------------------------------

def hash_password(password: str) -> str:
    return _pwd_context.hash(password)


def verify_password(plain: str, hashed: str) -> bool:
    return _pwd_context.verify(plain, hashed)


# -- OTP tokens ------------------------------------------------

def generate_otp() -> tuple[str, str]:
    """Return (raw_6char_code, sha256_hex_digest). Store digest; send raw."""
    raw = secrets.token_hex(3)          # 6 hex chars, looks like a code
    digest = _sha256(raw)
    return raw, digest


def verify_otp(raw: str, stored_digest: str) -> bool:
    return hmac.compare_digest(_sha256(raw), stored_digest)


def _sha256(value: str) -> str:
    return hashlib.sha256(value.encode()).hexdigest()


# -- JWT access tokens -----------------------------------------

def create_access_token(user_id: str) -> str:
    expire = datetime.now(timezone.utc) + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    return jwt.encode({"sub": str(user_id), "exp": expire}, SECRET_KEY, algorithm=ALGORITHM)


def decode_access_token(token: str) -> str:
    """Return user_id or raise JWTError."""
    payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
    user_id: str = payload.get("sub")
    if not user_id:
        raise JWTError("Missing subject")
    return user_id


# -- Refresh tokens --------------------------------------------

def generate_refresh_token() -> tuple[str, str]:
    """Return (raw_token, sha256_hex_digest). Store digest; send raw."""
    raw = secrets.token_urlsafe(64)
    return raw, _sha256(raw)


def refresh_token_expiry() -> datetime:
    return datetime.now(timezone.utc) + timedelta(days=REFRESH_TOKEN_EXPIRE_DAYS)


import hashlib
import os


def hash_bvn(bvn: str) -> str:
    salt = os.getenv("BVN_SALT", "default_salt")  # use env in prod
    return hashlib.sha256(f"{bvn}{salt}".encode()).hexdigest()
