"""
FastAPI dependency functions.
get_db is defined in app.database to avoid a circular import; re-exported here
for convenience so routes can import from one place.
"""
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jose import JWTError
from sqlalchemy.orm import Session

from app.database import get_db  # re-export
from app.models.user import User
from app.utils.security import decode_access_token

_bearer = HTTPBearer()


def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(_bearer),
    db: Session = Depends(get_db),
) -> User:
    """
    Validates the Bearer JWT and returns the active, verified User.
    Raises 401 for bad/expired tokens or deactivated accounts.
    Raises 403 for unverified accounts.
    """
    try:
        user_id = decode_access_token(credentials.credentials)
    except JWTError:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Invalid or expired token.")

    user = db.query(User).filter(User.id == user_id).first()
    if not user or not user.is_active:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "User not found or deactivated.")
    if not user.verified_at:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Account not verified.")

    return user


__all__ = ["get_db", "get_current_user"]