"""
KYC service.

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
from app.models.wallet import Wallet
from app.schemas.kyc import KYCRequirementsResponse, KYCStatusResponse
from app.services.interswitch import verify_bvn_boolean_match
from app.services.wallet import get_wallet_by_user_id, get_wallet_status_value, provision_user_wallet
from app.utils.security import hash_bvn


def _derive_next_step(*, bvn_verified: bool, wallet_status: str) -> str:
    if not bvn_verified:
        return "verify_bvn"
    if wallet_status == "active":
        return "completed"
    if wallet_status == "failed":
        return "retry_wallet_provisioning"
    return "provision_wallet"


def _build_kyc_status_response(kyc: KYC | None, wallet: Wallet | None) -> KYCStatusResponse:
    bvn_verified = bool(kyc and kyc.is_verified)
    wallet_status = get_wallet_status_value(wallet)
    return KYCStatusResponse(
        kyc_id=kyc.id if kyc else None,
        wallet_id=wallet.id if wallet else None,
        status=kyc.status if kyc else "not_started",
        bvn_verified=bvn_verified,
        wallet_provisioned=bool(wallet and wallet.is_active),
        wallet_status=wallet_status,
        next_step=_derive_next_step(bvn_verified=bvn_verified, wallet_status=wallet_status),
    )


def get_kyc_status(user_id: str, db: Session) -> KYCStatusResponse:
    kyc = db.query(KYC).filter(KYC.user_id == user_id).first()
    wallet = get_wallet_by_user_id(user_id, db)
    return _build_kyc_status_response(kyc, wallet)


def get_kyc_requirements(user_id: str, db: Session) -> KYCRequirementsResponse:
    snapshot = get_kyc_status(user_id, db)
    if snapshot.next_step == "completed":
        return KYCRequirementsResponse(
            bvn_required=False,
            bvn_verified=True,
            wallet_required=False,
            wallet_provisioned=True,
            wallet_status=snapshot.wallet_status,
            next_step="completed",
        )

    if snapshot.next_step == "verify_bvn":
        return KYCRequirementsResponse(
            bvn_required=True,
            bvn_verified=False,
            wallet_required=False,
            wallet_provisioned=False,
            wallet_status=snapshot.wallet_status,
            next_step="verify_bvn",
            banner_title="Complete your KYC",
            banner_message="Verify your BVN to complete identity verification.",
        )

    if snapshot.next_step == "retry_wallet_provisioning":
        return KYCRequirementsResponse(
            bvn_required=False,
            bvn_verified=True,
            wallet_required=True,
            wallet_provisioned=False,
            wallet_status=snapshot.wallet_status,
            next_step="retry_wallet_provisioning",
            banner_title="Finish wallet setup",
            banner_message="Your BVN is verified, but wallet provisioning needs a retry.",
        )

    return KYCRequirementsResponse(
        bvn_required=False,
        bvn_verified=True,
        wallet_required=True,
        wallet_provisioned=False,
        wallet_status=snapshot.wallet_status,
        next_step="provision_wallet",
        banner_title="Finish wallet setup",
        banner_message="Your wallet is being provisioned or still needs to be created.",
    )


def verify_bvn(db: Session, user: User, bvn: str) -> tuple[KYC, Wallet]:
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
        wallet = provision_user_wallet(db, user, raise_on_failure=False)
        return existing_kyc, wallet

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
        wallet = provision_user_wallet(db, user, raise_on_failure=False)
        return existing_kyc, wallet

    kyc = KYC(
        user_id=user_id,
        bvn_hash=bvn_hash,
        status="verified",
    )
    db.add(kyc)
    db.commit()
    db.refresh(kyc)
    wallet = provision_user_wallet(db, user, raise_on_failure=False)
    return kyc, wallet


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
