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
    """Single month row — stored in raw_data JSONB, never queried by column."""
    totalDebit:     float
    debitCount:     float
    totalCredit:    float
    creditCount:    float
    yearMonth:      str
    averageBalance: float


class BankStatementResponse(BaseModel):
    """
    Reflects the actual model columns.
    Aggregates are real typed fields; month rows come back from raw_data.
    """
    id:              str
    user_id:         str
    average_balance: float
    total_credit:    float
    total_debit:     float
    raw_data:        list[MonthOnMonth]
    generated_at:    datetime
    updated_at:      datetime

    model_config = {"from_attributes": True}