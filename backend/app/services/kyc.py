"""
KYC service  —  two distinct responsibilities, two distinct functions:

  verify_bvn()            →  creates/updates the KYC record (identity layer)
  generate_bank_statement() →  creates/refreshes the BankStatement record (financial layer)

The two records share user_id + kyc_id as foreign keys but are otherwise
independent: you can regenerate a statement without touching KYC, and KYC
status changes don't cascade into statement data.
"""
import random
import uuid
from datetime import datetime, timezone
from typing import Any

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models.bank_statement import BankStatement
from app.models.kyc import KYC
from app.models.user import User
from app.utils.security import hash_bvn


# ── KYC (identity) ────────────────────────────────────────────────────────────

def verify_bvn(db: Session, user_id: str, bvn: str) -> KYC:
    """
    Hash and store a BVN, marking the user's KYC as verified.
    Raises ValueError for invalid input or duplicate BVN/user.
    """
    if not bvn.isdigit() or len(bvn) != 11:
        raise ValueError("BVN must be exactly 11 digits.")

    bvn_hash = hash_bvn(bvn)

    # Reject if this BVN is already tied to a *different* account
    existing_bvn = db.query(KYC).filter(KYC.bvn_hash == bvn_hash).first()
    if existing_bvn and existing_bvn.user_id != user_id:
        raise ValueError("BVN is already linked to another account.")

    # Reject if this user already has a *different* BVN verified
    existing_kyc = db.query(KYC).filter(KYC.user_id == user_id).first()
    if existing_kyc and existing_kyc.bvn_hash != bvn_hash:
        raise ValueError("User already has a different BVN linked.")

    if existing_kyc:
        # Idempotent re-verification (same BVN)
        existing_kyc.status = "verified"
        db.commit()
        db.refresh(existing_kyc)
        return existing_kyc

    kyc = KYC(
        user_id  = user_id,
        bvn_hash = bvn_hash,
        status   = "verified",
    )
    db.add(kyc)
    db.commit()
    db.refresh(kyc)
    return kyc


# ── Bank Statement (financial) ────────────────────────────────────────────────

def _build_statement_data() -> dict[str, Any]:
    """
    Generates synthetic month-on-month transaction data.
    Replace with a real third-party call (e.g. Mono, Okra, Stitch) in production.
    """
    months = ["2024-04", "2024-05", "2024-06"]
    month_rows: list[dict] = []

    totals = dict(debit=0.0, credit=0.0, debit_count=0, credit_count=0, balance=0.0)

    for month in months:
        td = float(random.randint(1_000,   500_000))
        tc = float(random.randint(0,     1_000_000))
        dc = random.randint(1, 20)
        cc = random.randint(0, 15)
        ab = round(random.uniform(0, 300_000), 2)

        totals["debit"]        += td
        totals["credit"]       += tc
        totals["debit_count"]  += dc
        totals["credit_count"] += cc
        totals["balance"]      += ab

        month_rows.append({
            "totalDebit":     td,
            "debitCount":     float(dc),
            "totalCredit":    tc,
            "creditCount":    float(cc),
            "yearMonth":      month,
            "averageBalance": ab,
        })

    n = len(months)
    return {
        "monthOnMonth": month_rows,
        "averageValue": {
            "totalDebit":     totals["debit"]        / n,
            "debitCount":     totals["debit_count"]  / n,
            "totalCredit":    totals["credit"]       / n,
            "creditCount":    totals["credit_count"] / n,
            "averageBalance": totals["balance"]      / n,
        },
    }


def generate_bank_statement(db: Session, user_id: str) -> BankStatement:
    """
    Generates (or regenerates) the BankStatement for a verified user.
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

    now  = datetime.now(timezone.utc)
    data = _build_statement_data()

    existing = db.query(BankStatement).filter(BankStatement.user_id == user_id).first()
    if existing:
        existing.data       = data
        existing.updated_at = now
        db.commit()
        db.refresh(existing)
        return existing

    statement = BankStatement(
        user_id      = user_id,
        kyc_id       = kyc.id,
        data         = data,
        generated_at = now,
        updated_at   = now,
    )
    db.add(statement)
    db.commit()
    db.refresh(statement)
    return statement