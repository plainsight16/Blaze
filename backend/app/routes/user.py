"""
User routes.

GET /user/me  — returns the authenticated user's profile, wallet, and KYC state.
"""
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.models.user import User
from app.schemas.user import UserProfileResponse
from app.services.user import get_user_profile
from app.utils.dependencies import get_current_user, get_db

router = APIRouter()


@router.get("/me", response_model=UserProfileResponse)
def get_me(
    db: Session = Depends(get_db),
    cur_user: User = Depends(get_current_user),
) -> UserProfileResponse:
    """
    Returns the authenticated user's:
    - core profile (name, email, username)
    - wallet details (account number, bank, status)
    - KYC status + next onboarding step
    """
    return get_user_profile(cur_user, db)