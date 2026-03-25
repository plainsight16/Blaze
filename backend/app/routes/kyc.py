"""
KYC API Routes.

Endpoints for BVN verification and KYC status.
"""
import logging

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.models.user import User
from app.utils.dependencies import get_db, get_current_user
from app.services import kyc_service
from app.services.kyc_service import (
    KYCError,
    BVNValidationError,
    PhoneValidationError,
)
from app.schemas.kyc import (
    VerifyBVNRequest,
    VerifyBVNResponse,
    KYCStatusResponse,
    KYCRequirementResponse,
)


logger = logging.getLogger(__name__)
router = APIRouter(prefix="/kyc", tags=["KYC"])


# =============================================================================
# KYC Status
# =============================================================================

@router.get("/status", response_model=KYCStatusResponse)
async def get_kyc_status(
    current_user: User = Depends(get_current_user),
):
    """
    Get current KYC status.

    Returns verification status for email, BVN, and wallet.
    """
    status_data = kyc_service.get_kyc_status(current_user)
    return KYCStatusResponse(**status_data)


@router.get("/requirements", response_model=KYCRequirementResponse)
async def get_kyc_requirements(
    current_user: User = Depends(get_current_user),
):
    """
    Get remaining KYC requirements.

    Tells the user what steps they need to complete.
    """
    return KYCRequirementResponse.from_user(current_user)


# =============================================================================
# BVN Verification
# =============================================================================

@router.post("/verify-bvn", response_model=VerifyBVNResponse)
async def verify_bvn(
    request: VerifyBVNRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Verify BVN and provision wallet.

    This is the main KYC endpoint. Upon successful verification:
    1. BVN is validated and hashed (never stored in plain text)
    2. The user's name is verified against Interswitch
    3. An Interswitch wallet is provisioned
    4. A virtual bank account is created for deposits

    Prerequisites:
    - Email must be verified

    After completion:
    - User can join groups
    - User can make and receive transfers

    If the BVN verification succeeds but wallet provisioning fails, the
    response still returns success with next_step=retry_wallet_provisioning.
    """
    # Check email is verified
    if not current_user.verified_at:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Please verify your email before completing KYC",
        )

    try:
        result = await kyc_service.verify_bvn_and_provision_wallet(
            db=db,
            user=current_user,
            bvn=request.bvn,
            phone_number=request.phone_number,
        )

        return VerifyBVNResponse(
            message=result.message,
            bvn_verified=result.bvn_verified,
            kyc_completed=result.bvn_verified and result.wallet_provisioned,
            wallet_provisioned=result.wallet_provisioned,
            next_step=result.next_step,
            wallet_id=result.user.isw_wallet_id,
            virtual_account=result.user.isw_virtual_acct_no,
            bank=result.user.isw_virtual_acct_bank,
        )

    except BVNValidationError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid BVN: {e}",
        )

    except PhoneValidationError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid phone number: {e}",
        )

    except KYCError as e:
        logger.error(f"KYC verification failed for user {current_user.id}: {e}")
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=str(e),
        )
