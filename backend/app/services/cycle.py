# app/services/cycle.py
import random
from datetime import datetime, timezone, timedelta
from typing import TYPE_CHECKING

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models.cycle import Cycle, CycleSlot, CycleContribution, InsuranceWallet
from app.models.group import Group, UserGroup
from app.models.wallet import Wallet
from app.models.user import User
from app.services.wallet import get_wallet_by_user_id, get_wallet_by_group_id, fund_wallet


def _utcnow() -> datetime:
    return datetime.now(timezone.utc)


def _compute_reduction_pct(position: int, n_members: int, max_pct: float) -> float:
    """
    Linear decay: position 1 gets max_pct, last position gets 0%.
    position is 1-based.
    """
    if n_members == 1:
        return 0.0
    return max_pct * (n_members - position) / (n_members - 1)


def _next_due_date(from_dt: datetime, frequency: str) -> datetime:
    if frequency == "biweekly":
        return from_dt + timedelta(weeks=2)
    return from_dt + timedelta(days=30)


def _get_active_members(group_id: str, db: Session) -> list[UserGroup]:
    return (
        db.query(UserGroup)
        .filter(
            UserGroup.group_id == group_id,
            UserGroup.is_frozen == False,  # noqa: E712
        )
        .all()
    )


def _get_insurance_wallet(cycle_id: str, user_id: str, db: Session) -> InsuranceWallet | None:
    return db.query(InsuranceWallet).filter(
        InsuranceWallet.cycle_id == cycle_id,
        InsuranceWallet.user_id == user_id,
    ).first()


def _debit_wallet(wallet: Wallet, amount: float, db: Session) -> bool:
    """Attempt to debit a wallet. Returns True on success, False if insufficient funds."""
    if (wallet.amount or 0.0) < amount:
        return False
    wallet.amount = (wallet.amount or 0.0) - amount
    wallet.updated_at = _utcnow()
    return True


# -- Start cycle ---------------------------------------------------------------

def start_cycle(
    db: Session,
    group: Group,
    actor: User,
    frequency: str,
    max_reduction_pct: float,
) -> Cycle:
    # Only one active cycle per group
    existing = db.query(Cycle).filter(
        Cycle.group_id == group.id,
        Cycle.status == "active",
    ).first()
    if existing:
        raise HTTPException(status.HTTP_409_CONFLICT, "Group already has an active cycle.")

    members = _get_active_members(group.id, db)
    if len(members) < 2:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            "A cycle requires at least 2 active members."
        )

    # Shuffle for random payout order
    random.shuffle(members)
    n = len(members)
    now = _utcnow()

    cycle = Cycle(
        group_id=group.id,
        status="active",
        frequency=frequency,
        max_reduction_pct=max_reduction_pct,
        contribution_amount=float(group.monthly_con),
        started_at=now,
    )
    db.add(cycle)
    db.flush()  # get cycle.id

    # Build slots
    due = _next_due_date(now, frequency)
    for i, membership in enumerate(members):
        position = i + 1
        reduction_pct = _compute_reduction_pct(position, n, max_reduction_pct)
        full_pool = group.monthly_con * n
        insurance_amount = round(full_pool * reduction_pct / 100, 2)
        payout_amount = round(full_pool - insurance_amount, 2)

        slot = CycleSlot(
            cycle_id=cycle.id,
            user_id=membership.user_id,
            position=position,
            due_date=due,
            reduction_pct=reduction_pct,
            insurance_amount=insurance_amount,
            payout_amount=payout_amount,
            status="pending",
        )
        db.add(slot)

        # Pre-create insurance wallet for every member with holdback > 0
        if insurance_amount > 0:
            db.add(InsuranceWallet(
                cycle_id=cycle.id,
                user_id=membership.user_id,
                balance=0.0,
                status="holding",
            ))

        due = _next_due_date(due, frequency)

    db.commit()
    db.refresh(cycle)
    return cycle


# -- Process due slot ----------------------------------------------------------

