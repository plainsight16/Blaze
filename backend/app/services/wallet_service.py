"""
Wallet Service - Business logic for wallet operations.

Orchestrates wallet provisioning, balance queries, and transfers
with proper transaction logging and automatic reversals.
"""
import base64
import hashlib
import logging
import secrets
import time
import uuid
from datetime import datetime, timezone
from decimal import Decimal
from typing import Optional, Tuple

from cryptography.fernet import Fernet, InvalidToken
from sqlalchemy.orm import Session

from app.config import WALLET_PIN_ENCRYPTION_KEY
from app.models.user import User
from app.models.group import Group
from app.models.wallet import WalletTransaction
from app.services import interswitch as isw
from app.services.interswitch import (
    InterswitchError,
    InterswitchInsufficientFundsError,
    InterswitchTransactionError,
)


logger = logging.getLogger(__name__)


# =============================================================================
# Exceptions
# =============================================================================

class WalletError(Exception):
    """Base exception for wallet operations."""
    pass


class WalletNotFoundError(WalletError):
    """Wallet does not exist."""
    pass


class WalletAlreadyExistsError(WalletError):
    """Wallet already provisioned."""
    pass


class InsufficientBalanceError(WalletError):
    """Insufficient wallet balance."""
    pass


class InvalidPinError(WalletError):
    """Invalid wallet PIN."""
    pass


class TransferError(WalletError):
    """Transfer operation failed."""
    pass


# =============================================================================
# PIN Encryption
# =============================================================================

def _get_cipher() -> Fernet:
    """
    Get Fernet cipher for PIN encryption.

    Derives a 32-byte key from the config using SHA-256,
    then base64 encodes it for Fernet.
    """
    key_bytes = hashlib.sha256(WALLET_PIN_ENCRYPTION_KEY.encode()).digest()
    return Fernet(base64.urlsafe_b64encode(key_bytes))


def encrypt_pin(pin: str) -> str:
    """
    Encrypt wallet PIN for secure storage.

    Args:
        pin: Plain 4-digit PIN

    Returns:
        Encrypted PIN string
    """
    cipher = _get_cipher()
    return cipher.encrypt(pin.encode()).decode()


def decrypt_pin(encrypted_pin: str) -> str:
    """
    Decrypt wallet PIN for API calls.

    Args:
        encrypted_pin: Encrypted PIN from database

    Returns:
        Plain 4-digit PIN

    Raises:
        WalletError: If decryption fails
    """
    try:
        cipher = _get_cipher()
        return cipher.decrypt(encrypted_pin.encode()).decode()
    except InvalidToken:
        logger.error("Failed to decrypt wallet PIN - invalid token")
        raise WalletError("PIN decryption failed")


def generate_wallet_pin() -> str:
    """
    Generate a cryptographically secure random 4-digit PIN.

    Returns:
        4-digit PIN string (e.g., "0472")
    """
    return f"{secrets.randbelow(10000):04d}"


# =============================================================================
# Transaction Reference Generation
# =============================================================================

def _generate_ref(prefix: str, *parts: str) -> str:
    """Generate a unique transaction reference."""
    timestamp = int(time.time() * 1000)  # Millisecond precision
    parts_str = "-".join(p[:8] for p in parts if p)
    return f"{prefix}-{parts_str}-{timestamp}"


def generate_wallet_creation_ref(customer_id: str) -> str:
    """Reference for wallet creation."""
    return _generate_ref("WAL", customer_id)


def generate_contribution_debit_ref(group_id: str, user_id: str) -> str:
    """Reference for contribution debit (user → group)."""
    return _generate_ref("CTR-D", group_id, user_id)


def generate_contribution_credit_ref(group_id: str, user_id: str) -> str:
    """Reference for contribution credit (user → group)."""
    return _generate_ref("CTR-C", group_id, user_id)


def generate_payout_debit_ref(group_id: str, cycle: int) -> str:
    """Reference for payout debit (group → user)."""
    return _generate_ref("PAY-D", group_id, str(cycle))


