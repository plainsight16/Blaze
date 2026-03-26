"""
BankStatement — separated from KYC so that:
  - KYC (identity verification) and financial data have distinct lifecycles.
  - The statement can be regenerated without touching the KYC record.
  - Queries that only need eligibility (average_balance) hit a real indexed
    column — no JSON traversal, no try/except, no malformed-data surprises.

Column strategy
───────────────
Aggregates that the application reasons about (average_balance, total_credit,
total_debit) are proper typed columns.  The month-on-month rows are genuinely
variable-length array data with no fixed cardinality, so they stay in JSONB —
but as raw_data, explicitly named to signal "read-only archive, not logic".
"""
import uuid
from datetime import datetime

from sqlalchemy import DateTime, Float, ForeignKey, JSON, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base



class BankStatement(Base):
    __tablename__ = "bank_statements"

    id:      Mapped[str] = mapped_column(String, primary_key=True, default=lambda: str(uuid.uuid4()))

    # One statement per user — enforced at DB level
    user_id: Mapped[str] = mapped_column(String, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, unique=True, index=True)
    kyc_id:  Mapped[str] = mapped_column(String, ForeignKey("kyc.id",   ondelete="CASCADE"), nullable=False, unique=True)

    # ── Queryable aggregates (extracted from averageValue) ────────────────────
    # These are the values the application actually reasons about.
    # Storing them as real columns means: typed, indexable, no dict traversal.
    average_balance: Mapped[float] = mapped_column(Float, nullable=False)
    total_credit:    Mapped[float] = mapped_column(Float, nullable=False)
    total_debit:     Mapped[float] = mapped_column(Float, nullable=False)

    # ── Raw archive ───────────────────────────────────────────────────────────
    # Month-on-month rows: variable-length, never queried by column — JSONB is
    # the right tool here.  Shape: [ { yearMonth, totalDebit, totalCredit,
    # debitCount, creditCount, averageBalance }, ... ]
    raw_data: Mapped[dict] = mapped_column(JSON, nullable=False)

    generated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    updated_at:   Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)

    user: Mapped["User"] = relationship("User", back_populates="bank_statement")
    kyc:  Mapped["KYC"]  = relationship("KYC",  back_populates="bank_statement")