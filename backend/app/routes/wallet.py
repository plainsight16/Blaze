"""
Wallet API Routes.

Endpoints for wallet balance queries, transfers, and transaction history.
"""
import logging
from decimal import Decimal

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.models.user import User
from app.models.group import Group
from app.utils.dependencies import get_db, get_current_user
from app.services import wallet_service
from app.services.wallet_service import (
    WalletError,
    WalletNotFoundError,
    InsufficientBalanceError,
    InvalidPinError,
    TransferError,
)
from app.schemas.wallet import (
    WalletBalanceResponse,
    WalletInfoResponse,
    TransferToGroupRequest,
    TransferResponse,
    TransactionResponse,
    TransactionListResponse,
)


logger = logging.getLogger(__name__)
router = APIRouter(prefix="/wallet", tags=["Wallet"])


# =============================================================================
# Wallet Info & Balance
# =============================================================================

@router.get("/info", response_model=WalletInfoResponse)
async def get_wallet_info(
    current_user: User = Depends(get_current_user),
):
    """
    Get current user's wallet information.

    Returns wallet details including virtual account number for funding.
    """
    if not current_user.has_wallet:
        return WalletInfoResponse(
            has_wallet=False,
            wallet_id=None,
            virtual_account_number=None,
            virtual_account_bank=None,
        )

    return WalletInfoResponse(
        has_wallet=True,
        wallet_id=current_user.isw_wallet_id,
        virtual_account_number=current_user.isw_virtual_acct_no,
        virtual_account_bank=current_user.isw_virtual_acct_bank,
    )


@router.get("/balance", response_model=WalletBalanceResponse)
async def get_wallet_balance(
    current_user: User = Depends(get_current_user),
):
    """
    Get current user's wallet balance.

    Queries Interswitch directly for real-time balance.
    Balance is never cached.
    """
    if not current_user.has_wallet:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Complete KYC to access wallet features",
        )

    try:
        balance = await wallet_service.get_user_balance(current_user)
        return WalletBalanceResponse(**balance)
    except WalletNotFoundError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))
    except WalletError as e:
        if "not supported for static virtual accounts" in str(e):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=str(e),
            )
        logger.error(f"Balance query failed for user {current_user.id}: {e}")
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail="Unable to retrieve balance. Please try again.",
        )


@router.get("/group/{group_id}/balance", response_model=WalletBalanceResponse)
async def get_group_wallet_balance(
    group_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Get group's wallet balance.

    Members can view their group's balance. Queries Interswitch directly.
    """
    # Get group
    group = db.query(Group).filter(Group.id == group_id, Group.is_active == True).first()
    if not group:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Group not found",
        )

    # Verify user is a member
    from app.models.group import UserGroup
    membership = db.query(UserGroup).filter(
        UserGroup.user_id == current_user.id,
        UserGroup.group_id == group.id,
    ).first()

    if not membership:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You must be a group member to view balance",
        )

    if not group.has_wallet:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Group wallet not provisioned",
        )

    try:
        balance = await wallet_service.get_group_balance(group)
        return WalletBalanceResponse(**balance)
    except WalletNotFoundError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))
    except WalletError as e:
        if "not supported for static virtual accounts" in str(e):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=str(e),
            )
        logger.error(f"Balance query failed for group {group.id}: {e}")
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail="Unable to retrieve balance. Please try again.",
        )


# =============================================================================
# Transfers
# =============================================================================

@router.post("/transfer/to-group", response_model=TransferResponse)
async def transfer_to_group(
    request: TransferToGroupRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Transfer funds from user wallet to group wallet.

    This is used for group contributions. Requires wallet PIN.

    The transfer is atomic:
    - If the group credit fails, the user debit is automatically reversed.
    """
    if not current_user.has_wallet:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Complete KYC to make transfers",
        )

    # Get group
    group = db.query(Group).filter(Group.id == request.group_id).first()
    if not group:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Group not found",
        )

    if not group.has_wallet:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Group wallet not available",
        )

    # Verify user is a member
    from app.models.group import UserGroup
    membership = db.query(UserGroup).filter(
        UserGroup.user_id == current_user.id,
        UserGroup.group_id == group.id,
    ).first()

    if not membership:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You must be a group member to contribute",
        )

    try:
        result = await wallet_service.transfer_user_to_group(
            db=db,
            user=current_user,
            group=group,
            amount=request.amount,
            user_pin=request.pin,
            narration=request.narration,
        )

        return TransferResponse(
            status=result["status"],
            debit_reference=result["debit_reference"],
            credit_reference=result["credit_reference"],
            amount=result["amount"],
            message="Contribution successful",
        )

    except InsufficientBalanceError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Insufficient wallet balance",
        )

    except InvalidPinError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid wallet PIN",
        )

    except TransferError as e:
        if "not supported for static virtual accounts" in str(e):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=str(e),
            )
        logger.error(f"Transfer failed: {e}")
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=str(e),
        )


# =============================================================================
# Transaction History
# =============================================================================

@router.get("/transactions", response_model=TransactionListResponse)
async def get_transaction_history(
    limit: int = 50,
    offset: int = 0,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Get user's wallet transaction history.

    Returns transactions in reverse chronological order (newest first).
    """
    if not current_user.has_wallet:
        return TransactionListResponse(
            transactions=[],
            total=0,
            limit=limit,
            offset=offset,
        )

    # Clamp limit
    limit = min(limit, 100)

    transactions = wallet_service.get_user_transactions(
        db=db,
        user_id=current_user.id,
        limit=limit,
        offset=offset,
    )

    # Get total count
    from app.models.wallet import WalletTransaction
    total = db.query(WalletTransaction).filter(
        WalletTransaction.wallet_owner_type == "user",
        WalletTransaction.wallet_owner_id == current_user.id,
    ).count()

    return TransactionListResponse(
        transactions=[
            TransactionResponse(
                id=tx.id,
                transaction_type=tx.transaction_type,
                amount=float(tx.amount),
                currency=tx.currency,
                status=tx.status,
                counterparty_type=tx.counterparty_type,
                counterparty_id=tx.counterparty_id,
                description=tx.description,
                narration=tx.narration,
                transaction_ref=tx.transaction_ref,
                created_at=tx.created_at,
            )
            for tx in transactions
        ],
        total=total,
        limit=limit,
        offset=offset,
    )
