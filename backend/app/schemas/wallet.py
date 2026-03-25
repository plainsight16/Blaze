"""
Wallet API request and response schemas.
"""
from datetime import datetime
from decimal import Decimal
from typing import Optional
from pydantic import BaseModel, Field, field_validator


# =============================================================================
# Balance
# =============================================================================

class WalletBalanceResponse(BaseModel):
    """Wallet balance response from ISW."""
    available_balance: float = Field(..., description="Available balance in Naira")
    ledger_balance: float = Field(..., description="Ledger balance in Naira")
    currency: str = Field(default="NGN")
    virtual_account: Optional[str] = Field(None, description="Virtual account number")
    bank: Optional[str] = Field(None, description="Bank name")


class WalletInfoResponse(BaseModel):
    """User wallet information."""
    has_wallet: bool
    wallet_id: Optional[str] = None
    virtual_account_number: Optional[str] = None
    virtual_account_bank: Optional[str] = None


# =============================================================================
# Transfers
# =============================================================================

class TransferToGroupRequest(BaseModel):
    """Request to transfer from user wallet to group wallet."""
    group_id: str = Field(..., description="Target group ID")
    amount: Decimal = Field(..., gt=0, description="Amount in Naira")
    pin: str = Field(..., min_length=4, max_length=4, description="4-digit wallet PIN")
    narration: Optional[str] = Field(None, max_length=255, description="Transaction description")

    @field_validator("amount")
    @classmethod
    def validate_amount(cls, v):
        if v < 100:
            raise ValueError("Minimum transfer amount is ₦100")
        if v > 1_000_000:
            raise ValueError("Maximum transfer amount is ₦1,000,000")
        return v

    @field_validator("pin")
    @classmethod
    def validate_pin(cls, v):
        if not v.isdigit():
            raise ValueError("PIN must be 4 digits")
        return v


class TransferResponse(BaseModel):
    """Response after successful transfer."""
    status: str
    debit_reference: str
    credit_reference: str
    amount: float
    message: Optional[str] = None


# =============================================================================
# Transaction History
# =============================================================================

class TransactionResponse(BaseModel):
    """Single transaction record."""
    id: str
    transaction_type: str  # debit | credit | reversal
    amount: float
    currency: str
    status: str  # pending | completed | failed | reversed
    counterparty_type: Optional[str] = None
    counterparty_id: Optional[str] = None
    description: Optional[str] = None
    narration: Optional[str] = None
    transaction_ref: Optional[str] = None
    created_at: datetime

    model_config = {"from_attributes": True}


class TransactionListResponse(BaseModel):
    """Paginated list of transactions."""
    transactions: list[TransactionResponse]
    total: int
    limit: int
    offset: int


# =============================================================================
# Group Wallet
# =============================================================================

class GroupWalletInfoResponse(BaseModel):
    """Group wallet information (admin view)."""
    group_id: str
    group_name: str
    has_wallet: bool
    virtual_account_number: Optional[str] = None
    virtual_account_bank: Optional[str] = None
    balance: Optional[WalletBalanceResponse] = None
