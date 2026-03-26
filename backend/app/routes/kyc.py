"""
KYC routes.

POST /kyc/verify           — submit BVN for verification
POST /kyc/bank-statement   — generate (or regenerate) bank statement
GET  /kyc/bank-statement   — fetch the current bank statement
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.models.user import User
from app.schemas.kyc import BankStatementResponse, KYCRequest, KYCStatusResponse
from app.services.kyc import generate_bank_statement, verify_bvn
from app.utils.dependencies import get_current_user, get_db

router = APIRouter()


@router.post("/verify", response_model=KYCStatusResponse, status_code=status.HTTP_201_CREATED)
def verify_kyc(
    payload:  KYCRequest,
    db:       Session = Depends(get_db),
    cur_user: User    = Depends(get_current_user),
) -> KYCStatusResponse:
    try:
        kyc = verify_bvn(db, cur_user.id, payload.bvn)
    except ValueError as exc:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, detail=str(exc))

    return KYCStatusResponse(kyc_id=kyc.id, status=kyc.status)


@router.post(
    "/bank-statement",
    response_model=BankStatementResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_bank_statement(
    db:       Session = Depends(get_db),
    cur_user: User    = Depends(get_current_user),
) -> BankStatementResponse:
    """Generate or regenerate the authenticated user's bank statement."""
    statement = generate_bank_statement(db, cur_user.id)
    return BankStatementResponse.model_validate(statement)


@router.get("/bank-statement", response_model=BankStatementResponse)
def get_bank_statement(
    db:       Session = Depends(get_db),
    cur_user: User    = Depends(get_current_user),
) -> BankStatementResponse:
    """Fetch the user's most recent bank statement without regenerating it."""
    from app.models.bank_statement import BankStatement  # local to avoid circular at module level

    statement = db.query(BankStatement).filter(
        BankStatement.user_id == cur_user.id
    ).first()
    if not statement:
        raise HTTPException(
            status.HTTP_404_NOT_FOUND,
            "No bank statement found. POST /kyc/bank-statement to generate one.",
        )
    return BankStatementResponse.model_validate(statement)