def generate_payout_credit_ref(group_id: str, user_id: str) -> str:
    """Reference for payout credit (group → user)."""
    return _generate_ref("PAY-C", group_id, user_id)


def generate_reversal_ref(original_ref: str) -> str:
    """Reference for transaction reversal."""
    return f"REV-{original_ref[-20:]}-{int(time.time())}"


# =============================================================================
# Transaction Logging
# =============================================================================

def _log_transaction(
    db: Session,
    wallet_owner_type: str,
    wallet_owner_id: str,
    transaction_type: str,
    amount: Decimal,
    status: str = "pending",
    counterparty_type: Optional[str] = None,
    counterparty_id: Optional[str] = None,
    transaction_ref: Optional[str] = None,
    description: Optional[str] = None,
    narration: Optional[str] = None,
) -> WalletTransaction:
    """
    Create a wallet transaction log entry.

    All wallet operations are logged for audit and reconciliation.
    """
    tx = WalletTransaction(
        id=str(uuid.uuid4()),
        wallet_owner_type=wallet_owner_type,
        wallet_owner_id=wallet_owner_id,
        transaction_type=transaction_type,
        amount=amount,
        currency="NGN",
        counterparty_type=counterparty_type,
        counterparty_id=counterparty_id,
        transaction_ref=transaction_ref,
        description=description,
        narration=narration,
        status=status,
        created_at=datetime.now(timezone.utc),
    )
    db.add(tx)
    db.flush()  # Get ID without committing
    return tx


def _update_transaction(
    db: Session,
    tx: WalletTransaction,
    status: str,
    isw_reference: Optional[str] = None,
    isw_response_code: Optional[str] = None,
    isw_response_msg: Optional[str] = None,
):
    """Update transaction status after ISW response."""
    tx.status = status
    tx.isw_reference = isw_reference
    tx.isw_response_code = isw_response_code
    tx.isw_response_msg = isw_response_msg
    tx.updated_at = datetime.now(timezone.utc)
    db.flush()


# =============================================================================
# Wallet Provisioning
# =============================================================================

async def provision_user_wallet(
    db: Session,
    user: User,
    phone_number: str,
) -> User:
    """
    Provision a static Interswitch virtual account for a KYC-verified user.

    Prerequisites:
    - User must have verified email (verified_at is set)
    - User must have completed BVN verification (bvn_verified=True)

    Steps:
    1. Validate prerequisites
    2. Call ISW static virtual-account API
    3. Store the generated funding account details

    Args:
        db: Database session
        user: User model instance
        phone_number: Nigerian phone number

    Returns:
        Updated User with wallet details

    Raises:
        WalletAlreadyExistsError: If user already has wallet
        WalletError: If provisioning fails
    """
    if user.isw_wallet_id:
        raise WalletAlreadyExistsError("User already has a wallet")

    if not user.bvn_verified:
        raise WalletError("BVN verification required before wallet provisioning")

    if not user.verified_at:
        raise WalletError("Email verification required before wallet provisioning")

    logger.info(f"Provisioning wallet for user: {user.id}")

    try:
        account_name = user.full_name
        wallet = await isw.create_wallet(
            account_name=account_name,
            customer_id=user.id,
        )

        # Store wallet details
        user.phone_number = phone_number
        user.isw_wallet_id = wallet.wallet_id
        user.isw_merchant_code = wallet.merchant_code
        user.isw_virtual_acct_no = wallet.account_number
        user.isw_virtual_acct_bank = wallet.bank_name
        user.wallet_pin_encrypted = None

        db.commit()
        db.refresh(user)

        logger.info(f"Virtual account provisioned for user {user.id}: {wallet.wallet_id}")
        return user

    except InterswitchError as e:
        logger.error(f"Failed to provision wallet for user {user.id}: {e}")
        db.rollback()
        raise WalletError(f"Wallet provisioning failed: {e.message}")


