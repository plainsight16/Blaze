"""
Refresh-token lifecycle: issue, rotate, revoke.
Access token creation lives in app.utils.security (pure crypto, no DB).
"""
import uuid
from datetime import datetime, timezone

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models.refresh_token import RefreshToken
from app.utils.security import _sha256, generate_refresh_token, refresh_token_expiry


def issue_refresh_token(user_id: str, db: Session) -> str:
    """Persist a new refresh token record; return the raw token for the client."""
    raw, digest = generate_refresh_token()
    db.add(RefreshToken(
        id         = str(uuid.uuid4()),
        user_id    = user_id,
        token_hash = digest,
        expires_at = refresh_token_expiry(),
        revoked    = False,
        created_at = datetime.now(timezone.utc),
    ))
    db.commit()
    return raw


def rotate_refresh_token(raw: str, db: Session) -> tuple[str, str]:
    """
    Validate the incoming raw token, revoke it, and issue a fresh one.
    Returns (new_raw_token, user_id).
    """
    digest = _sha256(raw)
    record = db.query(RefreshToken).filter(RefreshToken.token_hash == digest).first()

    if not record or record.revoked:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Invalid refresh token.")
    if datetime.now(timezone.utc) > record.expires_at.replace(tzinfo=timezone.utc):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Refresh token expired.")

    user_id        = record.user_id
    record.revoked = True
    db.commit()

    return issue_refresh_token(user_id, db), user_id


def revoke_refresh_token(raw: str, db: Session) -> None:
    """Revoke a single token (single-device logout)."""
    digest = _sha256(raw)
    record = db.query(RefreshToken).filter(RefreshToken.token_hash == digest).first()
    if record and not record.revoked:
        record.revoked = True
        db.commit()


def revoke_all_refresh_tokens(user_id: str, db: Session) -> None:
    """Revoke every active token for a user (all-device logout / password reset)."""
    db.query(RefreshToken).filter(
        RefreshToken.user_id == user_id,
        RefreshToken.revoked == False,  # noqa: E712
    ).update({"revoked": True})
    db.commit()