"""
User service.

Thin aggregation layer: fetches the user's wallet and KYC state, then
assembles the UserProfileResponse.  No business-rule enforcement lives here
— that belongs in kyc.py / wallet.py.
"""
from __future__ import annotations

from sqlalchemy.orm import Session

from app.models.user import User
from app.schemas.kyc import KYCStatusResponse
from app.schemas.user import UserProfileResponse
from app.schemas.wallet import WalletResponse
from app.services.kyc import get_kyc_status
from app.services.wallet import get_wallet_by_user_id


def get_user_profile(user: User, db: Session) -> UserProfileResponse:
    """
    Return a consolidated profile for *user* including:
      - core user fields
      - wallet details (None if not yet provisioned)
      - KYC / onboarding status
    """
    wallet_orm = get_wallet_by_user_id(user.id, db)
    wallet_out = WalletResponse.model_validate(wallet_orm) if wallet_orm else None

    kyc_status: KYCStatusResponse = get_kyc_status(user.id, db)

    return UserProfileResponse(
        id=user.id,
        email=user.email,
        username=user.username,
        first_name=user.first_name,
        last_name=user.last_name,
        is_active=user.is_active,
        verified_at=user.verified_at,
        wallet=wallet_out,
        kyc=kyc_status,
    )