async def provision_group_wallet(
    db: Session,
    group: Group,
    owner: User,
) -> Group:
    """
    Provision an Interswitch wallet for a group.

    The group wallet is used to collect contributions and can receive deposits
    through the generated static virtual account.

    Prerequisites:
    - Owner must have completed KYC
    - Group must not already have a wallet

    Args:
        db: Database session
        group: Group model instance
        owner: Group owner (used for contact details)

    Returns:
        Updated Group with wallet details

    Raises:
        WalletAlreadyExistsError: If group already has wallet
        WalletError: If provisioning fails
    """
    if group.isw_wallet_id:
        raise WalletAlreadyExistsError("Group already has a wallet")

    if not owner.bvn_verified:
        raise WalletError("Group owner must complete KYC first")

    customer_id = f"GRP-{group.id}"

    logger.info(f"Provisioning wallet for group: {group.id}")

    try:
        wallet = await isw.create_wallet(
            account_name=group.name[:100],
            customer_id=customer_id,
        )

        # Store wallet details
        group.isw_wallet_id = wallet.wallet_id
        group.isw_merchant_code = wallet.merchant_code
        group.isw_virtual_acct_no = wallet.account_number
        group.isw_virtual_acct_bank = wallet.bank_name
        group.wallet_pin_encrypted = None

        db.commit()
        db.refresh(group)

        logger.info(f"Virtual account provisioned for group {group.id}: {wallet.wallet_id}")
        return group

    except InterswitchError as e:
        logger.error(f"Failed to provision wallet for group {group.id}: {e}")
        db.rollback()
        raise WalletError(f"Group wallet provisioning failed: {e.message}")


# =============================================================================
# Balance Queries
# =============================================================================

async def get_user_balance(user: User) -> dict:
    """
    Get user wallet balance from Interswitch.

    This queries ISW directly - balances are never cached locally.

    Args:
        user: User with wallet

    Returns:
        dict with available_balance, ledger_balance, currency, virtual_account, bank

    Raises:
        WalletNotFoundError: If user has no wallet
        WalletError: If balance query fails
    """
    if not user.isw_wallet_id:
        raise WalletNotFoundError("User does not have a wallet")
    if not user.wallet_pin_encrypted:
        raise WalletError("Balance queries are not supported for static virtual accounts yet")

    try:
        balance = await isw.get_wallet_balance(user.isw_wallet_id)
        return {
            "available_balance": balance.available_balance,
            "ledger_balance": balance.ledger_balance,
            "currency": balance.currency,
            "virtual_account": user.isw_virtual_acct_no,
            "bank": user.isw_virtual_acct_bank,
        }
    except InterswitchError as e:
        logger.error(f"Failed to get balance for user {user.id}: {e}")
        raise WalletError(f"Balance query failed: {e.message}")


async def get_group_balance(group: Group) -> dict:
    """
    Get group wallet balance from Interswitch.

    Args:
        group: Group with wallet

    Returns:
        dict with available_balance, ledger_balance, currency, virtual_account, bank

    Raises:
        WalletNotFoundError: If group has no wallet
        WalletError: If balance query fails
    """
    if not group.isw_wallet_id:
        raise WalletNotFoundError("Group does not have a wallet")
    if not group.wallet_pin_encrypted:
        raise WalletError("Balance queries are not supported for static virtual accounts yet")

    try:
        balance = await isw.get_wallet_balance(group.isw_wallet_id)
        return {
            "available_balance": balance.available_balance,
            "ledger_balance": balance.ledger_balance,
            "currency": balance.currency,
            "virtual_account": group.isw_virtual_acct_no,
            "bank": group.isw_virtual_acct_bank,
        }
    except InterswitchError as e:
        logger.error(f"Failed to get balance for group {group.id}: {e}")
        raise WalletError(f"Balance query failed: {e.message}")


# =============================================================================
# Wallet-to-Wallet Transfers
# =============================================================================

