"""
KYC API request and response schemas.
"""
from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field, field_validator
import re

# BVN Verification
class VerifyBVNRequest(BaseModel):
    """Request to verify BVN and provision wallet."""
    bvn: str = Field(
        ...,
        min_length=11,
        max_length=11,
        description="11-digit Bank Verification Number"
    )
    phone_number: str = Field(
        ...,
        description="Nigerian phone number (e.g., 08012345678 or +2348012345678)"
    )

    @field_validator("bvn")
    @classmethod
    def validate_bvn_format(cls, v):
        cleaned = v.strip().replace(" ", "").replace("-", "")
        if len(cleaned) != 11:
            raise ValueError("BVN must be exactly 11 digits")
        if not cleaned.isdigit():
            raise ValueError("BVN must contain only digits")
        return cleaned

    @field_validator("phone_number")
    @classmethod
    def validate_phone_format(cls, v):
        # Remove whitespace and common separators
        cleaned = re.sub(r"[\s\-\(\)]", "", v)

        # Remove leading +
        if cleaned.startswith("+"):
            cleaned = cleaned[1:]

        # Convert local format to international
        if cleaned.startswith("0") and len(cleaned) == 11:
            cleaned = "234" + cleaned[1:]

        # Validate Nigerian format
        if not cleaned.startswith("234"):
            raise ValueError("Must be a Nigerian phone number")

        if len(cleaned) != 13:
            raise ValueError("Invalid phone number length")

        if not cleaned.isdigit():
            raise ValueError("Phone number must contain only digits")

        return cleaned


class VerifyBVNResponse(BaseModel):
    """Response after successful BVN verification."""
    message: str
    bvn_verified: bool
    kyc_completed: bool
    wallet_provisioned: bool
    next_step: Optional[str] = None
    wallet_id: Optional[str] = None
    virtual_account: Optional[str] = None
    bank: Optional[str] = None

# KYC Status
class KYCStatusResponse(BaseModel):
    """Current KYC status for a user."""
    email_verified: bool
    bvn_verified: bool
    has_wallet: bool
    kyc_complete: bool
    kyc_completed_at: Optional[datetime] = None
    wallet_info: Optional[dict] = None


class KYCRequirementResponse(BaseModel):
    """What's needed to complete KYC."""
    email_verified: bool
    bvn_verified: bool
    has_wallet: bool
    next_step: Optional[str] = None
    message: str

    @classmethod
    def from_user(cls, user) -> "KYCRequirementResponse":
        """Build response from user model."""
        email_ok = user.verified_at is not None
        bvn_ok = user.bvn_verified
        wallet_ok = user.has_wallet

        if not email_ok:
            next_step = "verify_email"
            message = "Please verify your email address"
        elif not bvn_ok:
            next_step = "verify_bvn"
            message = "Please complete BVN verification"
        elif not wallet_ok:
            next_step = "retry_wallet_provisioning"
            message = "BVN verified. Wallet provisioning is pending"
        else:
            next_step = None
            message = "KYC complete! You're ready to join groups"

        return cls(
            email_verified=email_ok,
            bvn_verified=bvn_ok,
            has_wallet=wallet_ok,
            next_step=next_step,
            message=message,
        )
