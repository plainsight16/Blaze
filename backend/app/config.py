"""
Centralised application settings.
All values are read from environment variables (or a .env file via python-dotenv).
Missing required vars raise at import time so the app fails fast on bad config.
"""
import os
from dotenv import load_dotenv

load_dotenv()


def _require(key: str) -> str:
    value = os.getenv(key, "").strip()
    if not value:
        raise RuntimeError(f"Missing required environment variable: {key}")
    return value


# ── Database ──────────────────────────────────────────────────────────────────
# Supabase connection-pooler URI (port 6543), e.g.:
#   postgresql://postgres.<ref>:<password>@aws-0-<region>.pooler.supabase.com:6543/postgres
DATABASE_URL: str = _require("DATABASE_URL")

# ── Security ──────────────────────────────────────────────────────────────────
SECRET_KEY: str = _require("SECRET_KEY")
BVN_SALT: str   = _require("BVN_SALT")

# ── Email / SMTP ──────────────────────────────────────────────────────────────
SMTP_HOST: str = _require("SMTP_HOST")
SMTP_PORT: int = int(os.getenv("SMTP_PORT", "587"))
SMTP_USER: str = _require("SMTP_USER")
SMTP_PASS: str = _require("SMTP_PASS")

# ── Token / OTP lifetimes ─────────────────────────────────────────────────────
ACCESS_TOKEN_EXPIRE_MINUTES: int = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "60"))
REFRESH_TOKEN_EXPIRE_DAYS: int   = int(os.getenv("REFRESH_TOKEN_EXPIRE_DAYS",   "30"))
OTP_EXPIRY_MINUTES: int          = int(os.getenv("OTP_EXPIRY_MINUTES",          "5"))
OTP_RATE_LIMIT_SECONDS: int      = int(os.getenv("OTP_RATE_LIMIT_SECONDS",      "60"))

# ── CORS ──────────────────────────────────────────────────────────────────────
# Comma-separated allowed origins, e.g. "https://app.example.com,http://localhost:3000"
_raw_origins: str          = os.getenv("ALLOWED_ORIGINS", "http://localhost:3000")
ALLOWED_ORIGINS: list[str] = [o.strip() for o in _raw_origins.split(",") if o.strip()]