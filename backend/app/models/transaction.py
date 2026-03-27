import uuid
from datetime import datetime
from sqlalchemy import DateTime, Float, ForeignKey, String
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.database import Base

class Transaction(Base):
    __tablename__ = "transactions"

    id: Mapped[str] = mapped_column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    wallet_id: Mapped[str] = mapped_column(
        String, ForeignKey("wallets.id", ondelete="CASCADE"),
        nullable=False, index=True
    )
    type: Mapped[str] = mapped_column(String, nullable=False)  # "credit" | "debit"
    amount: Mapped[float] = mapped_column(Float, nullable=False)
    reference: Mapped[str] = mapped_column(String, nullable=False, unique=True)  # idempotency key
    description: Mapped[str | None] = mapped_column(String, nullable=True)
    status: Mapped[str] = mapped_column(String, nullable=False, default="success")
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)

    wallet: Mapped["Wallet"] = relationship("Wallet", back_populates="transactions")