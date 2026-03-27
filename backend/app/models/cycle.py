import uuid
from datetime import datetime
from sqlalchemy import DateTime, Float, ForeignKey, Integer, String, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.database import Base


class Cycle(Base):
    """One savings round for a group."""
    __tablename__ = "cycles"

    id: Mapped[str]                         = mapped_column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    group_id: Mapped[str]                   = mapped_column(String, ForeignKey("groups.id", ondelete="CASCADE"), nullable=False, index=True)
    # "active" | "completed" | "cancelled"
    status: Mapped[str]                     = mapped_column(String, nullable=False, default="active")
    frequency: Mapped[str]                  = mapped_column(String, nullable=False)  # "biweekly" | "monthly"
    max_reduction_pct: Mapped[float]        = mapped_column(Float, nullable=False, default=25.0)
    contribution_amount: Mapped[float]      = mapped_column(Float, nullable=False)
    started_at: Mapped[datetime]            = mapped_column(DateTime(timezone=True), nullable=False)
    completed_at: Mapped[datetime | None]   = mapped_column(DateTime(timezone=True), nullable=True)

    group: Mapped["Group"]                  = relationship("Group", back_populates="cycles")
    slots: Mapped[list["CycleSlot"]]        = relationship("CycleSlot", back_populates="cycle", cascade="all, delete-orphan", order_by="CycleSlot.position")


class CycleSlot(Base):
    """
    One member's position in a cycle.
    Each slot has a due date — on that date contributions are collected
    and the pool (minus insurance holdback) is paid to this member.
    """
    __tablename__ = "cycle_slots"

    id: Mapped[str]                                     = mapped_column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    cycle_id: Mapped[str]                               = mapped_column(String, ForeignKey("cycles.id", ondelete="CASCADE"), nullable=False, index=True)
    user_id: Mapped[str]                                = mapped_column(String, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    position: Mapped[int]                               = mapped_column(Integer, nullable=False)  # 1-based
    due_date: Mapped[datetime]                          = mapped_column(DateTime(timezone=True), nullable=False)
    reduction_pct: Mapped[float]                        = mapped_column(Float, nullable=False)
    insurance_amount: Mapped[float]                     = mapped_column(Float, nullable=False, default=0.0)
    payout_amount: Mapped[float]                        = mapped_column(Float, nullable=False)

    # "pending" | "paid" | "defaulted"
    status: Mapped[str]                                 = mapped_column(String, nullable=False, default="pending")
    paid_at: Mapped[datetime | None]                    = mapped_column(DateTime(timezone=True), nullable=True)

    cycle: Mapped["Cycle"]                              = relationship("Cycle", back_populates="slots")
    user: Mapped["User"]                                = relationship("User")
    contributions: Mapped[list["CycleContribution"]]    = relationship("CycleContribution", back_populates="slot", cascade="all, delete-orphan")

    __table_args__                                      = (
                                                            UniqueConstraint("cycle_id", "user_id", name="uq_cycle_slot_user"),
                                                            UniqueConstraint("cycle_id", "position", name="uq_cycle_slot_position"),
                                                        )


class CycleContribution(Base):
    """
    Records each member's contribution toward a specific slot's payout.
    One row per (slot, contributing_member).
    """
    __tablename__ = "cycle_contributions"

    id: Mapped[str]                     = mapped_column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    slot_id: Mapped[str]                = mapped_column(String, ForeignKey("cycle_slots.id", ondelete="CASCADE"), nullable=False, index=True)
    contributor_id: Mapped[str]         = mapped_column(String, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    amount: Mapped[float]               = mapped_column(Float, nullable=False)
    # "collected" | "defaulted" | "insurance_used"
    status: Mapped[str]                 = mapped_column(String, nullable=False, default="collected")
    collected_at: Mapped[datetime]      = mapped_column(DateTime(timezone=True), nullable=False)

    slot: Mapped["CycleSlot"]           = relationship("CycleSlot", back_populates="contributions")
    contributor: Mapped["User"]         = relationship("User")

    __table_args__ = (
        UniqueConstraint("slot_id", "contributor_id", name="uq_contribution_slot_member"),
    )


class InsuranceWallet(Base):
    """
    Per-user-per-cycle insurance pot.
    Funded by the holdback on their payout. Returned at cycle end if no default.
    """
    __tablename__ = "insurance_wallets"

    id: Mapped[str] = mapped_column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    cycle_id: Mapped[str] = mapped_column(
        String, ForeignKey("cycles.id", ondelete="CASCADE"), nullable=False, index=True
    )
    user_id: Mapped[str] = mapped_column(
        String, ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    balance: Mapped[float] = mapped_column(Float, nullable=False, default=0.0)
    # "holding" | "returned" | "forfeited"
    status: Mapped[str] = mapped_column(String, nullable=False, default="holding")

    __table_args__ = (
        UniqueConstraint("cycle_id", "user_id", name="uq_insurance_cycle_user"),
    )