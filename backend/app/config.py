import os
from dotenv import load_dotenv

load_dotenv()

def _require(key: str) -> str:
    value = os.getenv(key)
    if not value:
        raise RuntimeError(f"Missing required environment variable: {key}")
    return value

DATABASE_URL: str = _require("DATABASE_URL")
SECRET_KEY: str   = _require("SECRET_KEY")

SMTP_HOST: str = _require("SMTP_HOST")
SMTP_PORT: int = int(os.getenv("SMTP_PORT", "587"))
SMTP_USER: str = _require("SMTP_USER")
SMTP_PASS: str = _require("SMTP_PASS")

ACCESS_TOKEN_EXPIRE_MINUTES: int  = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES",  "60"))
REFRESH_TOKEN_EXPIRE_DAYS: int    = int(os.getenv("REFRESH_TOKEN_EXPIRE_DAYS",    "30"))
OTP_EXPIRY_MINUTES: int           = int(os.getenv("OTP_EXPIRY_MINUTES",           "5"))
OTP_RATE_LIMIT_SECONDS: int       = int(os.getenv("OTP_RATE_LIMIT_SECONDS",       "60"))
