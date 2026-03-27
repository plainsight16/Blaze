from datetime import datetime

from pydantic import BaseModel

from app.schemas.kyc import KYCStatusResponse
from app.schemas.wallet import WalletResponse


class UserProfileResponse(BaseModel):
    """
    Consolidated profile returned by GET /user/me.

    wallet_balance  - account_number from the active wallet (display value).
                      None when the wallet is not yet provisioned.
    kyc             - full KYC + wallet-status snapshot (re-uses the existing
                      KYCStatusResponse so the frontend has next_step guidance).
    wallet          - full wallet record, or None if not provisioned yet.
    """

    id: str
    email: str
    username: str
    first_name: str
    last_name: str
    is_active: bool
    verified_at: datetime | None

    # Derived / joined fields
    wallet: WalletResponse | None
    kyc: KYCStatusResponse

    model_config = {"from_attributes": True}