def process_due_slot(db: Session, slot: CycleSlot) -> None:
    if slot.status != "pending":
        return

    cycle = db.query(Cycle).filter(Cycle.id == slot.cycle_id).first()
    if not cycle or cycle.status != "active":
        return

    active_memberships = _get_active_members(cycle.group_id, db)
    active_user_ids = {m.user_id for m in active_memberships}

    if slot.user_id not in active_user_ids:
        slot.status = "defaulted"
        db.commit()
        _check_cycle_completion(db, cycle)
        return

    now = _utcnow()
    contribution_amount = cycle.contribution_amount
    collected_total = 0.0

    group_wallet = get_wallet_by_group_id(cycle.group_id, db)
    if not group_wallet:
        raise HTTPException(status.HTTP_500_INTERNAL_SERVER_ERROR, "Group wallet not found.")

    # ── Phase 1: collect from every active member into group wallet ────────────
    for membership in active_memberships:
        already = db.query(CycleContribution).filter(
            CycleContribution.slot_id == slot.id,
            CycleContribution.contributor_id == membership.user_id,
        ).first()
        if already:
            collected_total += already.amount if already.status == "collected" else 0.0
            continue

        member_wallet = get_wallet_by_user_id(membership.user_id, db)

        if member_wallet and _debit_wallet(member_wallet, contribution_amount, db):
            # Member wallet → group wallet
            group_wallet.amount = (group_wallet.amount or 0.0) + contribution_amount
            group_wallet.updated_at = now

            # Debit transaction on member wallet
            db.add(Transaction(
                wallet_id=member_wallet.id,
                type="debit",
                amount=contribution_amount,
                reference=f"cycle:{cycle.id}:slot:{slot.id}:contrib:{membership.user_id}",
                description=f"Cycle contribution — slot {slot.position}",
                status="success",
                created_at=now,
            ))
            # Credit transaction on group wallet
            db.add(Transaction(
                wallet_id=group_wallet.id,
                type="credit",
                amount=contribution_amount,
                reference=f"cycle:{cycle.id}:slot:{slot.id}:collected:{membership.user_id}",
                description=f"Contribution received from member for slot {slot.position}",
                status="success",
                created_at=now,
            ))

            db.add(CycleContribution(
                slot_id=slot.id,
                contributor_id=membership.user_id,
                amount=contribution_amount,
                status="collected",
                collected_at=now,
            ))
            collected_total += contribution_amount

        else:
            # Default — freeze and attempt insurance cover
            _freeze_member(
                db.query(UserGroup).filter(
                    UserGroup.user_id == membership.user_id,
                    UserGroup.group_id == cycle.group_id,
                ).first(),
                cycle.id,
                db,
            )
            active_user_ids.discard(membership.user_id)

            insurance = _get_insurance_wallet(cycle.id, membership.user_id, db)
            covered = 0.0

            if insurance and insurance.balance > 0:
                covered = min(insurance.balance, contribution_amount)
                insurance.balance -= covered
                insurance.status = "forfeited"

                # Insurance wallet → group wallet
                group_wallet.amount = (group_wallet.amount or 0.0) + covered
                group_wallet.updated_at = now

                db.add(Transaction(
                    wallet_id=group_wallet.id,
                    type="credit",
                    amount=covered,
                    reference=f"cycle:{cycle.id}:slot:{slot.id}:insurance:{membership.user_id}",
                    description=f"Insurance cover for defaulted member slot {slot.position}",
                    status="success",
                    created_at=now,
                ))

            db.add(CycleContribution(
                slot_id=slot.id,
                contributor_id=membership.user_id,
                amount=covered,
                status="insurance_used" if covered > 0 else "defaulted",
                collected_at=now,
            ))
            collected_total += covered

    # ── Phase 2: disburse from group wallet to recipient ──────────────────────
    insurance_holdback = slot.insurance_amount
    actual_payout = max(0.0, collected_total - insurance_holdback)

    recipient_wallet = get_wallet_by_user_id(slot.user_id, db)
    if recipient_wallet and actual_payout > 0:
        # Debit group wallet
        group_wallet.amount = (group_wallet.amount or 0.0) - actual_payout
        group_wallet.updated_at = now

        db.add(Transaction(
            wallet_id=group_wallet.id,
            type="debit",
            amount=actual_payout,
            reference=f"cycle:{cycle.id}:slot:{slot.id}:payout",
            description=f"Payout disbursed to slot {slot.position} recipient",
            status="success",
            created_at=now,
        ))

        # Credit recipient wallet
        recipient_wallet.amount = (recipient_wallet.amount or 0.0) + actual_payout
        recipient_wallet.updated_at = now

        db.add(Transaction(
            wallet_id=recipient_wallet.id,
            type="credit",
            amount=actual_payout,
            reference=f"cycle:{cycle.id}:slot:{slot.id}:payout:received",
            description=f"Cycle payout received — position {slot.position}",
            status="success",
            created_at=now,
        ))

    # ── Phase 3: holdback stays in group wallet until routed to insurance ──────
    if insurance_holdback > 0:
        insurance = _get_insurance_wallet(cycle.id, slot.user_id, db)
        if not insurance:
            insurance = InsuranceWallet(
                cycle_id=cycle.id,
                user_id=slot.user_id,
                balance=0.0,
                status="holding",
            )
            db.add(insurance)

        # Debit group wallet for the holdback
        group_wallet.amount = (group_wallet.amount or 0.0) - insurance_holdback
        group_wallet.updated_at = now

        db.add(Transaction(
            wallet_id=group_wallet.id,
            type="debit",
            amount=insurance_holdback,
            reference=f"cycle:{cycle.id}:slot:{slot.id}:insurance:holdback",
            description=f"Insurance holdback for slot {slot.position} recipient",
            status="success",
            created_at=now,
        ))

        insurance.balance += insurance_holdback

    slot.status = "paid"
    slot.paid_at = now
    slot.payout_amount = actual_payout
    db.commit()

    _check_cycle_completion(db, cycle)