async def transfer_user_to_group(
    db: Session,
    user: User,
    group: Group,
    amount: Decimal,
    user_pin: str,
    narration: Optional[str] = None,
) -> dict:
    """
    Transfer funds from user wallet to group wallet (contribution).

    This is an atomic operation with automatic rollback:
    1. Debit user wallet (requires PIN)
    2. Credit group wallet
    3. If credit fails, reverse user debit

    All steps are logged as WalletTransaction records.

    Args:
        db: Database session
        user: Source user with wallet
        group: Destination group with wallet
        amount: Amount in Naira (Decimal for precision)
        user_pin: User's 4-digit wallet PIN
        narration: Optional description

    Returns:
        dict with status, debit_reference, credit_reference, amount

    Raises:
        WalletNotFoundError: If either wallet is missing
        InsufficientBalanceError: If user balance is too low
        InvalidPinError: If PIN is incorrect
        TransferError: If transfer fails
    """
    # Validate wallets exist
    if not user.isw_wallet_id:
        raise WalletNotFoundError("User does not have a wallet")
    if not group.isw_wallet_id:
        raise WalletNotFoundError("Group does not have a wallet")
    if not user.wallet_pin_encrypted or not group.wallet_pin_encrypted:
        raise TransferError("Transfers are not supported for static virtual accounts yet")

    amount_decimal = Decimal(str(amount))
    narration = narration or f"Contribution to {group.name}"

    # Generate references
    debit_ref = generate_contribution_debit_ref(group.id, user.id)
    credit_ref = generate_contribution_credit_ref(group.id, user.id)

    logger.info(f"Transfer: User {user.id} -> Group {group.id}, amount: {amount}")

    # Step 1: Log pending debit
    debit_tx = _log_transaction(
        db=db,
        wallet_owner_type="user",
        wallet_owner_id=user.id,
        transaction_type="debit",
        amount=amount_decimal,
        counterparty_type="group",
        counterparty_id=group.id,
        transaction_ref=debit_ref,
        description=f"Contribution to group: {group.name}",
        narration=narration,
    )
    db.commit()

    # Step 2: Debit user wallet
    try:
        debit_result = await isw.debit_wallet(
            wallet_id=user.isw_wallet_id,
            amount=float(amount_decimal),
            pin=user_pin,
            transaction_ref=debit_ref,
            narration=narration,
        )

        _update_transaction(
            db, debit_tx,
            status="completed",
            isw_reference=debit_result.external_reference,
            isw_response_code=debit_result.response_code,
            isw_response_msg=debit_result.response_message,
        )
        db.commit()

    except InterswitchInsufficientFundsError:
        _update_transaction(db, debit_tx, status="failed", isw_response_code="51")
        db.commit()
        raise InsufficientBalanceError("Insufficient wallet balance")

    except InterswitchTransactionError as e:
        _update_transaction(
            db, debit_tx,
            status="failed",
            isw_response_code=e.response_code,
            isw_response_msg=str(e.message),
        )
        db.commit()

        if e.response_code == "55":
            raise InvalidPinError("Invalid wallet PIN")
        raise TransferError(f"Debit failed: {e.message}")

    # Step 3: Log pending credit
    credit_tx = _log_transaction(
        db=db,
        wallet_owner_type="group",
        wallet_owner_id=group.id,
        transaction_type="credit",
        amount=amount_decimal,
        counterparty_type="user",
        counterparty_id=user.id,
        transaction_ref=credit_ref,
        description=f"Contribution from: {user.full_name}",
        narration=narration,
    )
    db.commit()

    # Step 4: Credit group wallet
    try:
        credit_result = await isw.credit_wallet(
            wallet_id=group.isw_wallet_id,
            amount=float(amount_decimal),
            transaction_ref=credit_ref,
            narration=f"Contribution from {user.first_name} {user.last_name}",
        )

        _update_transaction(
            db, credit_tx,
            status="completed",
            isw_reference=credit_result.external_reference,
            isw_response_code=credit_result.response_code,
            isw_response_msg=credit_result.response_message,
        )
        db.commit()

        logger.info(f"Transfer successful: {debit_ref} -> {credit_ref}")

        return {
            "status": "success",
            "debit_reference": debit_ref,
            "credit_reference": credit_ref,
            "amount": float(amount_decimal),
        }

    except InterswitchTransactionError as e:
        logger.error(f"Credit failed, reversing debit: {e}")

        _update_transaction(
            db, credit_tx,
            status="failed",
            isw_response_code=e.response_code,
            isw_response_msg=str(e.message),
        )
        db.commit()

        # Reverse the user debit
        await _reverse_transaction(db, debit_tx, debit_ref, user.id, "user")

        raise TransferError(f"Credit failed, debit reversed: {e.message}")


