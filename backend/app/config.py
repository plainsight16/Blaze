import os
from dotenv import load_dotenv

load_dotenv()


def _require(key: str) -> str:
    value = os.getenv(key)
    if not value:
        raise RuntimeError(f"Missing required environment variable: {key}")
    return value


def _require_in_production(key: str, default: str = "") -> str:
    """Require in production, allow default in development."""
    value = os.getenv(key, default)
    env = os.getenv("ENVIRONMENT", "development")
    if not value and env == "production":
        raise RuntimeError(f"Missing required environment variable: {key}")
    return value


# Database
DATABASE_URL: str = _require("DATABASE_URL")
SECRET_KEY: str = _require("SECRET_KEY")

# Email (SMTP)
SMTP_HOST: str = _require("SMTP_HOST")
SMTP_PORT: int = int(os.getenv("SMTP_PORT", "587"))
SMTP_USER: str = _require("SMTP_USER")
SMTP_PASS: str = _require("SMTP_PASS")

# Token Expiry
ACCESS_TOKEN_EXPIRE_MINUTES: int = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "60"))
REFRESH_TOKEN_EXPIRE_DAYS: int = int(os.getenv("REFRESH_TOKEN_EXPIRE_DAYS", "30"))
OTP_EXPIRY_MINUTES: int = int(os.getenv("OTP_EXPIRY_MINUTES", "5"))
OTP_RATE_LIMIT_SECONDS: int = int(os.getenv("OTP_RATE_LIMIT_SECONDS", "60"))

# Interswitch Configuration
ISW_CLIENT_ID: str = _require_in_production("ISW_CLIENT_ID")
ISW_CLIENT_SECRET: str = _require_in_production("ISW_CLIENT_SECRET")
ISW_MERCHANT_CODE: str = _require_in_production("ISW_MERCHANT_CODE")
ISW_QA_CLIENT_ID: str = _require_in_production("ISW_QA_CLIENT_ID")
ISW_QA_CLIENT_SECRET: str = _require_in_production("ISW_QA_CLIENT_SECRET")
ISW_QA_MERCHANT_CODE: str = _require_in_production("ISW_QA_MERCHANT_CODE", ISW_MERCHANT_CODE)
# API Base URLs (defaults to sandbox/QA)
ISW_PASSPORT_URL: str = os.getenv(
    "ISW_PASSPORT_URL",
    "https://passport-v2.k8.isw.la/passport"
)
ISW_IDENTITY_BASE_URL: str = os.getenv(
    "ISW_IDENTITY_BASE_URL",
    "https://api-marketplace-routing.k8.isw.la/marketplace-routing"
)
ISW_WALLET_BASE_URL: str = os.getenv(
    "ISW_WALLET_BASE_URL",
    "https://merchant-wallet.k8.isw.la/merchant-wallet"
)

ISW_QA_URL: str = os.getenv(
    "ISW_QA_URL",
    "https://qa.interswitchng.com/paymentgateway"
)

# Wallet Security
# 32-byte hex key for AES-256 encryption of wallet PINs
WALLET_PIN_ENCRYPTION_KEY: str = _require_in_production(
    "WALLET_PIN_ENCRYPTION_KEY",
    "0" * 64  # Development default (DO NOT USE IN PRODUCTION)
)

# Environment
ENVIRONMENT: str = os.getenv("ENVIRONMENT", "development")
