from datetime import datetime
from typing import Literal

from pydantic import BaseModel, Field


class KYCRequest(BaseModel):
    bvn: str = Field(..., min_length=11, max_length=11, pattern=r"^\d{11}$")


class KYCRequirementsResponse(BaseModel):
    bvn_required: bool
    bvn_verified: bool
    next_step: Literal["verify_bvn", "completed"]
    banner_title: str | None = None
    banner_message: str | None = None


class KYCStatusResponse(BaseModel):
    kyc_id: str | None
    status: str   # "not_started" | "verified"
    bvn_verified: bool
    next_step: Literal["verify_bvn", "completed"]


class KYCVerificationResponse(BaseModel):
    kyc_id: str
    status: str
    bvn_verified: bool = True
    next_step: Literal["completed"] = "completed"


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
