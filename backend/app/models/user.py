import uuid
from datetime import datetime

from sqlalchemy import Boolean, DateTime, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class User(Base):
    __tablename__ = "users"

    id:            Mapped[str]            = mapped_column(String,  primary_key=True, default=lambda: str(uuid.uuid4()))
    email:         Mapped[str]            = mapped_column(String,  unique=True,  nullable=False, index=True)
    username:      Mapped[str]            = mapped_column(String,  unique=True,  nullable=False)
    first_name:    Mapped[str]            = mapped_column(String,  nullable=False)
    last_name:     Mapped[str]            = mapped_column(String,  nullable=False)
    password_hash: Mapped[str]            = mapped_column(String,  nullable=False)
    is_active:     Mapped[bool]           = mapped_column(Boolean, nullable=False, default=True)
    verified_at:   Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    created_at:    Mapped[datetime]       = mapped_column(DateTime(timezone=True), nullable=False)

    # Relationships (back-populated from child tables)
    kyc:           Mapped["KYC | None"]           = relationship("KYC",          back_populates="user", uselist=False)
    bank_statement: Mapped["BankStatement | None"] = relationship("BankStatement", back_populates="user", uselist=False)