from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.models.user import User
from app.schemas.wallet import WalletResponse
from app.services.wallet import WalletProvisioningError, get_wallet_by_user_id, provision_user_wallet
from app.utils.dependencies import get_current_user, get_db

router = APIRouter()


@router.get("", response_model=WalletResponse)
def get_wallet(
    db: Session = Depends(get_db),
    cur_user: User = Depends(get_current_user),
) -> WalletResponse:
    wallet = get_wallet_by_user_id(cur_user.id, db)
    if not wallet:
        raise HTTPException(
            status.HTTP_404_NOT_FOUND,
            "Wallet not found. Complete BVN verification to provision your wallet.",
        )
    return WalletResponse.model_validate(wallet)


@router.post("/provision", response_model=WalletResponse)
def provision_wallet(
    db: Session = Depends(get_db),
    cur_user: User = Depends(get_current_user),
) -> WalletResponse:
    try:
        wallet = provision_user_wallet(db, cur_user)
    except ValueError as exc:
        raise HTTPException(status.HTTP_403_FORBIDDEN, detail=str(exc))
    except WalletProvisioningError as exc:
        raise HTTPException(status.HTTP_502_BAD_GATEWAY, detail=str(exc))

    return WalletResponse.model_validate(wallet)