async def transfer_group_to_user(
    db: Session,
    group: Group,
    user: User,
    amount: Decimal,
    narration: Optional[str] = None,
) -> dict:
    """
    Transfer funds from group wallet to user wallet (payout).

    This uses the group's system-generated PIN (never exposed to users).

    Steps:
    1. Debit group wallet (system PIN)
    2. Credit user wallet
    3. If credit fails, reverse group debit

    Args:
        db: Database session
        group: Source group with wallet
        user: Destination user with wallet
        amount: Amount in Naira
        narration: Optional description

    Returns:
        dict with status, debit_reference, credit_reference, amount

    Raises:
        WalletNotFoundError: If either wallet is missing
        InsufficientBalanceError: If group balance is too low
        TransferError: If transfer fails
    """
    # Validate wallets exist
    if not group.isw_wallet_id:
        raise WalletNotFoundError("Group does not have a wallet")
    if not user.isw_wallet_id:
        raise WalletNotFoundError("User does not have a wallet")
    if not group.wallet_pin_encrypted or not user.wallet_pin_encrypted:
        raise TransferError("Transfers are not supported for static virtual accounts yet")

    if not group.wallet_pin_encrypted:
        raise WalletError("Group wallet PIN not found")

    amount_decimal = Decimal(str(amount))
    narration = narration or f"Payout from {group.name}"

    # Decrypt group's system PIN
    group_pin = decrypt_pin(group.wallet_pin_encrypted)

    # Generate references
    cycle = group.current_cycle or 1
    debit_ref = generate_payout_debit_ref(group.id, cycle)
    credit_ref = generate_payout_credit_ref(group.id, user.id)

    logger.info(f"Payout: Group {group.id} -> User {user.id}, amount: {amount}")

    # Step 1: Log pending debit
    debit_tx = _log_transaction(
        db=db,
        wallet_owner_type="group",
        wallet_owner_id=group.id,
        transaction_type="debit",
        amount=amount_decimal,
        counterparty_type="user",
        counterparty_id=user.id,
        transaction_ref=debit_ref,
        description=f"Payout to: {user.full_name}",
        narration=narration,
    )
    db.commit()

    # Step 2: Debit group wallet
    try:
        debit_result = await isw.debit_wallet(
            wallet_id=group.isw_wallet_id,
            amount=float(amount_decimal),
            pin=group_pin,
            transaction_ref=debit_ref,
            narration=f"Payout to {user.first_name} {user.last_name}",
        )

        _update_transaction(
            db, debit_tx,
            status="completed",
            isw_reference=debit_result.external_reference,
            isw_response_code=debit_result.response_code,
            isw_response_msg=debit_result.response_message,
        )
        db.commit()

    except InterswitchInsufficientFundsError:
        _update_transaction(db, debit_tx, status="failed", isw_response_code="51")
        db.commit()
        raise InsufficientBalanceError("Insufficient group wallet balance")

    except InterswitchTransactionError as e:
        _update_transaction(
            db, debit_tx,
            status="failed",
            isw_response_code=e.response_code,
            isw_response_msg=str(e.message),
        )
        db.commit()
        raise TransferError(f"Group debit failed: {e.message}")

    # Step 3: Log pending credit
    credit_tx = _log_transaction(
        db=db,
        wallet_owner_type="user",
        wallet_owner_id=user.id,
        transaction_type="credit",
        amount=amount_decimal,
        counterparty_type="group",
        counterparty_id=group.id,
        transaction_ref=credit_ref,
        description=f"Payout from group: {group.name}",
        narration=narration,
    )
    db.commit()

    # Step 4: Credit user wallet
    try:
        credit_result = await isw.credit_wallet(
            wallet_id=user.isw_wallet_id,
            amount=float(amount_decimal),
            transaction_ref=credit_ref,
            narration=f"Payout from {group.name}",
        )

        _update_transaction(
            db, credit_tx,
            status="completed",
            isw_reference=credit_result.external_reference,
            isw_response_code=credit_result.response_code,
            isw_response_msg=credit_result.response_message,
        )
        db.commit()

        logger.info(f"Payout successful: {debit_ref} -> {credit_ref}")

        return {
            "status": "success",
            "debit_reference": debit_ref,
            "credit_reference": credit_ref,
            "amount": float(amount_decimal),
        }

    except InterswitchTransactionError as e:
        logger.error(f"Payout credit failed, reversing debit: {e}")

        _update_transaction(
            db, credit_tx,
            status="failed",
            isw_response_code=e.response_code,
            isw_response_msg=str(e.message),
        )
        db.commit()

        # Reverse the group debit
        await _reverse_transaction(db, debit_tx, debit_ref, group.id, "group")

        raise TransferError(f"Payout credit failed, debit reversed: {e.message}")


