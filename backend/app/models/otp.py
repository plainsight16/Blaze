from sqlalchemy import Boolean, Column, DateTime, Enum, ForeignKey, String
from app.database import Base

import enum


class OTPPurpose(str, enum.Enum):
    email_verification = "email_verification"
    password_reset     = "password_reset"


class OTP(Base):
    __tablename__ = "otp_codes"

    id         = Column(String,   primary_key=True)
    user_id    = Column(String,   ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    purpose    = Column(Enum(OTPPurpose, name="otp_purpose"), nullable=False)
    otp_hash   = Column(String,   nullable=False)
    expires_at = Column(DateTime(timezone=True), nullable=False)
    is_used    = Column(Boolean,  nullable=False, default=False)
    created_at = Column(DateTime(timezone=True), nullable=False)
