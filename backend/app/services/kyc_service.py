"""
KYC Service - Identity verification and wallet provisioning.

Handles BVN verification flow and triggers wallet creation
upon successful KYC completion.
"""
import hashlib
import logging
import re
from dataclasses import dataclass
from datetime import datetime, timezone
from typing import Optional

from sqlalchemy.orm import Session

from app.models.user import User
from app.services import interswitch as isw
from app.services import wallet_service


logger = logging.getLogger(__name__)


# =============================================================================
# Exceptions
# =============================================================================

class KYCError(Exception):
    """Base exception for KYC operations."""
    pass


class BVNValidationError(KYCError):
    """BVN format or verification failed."""
    pass


class PhoneValidationError(KYCError):
    """Phone number format invalid."""
    pass


@dataclass
class KYCVerificationResult:
    """Outcome of the BVN verification + wallet provisioning flow."""
    user: User
    bvn_verified: bool
    wallet_provisioned: bool
    next_step: Optional[str]
    message: str


# =============================================================================
# Validation
# =============================================================================

def validate_bvn(bvn: str) -> str:
    """
    Validate BVN format.

    BVN (Bank Verification Number) is an 11-digit number issued by
    the Central Bank of Nigeria.

    Args:
        bvn: BVN string to validate

    Returns:
        Cleaned BVN string

    Raises:
        BVNValidationError: If format is invalid
    """
    # Remove any whitespace
    cleaned = bvn.strip().replace(" ", "").replace("-", "")

    if len(cleaned) != 11:
        raise BVNValidationError("BVN must be exactly 11 digits")

    if not cleaned.isdigit():
        raise BVNValidationError("BVN must contain only digits")

    return cleaned


def validate_nigerian_phone(phone: str) -> str:
    """
    Validate and normalize Nigerian phone number.

    Accepts formats:
    - 08012345678
    - +2348012345678
    - 2348012345678

    Args:
        phone: Phone number string

    Returns:
        Normalized phone in format: 2348012345678

    Raises:
        PhoneValidationError: If format is invalid
    """
    # Remove whitespace, dashes, parentheses
    cleaned = re.sub(r"[\s\-\(\)]", "", phone)

    # Remove leading + if present
    if cleaned.startswith("+"):
        cleaned = cleaned[1:]

    # Handle 0-prefixed numbers (local format)
    if cleaned.startswith("0") and len(cleaned) == 11:
        cleaned = "234" + cleaned[1:]

    # Validate final format
    if not cleaned.startswith("234"):
        raise PhoneValidationError("Phone number must be a Nigerian number")

    if len(cleaned) != 13:
        raise PhoneValidationError("Invalid phone number length")

    if not cleaned.isdigit():
        raise PhoneValidationError("Phone number must contain only digits")

    # Validate mobile prefix (after 234)
    mobile_prefix = cleaned[3:6]
    valid_prefixes = [
        "701", "702", "703", "704", "705", "706", "707", "708", "709",
        "801", "802", "803", "804", "805", "806", "807", "808", "809",
        "810", "811", "812", "813", "814", "815", "816", "817", "818", "819",
        "901", "902", "903", "904", "905", "906", "907", "908", "909",
        "911", "912", "913", "914", "915", "916",
    ]
    if mobile_prefix not in valid_prefixes:
        raise PhoneValidationError("Invalid Nigerian mobile number prefix")

    return cleaned


def hash_bvn(bvn: str) -> str:
    """
    Create SHA-256 hash of BVN for storage.

    We never store raw BVN - only the hash for verification.

    Args:
        bvn: Raw BVN string

    Returns:
        SHA-256 hex digest
    """
    return hashlib.sha256(bvn.encode()).hexdigest()


# =============================================================================
# KYC Verification
# =============================================================================

