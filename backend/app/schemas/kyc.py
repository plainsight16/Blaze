from datetime import datetime
from typing import Any

from pydantic import BaseModel, Field


# ── KYC ───────────────────────────────────────────────────────────────────────

class KYCRequest(BaseModel):
    bvn: str = Field(..., min_length=11, max_length=11, pattern=r"^\d{11}$")


class KYCStatusResponse(BaseModel):
    kyc_id: str
    status: str   # "pending" | "verified" | "failed"


# ── Bank Statement ────────────────────────────────────────────────────────────

class MonthOnMonth(BaseModel):
    phone:          str
    totalDebit:     float
    debitCount:     float
    totalCredit:    float
    creditCount:    float
    yearMonth:      str
    averageBalance: float


class AverageValue(BaseModel):
    totalDebit:     float
    debitCount:     float
    totalCredit:    float
    creditCount:    float
    averageBalance: float


class BankStatementData(BaseModel):
    monthOnMonth: list[MonthOnMonth]
    averageValue: AverageValue


class BankStatementResponse(BaseModel):
    id:           str
    user_id:      str
    data:         BankStatementData
    generated_at: datetime
    updated_at:   datetime

    model_config = {"from_attributes": True}