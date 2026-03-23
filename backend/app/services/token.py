import uuid
from datetime import datetime, timezone

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models.refresh_token import RefreshToken
from app.utils.security import _sha256, generate_refresh_token, refresh_token_expiry


def issue_refresh_token(user_id: str, db: Session) -> str:
    """Create a refresh token record and return the raw token."""
    raw, digest = generate_refresh_token()
    record = RefreshToken(
        id         = str(uuid.uuid4()),
        user_id    = user_id,
        token_hash = digest,
        expires_at = refresh_token_expiry(),
        revoked    = False,
        created_at = datetime.now(timezone.utc),
    )
    db.add(record)
    db.commit()
    return raw


def rotate_refresh_token(raw: str, db: Session) -> tuple[str, str]:
    """
    Validate raw refresh token, revoke it, issue a new one.
    Returns (new_raw_token, user_id).
    """
    digest = _sha256(raw)
    record = db.query(RefreshToken).filter(RefreshToken.token_hash == digest).first()

    if not record or record.revoked:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Invalid refresh token.")
    if datetime.now(timezone.utc) > record.expires_at.replace(tzinfo=timezone.utc):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Refresh token expired.")

    user_id = record.user_id
    record.revoked = True
    db.commit()

    new_raw = issue_refresh_token(user_id, db)
    return new_raw, user_id


def revoke_refresh_token(raw: str, db: Session) -> None:
    """Revoke a single refresh token (logout)."""
    digest = _sha256(raw)
    record = db.query(RefreshToken).filter(RefreshToken.token_hash == digest).first()
    if record and not record.revoked:
        record.revoked = True
        db.commit()


def revoke_all_refresh_tokens(user_id: str, db: Session) -> None:
    """Revoke all tokens for a user (logout all devices)."""
    db.query(RefreshToken).filter(
        RefreshToken.user_id == user_id,
        RefreshToken.revoked == False,  # noqa: E712
    ).update({"revoked": True})
    db.commit()
