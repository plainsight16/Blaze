from datetime import datetime

from pydantic import BaseModel, Field

from app.schemas.wallet import OnboardingNextStep, WalletStatus


class KYCRequest(BaseModel):
    bvn: str = Field(..., min_length=11, max_length=11, pattern=r"^\d{11}$")


class KYCRequirementsResponse(BaseModel):
    bvn_required: bool
    bvn_verified: bool
    wallet_required: bool
    wallet_provisioned: bool
    wallet_status: WalletStatus
    next_step: OnboardingNextStep
    banner_title: str | None = None
    banner_message: str | None = None


class KYCStatusResponse(BaseModel):
    kyc_id: str | None
    wallet_id: str | None
    status: str
    bvn_verified: bool
    wallet_provisioned: bool
    wallet_status: WalletStatus
    next_step: OnboardingNextStep


class KYCVerificationResponse(BaseModel):
    kyc_id: str
    wallet_id: str | None
    status: str
    bvn_verified: bool = True
    wallet_provisioned: bool
    wallet_status: WalletStatus
    next_step: OnboardingNextStep


class MonthOnMonth(BaseModel):
    """Single month row stored in raw_data and returned read-only."""

    totalDebit: float
    debitCount: float
    totalCredit: float
    creditCount: float
    yearMonth: str
    averageBalance: float


class BankStatementResponse(BaseModel):
    id: str
    user_id: str
    average_balance: float
    total_credit: float
    total_debit: float
    raw_data: list[MonthOnMonth]
    generated_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}
