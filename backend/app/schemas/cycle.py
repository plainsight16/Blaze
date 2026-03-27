from datetime import datetime
from pydantic import BaseModel, Field
from typing import Literal


CycleStatus = Literal["active", "completed", "cancelled"]
SlotStatus = Literal["pending", "paid", "defaulted"]
CycleFrequency = Literal["biweekly", "monthly"]


class StartCycleRequest(BaseModel):
    frequency: CycleFrequency
    max_reduction_pct: float = Field(default=25.0, ge=0.0, le=50.0)


class CycleSlotResponse(BaseModel):
    id: str
    cycle_id: str
    user_id: str
    position: int
    due_date: datetime
    reduction_pct: float
    insurance_amount: float
    payout_amount: float
    status: SlotStatus
    paid_at: datetime | None

    model_config = {"from_attributes": True}


class CycleResponse(BaseModel):
    id: str
    group_id: str
    status: CycleStatus
    frequency: CycleFrequency
    max_reduction_pct: float
    contribution_amount: float
    started_at: datetime
    completed_at: datetime | None
    slots: list[CycleSlotResponse]

    model_config = {"from_attributes": True}


class InsuranceWalletResponse(BaseModel):
    id: str
    cycle_id: str
    user_id: str
    balance: float
    status: str

    model_config = {"from_attributes": True}


class CycleContributionResponse(BaseModel):
    id: str
    slot_id: str
    contributor_id: str
    amount: float
    status: str
    collected_at: datetime

    model_config = {"from_attributes": True}