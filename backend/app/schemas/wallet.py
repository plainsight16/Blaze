from datetime import datetime
from typing import Literal

from pydantic import BaseModel


WalletStatus = Literal["not_started", "pending", "active", "failed"]
OnboardingNextStep = Literal[
    "verify_bvn",
    "provision_wallet",
    "retry_wallet_provisioning",
    "completed",
]


class WalletResponse(BaseModel):
    id: str
    user_id: str
    provider: str
    provider_wallet_id: str | None
    provider_reference: str | None
    account_name: str
    account_number: str | None
    bank_name: str | None
    bank_code: str | None
    status: WalletStatus
    failure_reason: str | None
    provisioned_at: datetime | None
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}
