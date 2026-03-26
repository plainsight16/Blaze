"""
KYC routes.

GET  /kyc/requirements   - discover whether BVN capture is still required
GET  /kyc/status         - inspect the authenticated user's KYC state
POST /kyc/verify-bvn     - submit BVN for verification
POST /kyc/verify         - backward-compatible alias for older clients
POST /kyc/bank-statement - generate or regenerate the user's bank statement
GET  /kyc/bank-statement - fetch the current bank statement
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.models.user import User
from app.schemas.kyc import (
    BankStatementResponse,
    KYCRequest,
    KYCRequirementsResponse,
    KYCStatusResponse,
    KYCVerificationResponse,
)
from app.services.interswitch import InterswitchError
from app.services.kyc import generate_bank_statement, get_kyc_requirements, get_kyc_status, verify_bvn
from app.utils.dependencies import get_current_user, get_db

router = APIRouter()


@router.get("/requirements", response_model=KYCRequirementsResponse)
def kyc_requirements(
    db: Session = Depends(get_db),
    cur_user: User = Depends(get_current_user),
) -> KYCRequirementsResponse:
    return get_kyc_requirements(cur_user.id, db)


@router.get("/status", response_model=KYCStatusResponse)
def kyc_status(
    db: Session = Depends(get_db),
    cur_user: User = Depends(get_current_user),
) -> KYCStatusResponse:
    return get_kyc_status(cur_user.id, db)


@router.post("/verify-bvn", response_model=KYCVerificationResponse, status_code=status.HTTP_201_CREATED)
def verify_kyc(
    payload: KYCRequest,
    db: Session = Depends(get_db),
    cur_user: User = Depends(get_current_user),
) -> KYCVerificationResponse:
    try:
        kyc = verify_bvn(db, cur_user, payload.bvn)
    except ValueError as exc:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, detail=str(exc))
    except InterswitchError as exc:
        raise HTTPException(status.HTTP_502_BAD_GATEWAY, detail=str(exc))

    return KYCVerificationResponse(kyc_id=kyc.id, status=kyc.status)


@router.post("/verify", response_model=KYCVerificationResponse, status_code=status.HTTP_201_CREATED)
def verify_kyc_legacy(
    payload: KYCRequest,
    db: Session = Depends(get_db),
    cur_user: User = Depends(get_current_user),
) -> KYCVerificationResponse:
    """Backward-compatible alias for clients still calling /kyc/verify."""
    return verify_kyc(payload=payload, db=db, cur_user=cur_user)


@router.post(
    "/bank-statement",
    response_model=BankStatementResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_bank_statement(
    db: Session = Depends(get_db),
    cur_user: User = Depends(get_current_user),
) -> BankStatementResponse:
    statement = generate_bank_statement(db, cur_user.id)
    return BankStatementResponse.model_validate(statement)


@router.get("/bank-statement", response_model=BankStatementResponse)
def get_bank_statement(
    db: Session = Depends(get_db),
    cur_user: User = Depends(get_current_user),
) -> BankStatementResponse:
    from app.models.bank_statement import BankStatement

    statement = db.query(BankStatement).filter(BankStatement.user_id == cur_user.id).first()
    if not statement:
        raise HTTPException(
            status.HTTP_404_NOT_FOUND,
            "No bank statement found. POST /kyc/bank-statement to generate one.",
        )
    return BankStatementResponse.model_validate(statement)