def _freeze_member(membership: UserGroup, cycle_id: str, db: Session) -> None:
    membership.is_frozen = True
    membership.frozen_until_cycle_id = cycle_id


def _check_cycle_completion(db: Session, cycle: Cycle) -> None:
    slots = db.query(CycleSlot).filter(CycleSlot.cycle_id == cycle.id).all()
    if any(s.status == "pending" for s in slots):
        return

    now = _utcnow()
    group_wallet = get_wallet_by_group_id(cycle.group_id, db)

    insurance_wallets = db.query(InsuranceWallet).filter(
        InsuranceWallet.cycle_id == cycle.id,
        InsuranceWallet.status == "holding",
    ).all()

    for iw in insurance_wallets:
        if iw.balance <= 0:
            continue

        user_wallet = get_wallet_by_user_id(iw.user_id, db)
        amount = iw.balance

        if group_wallet:
            # Debit group wallet
            group_wallet.amount = (group_wallet.amount or 0.0) - amount
            group_wallet.updated_at = now

            db.add(Transaction(
                wallet_id=group_wallet.id,
                type="debit",
                amount=amount,
                reference=f"cycle:{cycle.id}:insurance:return:{iw.user_id}",
                description="Insurance returned to member at cycle completion",
                status="success",
                created_at=now,
            ))

        if user_wallet:
            user_wallet.amount = (user_wallet.amount or 0.0) + amount
            user_wallet.updated_at = now

            db.add(Transaction(
                wallet_id=user_wallet.id,
                type="credit",
                amount=amount,
                reference=f"cycle:{cycle.id}:insurance:return:received:{iw.user_id}",
                description="Insurance holdback returned — cycle completed",
                status="success",
                created_at=now,
            ))

        iw.status = "returned"
        iw.balance = 0.0

    cycle.status = "completed"
    cycle.completed_at = now

    db.query(UserGroup).filter(
        UserGroup.frozen_until_cycle_id == cycle.id
    ).update({"is_frozen": False, "frozen_until_cycle_id": None})

    db.commit()

# -- Scheduler entry point -----------------------------------------------------

def process_all_due_slots(db: Session) -> None:
    """
    Run this on a schedule (e.g. every hour or daily).
    Finds all pending slots whose due_date has passed and processes them.
    """
    now = _utcnow()
    due_slots = (
        db.query(CycleSlot)
        .join(Cycle, Cycle.id == CycleSlot.cycle_id)
        .filter(
            CycleSlot.status == "pending",
            CycleSlot.due_date <= now,
            Cycle.status == "active",
        )
        .order_by(CycleSlot.due_date.asc())
        .all()
    )
    for slot in due_slots:
        try:
            process_due_slot(db, slot)
        except Exception:
            # Log and continue — one bad slot shouldn't block others
            db.rollback()
            continue


# -- Queries -------------------------------------------------------------------

def get_active_cycle(group_id: str, db: Session) -> Cycle | None:
    return db.query(Cycle).filter(
        Cycle.group_id == group_id,
        Cycle.status == "active",
    ).first()


def get_cycle_by_id(cycle_id: str, db: Session) -> Cycle | None:
    return db.query(Cycle).filter(Cycle.id == cycle_id).first()


def get_user_insurance_wallet(cycle_id: str, user_id: str, db: Session) -> InsuranceWallet | None:
    return _get_insurance_wallet(cycle_id, user_id, db)