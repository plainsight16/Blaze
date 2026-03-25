from sqlalchemy.orm import Session
from app.models.kyc import KYC
from app.models.user import User
from app.utils.security import hash_bvn

import random
from typing import Dict, Any


def verify_bvn(db: Session, user_id: str, bvn: str):
    if not bvn.isdigit() or len(bvn) != 11:
        raise ValueError("Invalid BVN")

    bvn_hashed = hash_bvn(bvn)

    existing_bvn = db.query(KYC).filter(KYC.bvn_hash == bvn_hashed).first()
    existing_user = db.query(KYC).filter(KYC.user_id == user_id).first()
    if existing_bvn:
        raise ValueError("BVN already linked to another account")
    elif existing_user:
        raise ValueError("User already linked to a BVN")

    kyc = KYC(
        user_id=user_id,
        bvn_hash=bvn_hashed,
        verified="true"
    )

    db.add(kyc)
    db.commit()
    db.refresh(kyc)

    return kyc

def generate_bank_statement() -> Dict[str, Any]:
    months = ["2024-04", "2024-05", "2024-06"]

    month_data = []
    total_debit = total_credit = 0
    debit_count = credit_count = 0
    balance_sum = 0

    for m in months:
        td = random.randint(1000, 500000)
        tc = random.randint(0, 1000000)
        dc = random.randint(1, 20)
        cc = random.randint(0, 15)
        ab = random.uniform(0, 300000)

        total_debit += td
        total_credit += tc
        debit_count += dc
        credit_count += cc
        balance_sum += ab

        month_data.append({
            "totalDebit": float(td),
            "debitCount": float(dc),
            "totalCredit": float(tc),
            "creditCount": float(cc),
            "yearMonth": m,
            "averageBalance": float(round(ab, 2))
        })

    avg_len = len(months)

    return {
        "monthOnMonth": month_data,
        "averageValue": {
            "totalDebit": total_debit / avg_len,
            "debitCount": debit_count / avg_len,
            "totalCredit": total_credit / avg_len,
            "creditCount": credit_count / avg_len,
            "averageBalance": balance_sum / avg_len
        }
    }

def attach_bank_statement(db: Session, user_id: str):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise ValueError("User not found")

    kyc = db.query(KYC).filter(KYC.user_id == user_id).first()
    if not kyc or not kyc.verified:
        raise ValueError("KYC not verified")

    statement = generate_bank_statement()

    kyc.bank_statement = statement
    db.commit()
    db.refresh(kyc)

    return statement