# =============================================================================
# Transaction Reversal
# =============================================================================

async def _reverse_transaction(
    db: Session,
    original_tx: WalletTransaction,
    original_ref: str,
    wallet_owner_id: str,
    wallet_owner_type: str,
) -> bool:
    """
    Reverse a completed transaction.

    Used to undo a debit when the corresponding credit fails.

    Args:
        db: Database session
        original_tx: The transaction to reverse
        original_ref: Original transaction reference
        wallet_owner_id: Owner of the wallet being reversed
        wallet_owner_type: "user" or "group"

    Returns:
        True if reversal succeeded
    """
    reversal_ref = generate_reversal_ref(original_ref)

    # Log pending reversal
    reversal_tx = _log_transaction(
        db=db,
        wallet_owner_type=wallet_owner_type,
        wallet_owner_id=wallet_owner_id,
        transaction_type="reversal",
        amount=original_tx.amount,
        transaction_ref=reversal_ref,
        description=f"Reversal of {original_ref}",
        status="pending",
    )
    reversal_tx.original_transaction_id = original_tx.id
    db.commit()

    try:
        result = await isw.reverse_transaction(original_ref, reversal_ref)

        _update_transaction(
            db, reversal_tx,
            status="completed",
            isw_reference=result.external_reference,
            isw_response_code=result.response_code,
            isw_response_msg=result.response_message,
        )

        # Mark original as reversed
        original_tx.status = "reversed"
        original_tx.updated_at = datetime.now(timezone.utc)
        db.commit()

        logger.info(f"Transaction reversed: {original_ref} -> {reversal_ref}")
        return True

    except InterswitchTransactionError as e:
        logger.error(f"Reversal failed for {original_ref}: {e}")

        _update_transaction(
            db, reversal_tx,
            status="failed",
            isw_response_code=e.response_code,
            isw_response_msg=str(e.message),
        )
        db.commit()

        # This is a critical error - manual intervention may be needed
        logger.critical(f"CRITICAL: Failed to reverse transaction {original_ref}")
        return False


# =============================================================================
# Transaction History
# =============================================================================

def get_user_transactions(
    db: Session,
    user_id: str,
    limit: int = 50,
    offset: int = 0,
) -> list[WalletTransaction]:
    """Get transaction history for a user."""
    return (
        db.query(WalletTransaction)
        .filter(
            WalletTransaction.wallet_owner_type == "user",
            WalletTransaction.wallet_owner_id == user_id,
        )
        .order_by(WalletTransaction.created_at.desc())
        .offset(offset)
        .limit(limit)
        .all()
    )


def get_group_transactions(
    db: Session,
    group_id: str,
    limit: int = 50,
    offset: int = 0,
) -> list[WalletTransaction]:
    """Get transaction history for a group."""
    return (
        db.query(WalletTransaction)
        .filter(
            WalletTransaction.wallet_owner_type == "group",
            WalletTransaction.wallet_owner_id == group_id,
        )
        .order_by(WalletTransaction.created_at.desc())
        .offset(offset)
        .limit(limit)
        .all()
    )
