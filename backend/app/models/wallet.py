import uuid
from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class Wallet(Base):
    """
    PR 2 scope: one wallet per user.
    Group wallets land in a later PR once the transfer/ledger model exists.
    """

    __tablename__ = "wallets"

    id: Mapped[str] = mapped_column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id: Mapped[str] = mapped_column(
        String,
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        unique=True,
        index=True,
    )
    provider: Mapped[str] = mapped_column(String, nullable=False, default="interswitch")
    provider_wallet_id: Mapped[str | None] = mapped_column(String, nullable=True, unique=True)
    provider_reference: Mapped[str | None] = mapped_column(String, nullable=True, unique=True)
    account_name: Mapped[str] = mapped_column(String, nullable=False)
    account_number: Mapped[str | None] = mapped_column(String, nullable=True, unique=True)
    bank_name: Mapped[str | None] = mapped_column(String, nullable=True)
    bank_code: Mapped[str | None] = mapped_column(String, nullable=True)
    status: Mapped[str] = mapped_column(String, nullable=False, default="pending")
    failure_reason: Mapped[str | None] = mapped_column(String, nullable=True)
    provisioned_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)

    user: Mapped["User"] = relationship("User", back_populates="wallet")

    @property
    def is_active(self) -> bool:
        return self.status == "active"
