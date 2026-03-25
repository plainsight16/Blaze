from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.models.user import User
from app.schemas.kyc import KYCRequest
from app.services.kyc import verify_bvn, attach_bank_statement
from app.utils.dependencies import get_current_user, get_db

router = APIRouter()

@router.post("/verify")
def verify_kyc(payload: KYCRequest, db: Session = Depends(get_db), cur_user: User = Depends(get_current_user)):
    user_id = cur_user.id
    try:
        kyc = verify_bvn(db, user_id, payload.bvn)    
        return {
            "responseCode": "00",
            "responseMessage": "BVN verified",
            "data": {"kycId": kyc.id}
        }

    except ValueError as e:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Invalid BVN")


@router.post("/generate-statement")
def generate_statement(db: Session = Depends(get_db), cur_user: User = Depends(get_current_user)):
    user_id = cur_user.id
    try:
        statement = attach_bank_statement(db, user_id)

        return {
            "responseCode": "00",
            "responseMessage": "Statement generated",
            "data": statement
        }

    except ValueError as e:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "error generating statement")