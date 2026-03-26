import enum
import uuid
from datetime import datetime

from sqlalchemy import Boolean, DateTime, Enum, ForeignKey, String
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base


class OTPPurpose(str, enum.Enum):
    email_verification = "email_verification"
    password_reset     = "password_reset"


class OTP(Base):
    __tablename__ = "otp_codes"

    id:         Mapped[str]          = mapped_column(String,  primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id:    Mapped[str]          = mapped_column(String,  ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    purpose:    Mapped[OTPPurpose]   = mapped_column(Enum(OTPPurpose, name="otp_purpose"), nullable=False)
    otp_hash:   Mapped[str]          = mapped_column(String,  nullable=False)
    expires_at: Mapped[datetime]     = mapped_column(DateTime(timezone=True), nullable=False)
    is_used:    Mapped[bool]         = mapped_column(Boolean, nullable=False, default=False)
    created_at: Mapped[datetime]     = mapped_column(DateTime(timezone=True), nullable=False)