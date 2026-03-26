"""
All cryptographic primitives live here.
Nothing in this module imports from app.models or app.services — it is a pure
utility layer with no side effects beyond computation.
"""
import hashlib
import hmac
import secrets
from datetime import datetime, timedelta, timezone

from jose import JWTError, jwt
from passlib.context import CryptContext

from app.config import (
    ACCESS_TOKEN_EXPIRE_MINUTES,
    BVN_SALT,
    REFRESH_TOKEN_EXPIRE_DAYS,
    SECRET_KEY,
)

_pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
_ALGORITHM   = "HS256"


# ── Passwords ─────────────────────────────────────────────────────────────────

def hash_password(password: str) -> str:
    return _pwd_context.hash(password)


def verify_password(plain: str, hashed: str) -> bool:
    return _pwd_context.verify(plain, hashed)


# ── OTP ───────────────────────────────────────────────────────────────────────

def generate_otp() -> tuple[str, str]:
    """Return (raw_6_hex_chars, sha256_digest).  Store digest; send raw."""
    raw    = secrets.token_hex(3)   # e.g. "a3f91c"
    digest = _sha256(raw)
    return raw, digest


def verify_otp(raw: str, stored_digest: str) -> bool:
    return hmac.compare_digest(_sha256(raw), stored_digest)


# ── JWT access tokens ─────────────────────────────────────────────────────────

def create_access_token(user_id: str) -> str:
    expire = datetime.now(timezone.utc) + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    return jwt.encode({"sub": user_id, "exp": expire}, SECRET_KEY, algorithm=_ALGORITHM)


def decode_access_token(token: str) -> str:
    """Return user_id string, or raise JWTError."""
    payload = jwt.decode(token, SECRET_KEY, algorithms=[_ALGORITHM])
    user_id: str | None = payload.get("sub")
    if not user_id:
        raise JWTError("Missing subject claim.")
    return user_id


# ── Refresh tokens ────────────────────────────────────────────────────────────

def generate_refresh_token() -> tuple[str, str]:
    """Return (raw_url_safe_token, sha256_digest).  Store digest; send raw."""
    raw = secrets.token_urlsafe(64)
    return raw, _sha256(raw)


def refresh_token_expiry() -> datetime:
    return datetime.now(timezone.utc) + timedelta(days=REFRESH_TOKEN_EXPIRE_DAYS)


# ── BVN ───────────────────────────────────────────────────────────────────────

def hash_bvn(bvn: str) -> str:
    """HMAC-SHA256 with a server-side salt so raw BVNs are never stored."""
    return hmac.new(BVN_SALT.encode(), bvn.encode(), hashlib.sha256).hexdigest()


# ── Internal helpers ──────────────────────────────────────────────────────────

def _sha256(value: str) -> str:
    return hashlib.sha256(value.encode()).hexdigest()