"""
Wallet transaction models for audit logging.

All wallet operations are logged as immutable records for:
- Compliance and audit trails
- Transaction reconciliation with Interswitch
- Dispute resolution
- Analytics and reporting
"""
from sqlalchemy import (
    Column, DateTime, String, Numeric, Index, CheckConstraint
)
from app.database import Base


class WalletTransaction(Base):
    """
    Immutable audit log of all wallet operations.

    Transaction Types:
    - debit: Money out of wallet
    - credit: Money into wallet
    - reversal: Undo a previous transaction

    Statuses:
    - pending: Transaction initiated, awaiting ISW response
    - completed: Successfully processed by ISW
    - failed: ISW rejected the transaction
    - reversed: Transaction was reversed
    """
    __tablename__ = "wallet_transactions"

    # -------------------------------------------------------------------------
    # Primary Key
    # -------------------------------------------------------------------------
    id = Column(String, primary_key=True)

    # -------------------------------------------------------------------------
    # Wallet Owner (polymorphic: user or group)
    # -------------------------------------------------------------------------
    wallet_owner_type = Column(String(10), nullable=False)  # user | group
    wallet_owner_id   = Column(String, nullable=False, index=True)

    # -------------------------------------------------------------------------
    # Transaction Details
    # -------------------------------------------------------------------------
    transaction_type = Column(String(20), nullable=False)   # debit | credit | reversal
    amount           = Column(Numeric(12, 2), nullable=False)
    currency         = Column(String(3), nullable=False, default="NGN")

    # -------------------------------------------------------------------------
    # Counterparty (who is on the other side of this transaction)
    # -------------------------------------------------------------------------
    counterparty_type = Column(String(10), nullable=True)   # user | group | bank | external
    counterparty_id   = Column(String, nullable=True)

    # -------------------------------------------------------------------------
    # Interswitch References
    # -------------------------------------------------------------------------
    isw_reference     = Column(String(100), nullable=True, index=True)
    isw_response_code = Column(String(10), nullable=True)
    isw_response_msg  = Column(String(255), nullable=True)

    # -------------------------------------------------------------------------
    # Context
    # -------------------------------------------------------------------------
    description     = Column(String(255), nullable=True)
    narration       = Column(String(255), nullable=True)
    transaction_ref = Column(String(100), nullable=True, unique=True)  # Our internal reference

    # -------------------------------------------------------------------------
    # Status & Timestamps
    # -------------------------------------------------------------------------
    status     = Column(String(15), nullable=False, default="pending")
    created_at = Column(DateTime(timezone=True), nullable=False)
    updated_at = Column(DateTime(timezone=True), nullable=True)

    # -------------------------------------------------------------------------
    # Linked Transactions (for reversals)
    # -------------------------------------------------------------------------
    original_transaction_id = Column(String, nullable=True)  # Points to reversed tx

    # -------------------------------------------------------------------------
    # Constraints
    # -------------------------------------------------------------------------
    __table_args__ = (
        Index("ix_wallet_tx_owner", "wallet_owner_type", "wallet_owner_id"),
        Index("ix_wallet_tx_status_created", "status", "created_at"),
        CheckConstraint(
            "wallet_owner_type IN ('user', 'group')",
            name="ck_wallet_owner_type"
        ),
        CheckConstraint(
            "transaction_type IN ('debit', 'credit', 'reversal')",
            name="ck_transaction_type"
        ),
        CheckConstraint(
            "status IN ('pending', 'completed', 'failed', 'reversed')",
            name="ck_transaction_status"
        ),
        CheckConstraint(
            "amount > 0",
            name="ck_positive_amount"
        ),
    )

    def __repr__(self) -> str:
        return (
            f"<WalletTransaction("
            f"id={self.id!r}, "
            f"type={self.transaction_type!r}, "
            f"amount={self.amount}, "
            f"status={self.status!r}"
            f")>"
        )
