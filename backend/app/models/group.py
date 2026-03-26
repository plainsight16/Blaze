from sqlalchemy import (
    Column, DateTime, ForeignKey, String, Boolean,
    UniqueConstraint, Numeric, Integer, Date, CheckConstraint
)
from sqlalchemy.orm import relationship
from app.database import Base


class Group(Base):
    """
    Ajo savings group model.

    Lifecycle:
    - open: Accepting members, not yet started
    - active: Contributions in progress
    - completed: All cycles finished, payouts done

    Visibility:
    - public: Discoverable, requires eligibility assessment + admin approval
    - private: Hidden, join via invite link only (no assessment)
    """
    __tablename__ = "groups"

    # -------------------------------------------------------------------------
    # Identity
    # -------------------------------------------------------------------------
    id          = Column(String, primary_key=True)
    name        = Column(String(100), unique=True, nullable=False, index=True)
    description = Column(String(500), nullable=True)

    # -------------------------------------------------------------------------
    # Visibility & Status
    # -------------------------------------------------------------------------
    type        = Column(String(10), nullable=False, default="public")  # public | private
    status      = Column(String(15), nullable=False, default="open")    # open | active | completed
    is_active   = Column(Boolean, nullable=False, default=True)

    # -------------------------------------------------------------------------
    # Ownership
    # -------------------------------------------------------------------------
    owner_id    = Column(
        String,
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True,
        index=True
    )

    # -------------------------------------------------------------------------
    # Contribution Configuration
    # -------------------------------------------------------------------------
    contribution_amount = Column(Numeric(12, 2), nullable=True)  # ₦500 - ₦1,000,000
    frequency           = Column(String(10), nullable=True)       # daily | weekly | monthly
    cycle_length        = Column(Integer, nullable=True)          # Number of members (2-30)
    max_members         = Column(Integer, nullable=True)          # Max participants
    start_date          = Column(Date, nullable=True)
    current_cycle       = Column(Integer, nullable=False, default=0)
    current_position    = Column(Integer, nullable=False, default=1)  # Who gets next payout

    # -------------------------------------------------------------------------
    # Interswitch Wallet
    # -------------------------------------------------------------------------
    isw_wallet_id         = Column(String(50), nullable=True, index=True)
    isw_merchant_code     = Column(String(20), nullable=True)
    isw_virtual_acct_no   = Column(String(20), nullable=True)  # Wema Bank virtual account
    isw_virtual_acct_bank = Column(String(50), nullable=True)
    wallet_pin_encrypted  = Column(String(255), nullable=True)  # AES-256, system-generated

    # -------------------------------------------------------------------------
    # Timestamps
    # -------------------------------------------------------------------------
    created_at  = Column(DateTime(timezone=True), nullable=False)

    # -------------------------------------------------------------------------
    # Relationships
    # -------------------------------------------------------------------------
    memberships = relationship("UserGroup", back_populates="group", cascade="all, delete-orphan")
    requests    = relationship("GroupRequest", back_populates="group", cascade="all, delete-orphan")

    wallet_transactions = relationship(
        "WalletTransaction",
        primaryjoin="and_(Group.id == foreign(WalletTransaction.wallet_owner_id), "
                    "WalletTransaction.wallet_owner_type == 'group')",
        viewonly=True
    )

    # -------------------------------------------------------------------------
    # Constraints
    # -------------------------------------------------------------------------
    __table_args__ = (
        CheckConstraint(
            "contribution_amount IS NULL OR (contribution_amount >= 500 AND contribution_amount <= 1000000)",
            name="ck_contribution_amount_range"
        ),
        CheckConstraint(
            "cycle_length IS NULL OR (cycle_length >= 2 AND cycle_length <= 30)",
            name="ck_cycle_length_range"
        ),
        CheckConstraint(
            "frequency IS NULL OR frequency IN ('daily', 'weekly', 'monthly')",
            name="ck_frequency_values"
        ),
        CheckConstraint(
            "type IN ('public', 'private')",
            name="ck_group_type_values"
        ),
        CheckConstraint(
            "status IN ('open', 'active', 'completed')",
            name="ck_group_status_values"
        ),
    )

    # -------------------------------------------------------------------------
    # Helper Properties
    # -------------------------------------------------------------------------
    @property
    def has_wallet(self) -> bool:
        return self.isw_wallet_id is not None

    @property
    def is_configured(self) -> bool:
        """Check if contribution settings are configured."""
        return all([
            self.contribution_amount is not None,
            self.frequency is not None,
            self.cycle_length is not None,
            self.start_date is not None
        ])


class UserGroup(Base):
    __tablename__ = "user_groups"

    user_id   = Column(String, ForeignKey("users.id",  ondelete="CASCADE"), primary_key=True)
    group_id  = Column(String, ForeignKey("groups.id", ondelete="CASCADE"), primary_key=True)
    role      = Column(String, nullable=False, default="member")  # "member" | "admin"
    joined_at = Column(DateTime(timezone=True), nullable=False)

    group = relationship("Group", back_populates="memberships")


class GroupRequest(Base):
    __tablename__ = "group_requests"

    id           = Column(String,  primary_key=True)
    group_id     = Column(String,  ForeignKey("groups.id", ondelete="CASCADE"), nullable=False, index=True)
    user_id      = Column(String,  ForeignKey("users.id",  ondelete="CASCADE"), nullable=False, index=True)
    initiated_by = Column(String,  ForeignKey("users.id",  ondelete="CASCADE"), nullable=False)
    direction    = Column(String,  nullable=False)   # "join_request" | "invite"
    status       = Column(String,  nullable=False, default="pending")  # "pending" | "approved" | "rejected" | "accepted" | "declined"
    created_at   = Column(DateTime(timezone=True), nullable=False)
    resolved_at  = Column(DateTime(timezone=True), nullable=True)

    group = relationship("Group", back_populates="requests")

    __table_args__ = (
        UniqueConstraint("group_id", "user_id", name="uq_group_request_pair"),
    )