"""
KYC service.

PR 1 responsibilities:
  - derive KYC requirements and status for the authenticated user
  - verify BVN against Interswitch using the user's stored name
  - store only the BVN hash after a successful boolean match
  - keep bank-statement generation isolated from identity verification
"""
from __future__ import annotations

import random
from datetime import datetime, timezone
from typing import Any

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models.bank_statement import BankStatement
from app.models.kyc import KYC
from app.models.user import User
from app.schemas.kyc import KYCRequirementsResponse, KYCStatusResponse
from app.services.interswitch import verify_bvn_boolean_match
from app.utils.security import hash_bvn


def get_kyc_status(user_id: str, db: Session) -> KYCStatusResponse:
    kyc = db.query(KYC).filter(KYC.user_id == user_id).first()
    bvn_verified = bool(kyc and kyc.is_verified)

    return KYCStatusResponse(
        kyc_id=kyc.id if kyc else None,
        status=kyc.status if kyc else "not_started",
        bvn_verified=bvn_verified,
        next_step="completed" if bvn_verified else "verify_bvn",
    )


def get_kyc_requirements(user_id: str, db: Session) -> KYCRequirementsResponse:
    snapshot = get_kyc_status(user_id, db)
    if snapshot.bvn_verified:
        return KYCRequirementsResponse(
            bvn_required=False,
            bvn_verified=True,
            next_step="completed",
        )

    return KYCRequirementsResponse(
        bvn_required=True,
        bvn_verified=False,
        next_step="verify_bvn",
        banner_title="Complete your KYC",
        banner_message="Verify your BVN to complete identity verification.",
    )


def verify_bvn(db: Session, user: User, bvn: str) -> KYC:
    """
    Verify the BVN against Interswitch, then hash and store it.
    Raises ValueError for invalid input or duplicate BVN ownership.
    """
    if not bvn.isdigit() or len(bvn) != 11:
        raise ValueError("BVN must be exactly 11 digits.")

    user_id = user.id
    bvn_hash = hash_bvn(bvn)

    existing_kyc = db.query(KYC).filter(KYC.user_id == user_id).first()
    if existing_kyc and existing_kyc.bvn_hash == bvn_hash and existing_kyc.is_verified:
        return existing_kyc

    existing_bvn = db.query(KYC).filter(KYC.bvn_hash == bvn_hash).first()
    if existing_bvn and existing_bvn.user_id != user_id:
        raise ValueError("BVN is already linked to another account.")

    if existing_kyc and existing_kyc.bvn_hash != bvn_hash:
        raise ValueError("User already has a different BVN linked.")

    matched = verify_bvn_boolean_match(user.first_name, user.last_name, bvn)
    if not matched:
        raise ValueError("BVN could not be verified against the supplied name.")

    if existing_kyc:
        existing_kyc.status = "verified"
        db.commit()
        db.refresh(existing_kyc)
        return existing_kyc

    kyc = KYC(
        user_id=user_id,
        bvn_hash=bvn_hash,
        status="verified",
    )
    db.add(kyc)
    db.commit()
    db.refresh(kyc)
    return kyc


def _build_statement_data() -> dict[str, Any]:
    """
    Generates synthetic month-on-month transaction data.
    Replace with a real third-party call in production.
    """
    months = ["2024-04", "2024-05", "2024-06"]
    month_rows: list[dict[str, float | str]] = []

    totals = {
        "debit": 0.0,
        "credit": 0.0,
        "debit_count": 0,
        "credit_count": 0,
        "balance": 0.0,
    }

    for month in months:
        td = float(random.randint(1_000, 500_000))
        tc = float(random.randint(0, 1_000_000))
        dc = random.randint(1, 20)
        cc = random.randint(0, 15)
        ab = round(random.uniform(0, 300_000), 2)

        totals["debit"] += td
        totals["credit"] += tc
        totals["debit_count"] += dc
        totals["credit_count"] += cc
        totals["balance"] += ab

        month_rows.append(
            {
                "totalDebit": td,
                "debitCount": float(dc),
                "totalCredit": tc,
                "creditCount": float(cc),
                "yearMonth": month,
                "averageBalance": ab,
            }
        )

    month_count = len(months)
    return {
        "monthOnMonth": month_rows,
        "averageValue": {
            "totalDebit": totals["debit"] / month_count,
            "debitCount": totals["debit_count"] / month_count,
            "totalCredit": totals["credit"] / month_count,
            "creditCount": totals["credit_count"] / month_count,
            "averageBalance": totals["balance"] / month_count,
        },
    }


def generate_bank_statement(db: Session, user_id: str) -> BankStatement:
    """
    Generate or regenerate the BankStatement for a verified user.
    Raises HTTP 403 if KYC is not complete.
    """
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "User not found.")

    kyc = db.query(KYC).filter(KYC.user_id == user_id).first()
    if not kyc:
        raise HTTPException(
            status.HTTP_403_FORBIDDEN,
            "KYC record not found. Complete BVN verification first.",
        )
    if not kyc.is_verified:
        raise HTTPException(
            status.HTTP_403_FORBIDDEN,
            "KYC not verified. Complete verification before generating a statement.",
        )

    now = datetime.now(timezone.utc)
    raw_data = _build_statement_data()
    avg = raw_data["averageValue"]

    existing = db.query(BankStatement).filter(BankStatement.user_id == user_id).first()
    if existing:
        existing.average_balance = avg["averageBalance"]
        existing.total_credit = avg["totalCredit"]
        existing.total_debit = avg["totalDebit"]
        existing.raw_data = raw_data["monthOnMonth"]
        existing.updated_at = now
        db.commit()
        db.refresh(existing)
        return existing

    statement = BankStatement(
        user_id=user_id,
        kyc_id=kyc.id,
        average_balance=avg["averageBalance"],
        total_credit=avg["totalCredit"],
        total_debit=avg["totalDebit"],
        raw_data=raw_data["monthOnMonth"],
        generated_at=now,
        updated_at=now,
    )
    db.add(statement)
    db.commit()
    db.refresh(statement)
    return statement
