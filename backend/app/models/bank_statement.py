"""
BankStatement — separated from KYC so that:
  - KYC (identity verification) and financial data have distinct lifecycles.
  - The statement can be regenerated without touching the KYC record.
  - Queries that only need KYC status don't pay the cost of loading JSON.
"""
import uuid
from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, JSON, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class BankStatement(Base):
    __tablename__ = "bank_statements"

    id:         Mapped[str]          = mapped_column(String, primary_key=True, default=lambda: str(uuid.uuid4()))

    # One statement per user — enforced at DB level
    user_id:    Mapped[str]          = mapped_column(String, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, unique=True, index=True)
    kyc_id:     Mapped[str]          = mapped_column(String, ForeignKey("kyc.id",   ondelete="CASCADE"), nullable=False, unique=True)

    # JSON shape: { monthOnMonth: [...], averageValue: {...} }
    data:       Mapped[dict]         = mapped_column(JSON, nullable=False)

    generated_at: Mapped[datetime]   = mapped_column(DateTime(timezone=True), nullable=False)
    updated_at:   Mapped[datetime]   = mapped_column(DateTime(timezone=True), nullable=False)

    user: Mapped["User"]  = relationship("User", back_populates="bank_statement")
    kyc:  Mapped["KYC"]   = relationship("KYC",  back_populates="bank_statement")