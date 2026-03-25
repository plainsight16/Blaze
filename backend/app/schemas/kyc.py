from pydantic import BaseModel, Field
from typing import List


class KYCRequest(BaseModel):
    bvn: str = Field(..., min_length=11, max_length=11)


class MonthOnMonth(BaseModel):
    phone: str
    totalDebit: float
    debitCount: float
    totalCredit: float
    creditCount: float
    yearMonth: str
    averageBalance: float


class AverageValue(BaseModel):
    totalDebit: float
    debitCount: float
    totalCredit: float
    creditCount: float
    averageBalance: float


class BankStatement(BaseModel):
    monthOnMonth: List[MonthOnMonth]
    averageValue: AverageValue


class KYCResponseData(BaseModel):
    bvn: str
    firstName: str
    lastName: str
    phone: str
    bankStatement: BankStatement


class KYCResponse(BaseModel):
    responseCode: str
    responseMessage: str
    data: KYCResponseData