async def verify_bvn_and_provision_wallet(
    db: Session,
    user: User,
    bvn: str,
    phone_number: str,
) -> KYCVerificationResult:
    """
    Verify user's BVN and provision their wallet.

    This is the main KYC flow:
    1. Validate BVN format
    2. Validate phone number format
    3. Verify the user's name and BVN against Interswitch
    4. Store BVN hash (never raw BVN)
    5. Persist the user's normalized phone number
    6. Provision Interswitch wallet

    Args:
        db: Database session
        user: User to verify
        bvn: Bank Verification Number
        phone_number: Nigerian phone number

    Returns:
        KYCVerificationResult describing the completed state

    Raises:
        BVNValidationError: If BVN format invalid
        PhoneValidationError: If phone format invalid
        KYCError: If verification fails
    """
    # Validate inputs
    validated_bvn = validate_bvn(bvn)
    validated_phone = validate_nigerian_phone(phone_number)
    provided_bvn_hash = hash_bvn(validated_bvn)
    already_verified = user.bvn_verified
    already_has_wallet = user.has_wallet

    logger.info(f"Starting KYC verification for user: {user.id}")

    if user.bvn_verified and user.bvn_hash and user.bvn_hash != provided_bvn_hash:
        raise BVNValidationError(
            "This account has already been verified with a different BVN"
        )

    try:
        if not user.bvn_verified:
            verification = await isw.verify_bvn_boolean_match(
                first_name=user.first_name,
                last_name=user.last_name,
                bvn=validated_bvn,
            )
            if not verification.matched:
                raise BVNValidationError(
                    verification.response_message or
                    "Provided BVN does not match your registered name"
                )

            user.bvn_hash = provided_bvn_hash
            user.bvn_verified = True
            logger.info(f"BVN verified successfully for user: {user.id}")
        elif not user.bvn_hash:
            # Heal incomplete legacy records so retries remain consistent.
            user.bvn_hash = provided_bvn_hash

        # Persist the user's normalized phone number even if wallet creation fails.
        user.phone_number = validated_phone
        db.commit()
        db.refresh(user)

    except BVNValidationError:
        db.rollback()
        raise

    except isw.InterswitchAuthError as e:
        logger.error(f"BVN verification auth failed for user {user.id}: {e}")
        db.rollback()
        raise KYCError(f"BVN verification authentication failed: {e.message}")

    except isw.InterswitchVerificationError as e:
        logger.error(f"BVN verification failed for user {user.id}: {e}")
        db.rollback()
        raise KYCError(f"BVN verification failed: {e.message}")

    except isw.InterswitchError as e:
        logger.error(f"Interswitch error during KYC for user {user.id}: {e}")
        db.rollback()
        raise KYCError(f"BVN verification failed: {e.message}")

    except Exception as e:
        logger.error(f"KYC failed for user {user.id}: {e}")
        db.rollback()
        raise KYCError(f"KYC verification failed: {e}")

    if user.has_wallet:
        if not user.kyc_completed_at:
            user.kyc_completed_at = datetime.now(timezone.utc)
            db.commit()
            db.refresh(user)

        message = (
            "KYC already complete"
            if already_verified and already_has_wallet else
            "BVN already verified and wallet is available"
        )
        return KYCVerificationResult(
            user=user,
            bvn_verified=True,
            wallet_provisioned=True,
            next_step=None,
            message=message,
        )

    try:
        user = await wallet_service.provision_user_wallet(
            db=db,
            user=user,
            phone_number=validated_phone,
        )

        user.kyc_completed_at = datetime.now(timezone.utc)
        db.commit()
        db.refresh(user)

        logger.info(f"KYC completed for user {user.id}, wallet: {user.isw_wallet_id}")
        return KYCVerificationResult(
            user=user,
            bvn_verified=True,
            wallet_provisioned=True,
            next_step=None,
            message=(
                "BVN verified and wallet provisioned successfully"
                if not already_verified else
                "Wallet provisioned successfully"
            ),
        )

    except wallet_service.WalletAlreadyExistsError:
        db.refresh(user)
        if not user.kyc_completed_at:
            user.kyc_completed_at = datetime.now(timezone.utc)
            db.commit()
            db.refresh(user)

        return KYCVerificationResult(
            user=user,
            bvn_verified=True,
            wallet_provisioned=True,
            next_step=None,
            message="KYC already complete",
        )

    except wallet_service.WalletError as e:
        logger.error(f"Wallet provisioning failed after BVN verification for user {user.id}: {e}")
        db.rollback()
        db.refresh(user)
        return KYCVerificationResult(
            user=user,
            bvn_verified=True,
            wallet_provisioned=False,
            next_step="retry_wallet_provisioning",
            message=(
                "BVN verified successfully, but wallet provisioning is pending. "
                "Please retry shortly."
            ),
        )


# =============================================================================
# KYC Status
# =============================================================================

def get_kyc_status(user: User) -> dict:
    """
    Get current KYC status for a user.

    Args:
        user: User to check

    Returns:
        dict with KYC status details
    """
    return {
        "email_verified": user.verified_at is not None,
        "bvn_verified": user.bvn_verified,
        "has_wallet": user.has_wallet,
        "kyc_complete": user.kyc_complete,
        "kyc_completed_at": user.kyc_completed_at,
        "wallet_info": {
            "virtual_account": user.isw_virtual_acct_no,
            "bank": user.isw_virtual_acct_bank,
        } if user.has_wallet else None,
    }


def check_kyc_required(user: User, action: str = "this action") -> None:
    """
    Check if user has completed KYC, raise if not.

    Use this as a guard before operations that require KYC.

    Args:
        user: User to check
        action: Description for error message

    Raises:
        KYCError: If KYC not complete
    """
    if not user.verified_at:
        raise KYCError(f"Email verification required for {action}")

    if not user.bvn_verified:
        raise KYCError(f"BVN verification required for {action}")

    if not user.has_wallet:
        raise KYCError(f"Wallet required for {action}")
