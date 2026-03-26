import uuid

from sqlalchemy import ForeignKey, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class KYC(Base):
    """
    Stores BVN verification state for a user.
    Bank statement data lives in its own BankStatement table (one-to-one via user_id).
    """
    __tablename__ = "kyc"

    id:       Mapped[str]  = mapped_column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id:  Mapped[str]  = mapped_column(String, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, unique=True, index=True)
    bvn_hash: Mapped[str]  = mapped_column(String, nullable=False, unique=True)

    # "pending" | "verified" | "failed"
    status:   Mapped[str]  = mapped_column(String, nullable=False, default="pending")

    user:     Mapped["User"]           = relationship("User",          back_populates="kyc")
    bank_statement: Mapped["BankStatement | None"] = relationship("BankStatement", back_populates="kyc", uselist=False)

    @property
    def is_verified(self) -> bool:
        return self.status == "verified"