"""
OTP lifecycle: rate-limit enforcement, creation, and consumption.
All functions are pure service logic — no HTTP concern leaks in except the
HTTPExceptions that constitute domain errors (wrong code, expired, etc.).
"""
import uuid
from datetime import datetime, timedelta, timezone

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.config import OTP_EXPIRY_MINUTES, OTP_RATE_LIMIT_SECONDS
from app.models.otp import OTP, OTPPurpose
from app.utils.security import generate_otp, verify_otp


def enforce_rate_limit(user_id: str, purpose: OTPPurpose, db: Session) -> None:
    """Raise 429 if a code was issued within OTP_RATE_LIMIT_SECONDS."""
    last = (
        db.query(OTP)
        .filter(OTP.user_id == user_id, OTP.purpose == purpose)
        .order_by(OTP.created_at.desc())
        .first()
    )
    if last:
        elapsed = (
            datetime.now(timezone.utc) - last.created_at.replace(tzinfo=timezone.utc)
        ).total_seconds()
        if elapsed < OTP_RATE_LIMIT_SECONDS:
            wait = int(OTP_RATE_LIMIT_SECONDS - elapsed)
            raise HTTPException(
                status.HTTP_429_TOO_MANY_REQUESTS,
                f"Too many requests. Try again in {wait}s.",
            )


def create_and_store_otp(user_id: str, purpose: OTPPurpose, db: Session) -> str:
    """
    Invalidate any live OTPs for this user+purpose, create a fresh one.
    Returns the raw (plaintext) code to be sent to the user.
    """
    # Invalidate all active codes for this purpose first
    db.query(OTP).filter(
        OTP.user_id == user_id,
        OTP.purpose == purpose,
        OTP.is_used == False,  # noqa: E712
    ).update({"is_used": True})

    raw, digest = generate_otp()
    record = OTP(
        id         = str(uuid.uuid4()),
        user_id    = user_id,
        purpose    = purpose,
        otp_hash   = digest,
        expires_at = datetime.now(timezone.utc) + timedelta(minutes=OTP_EXPIRY_MINUTES),
        is_used    = False,
        created_at = datetime.now(timezone.utc),
    )
    db.add(record)
    db.commit()
    return raw


def consume_otp(user_id: str, purpose: OTPPurpose, raw: str, db: Session) -> None:
    """
    Validate and mark the most recent active OTP as used.
    Raises HTTPException on any failure (no code, expired, wrong code).
    """
    record = (
        db.query(OTP)
        .filter(
            OTP.user_id == user_id,
            OTP.purpose == purpose,
            OTP.is_used == False,  # noqa: E712
        )
        .order_by(OTP.created_at.desc())
        .first()
    )
    if not record:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "No active code found.")
    if datetime.now(timezone.utc) > record.expires_at.replace(tzinfo=timezone.utc):
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Code has expired.")
    if not verify_otp(raw, record.otp_hash):
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Invalid code.")

    record.is_used = True
    db.commit()