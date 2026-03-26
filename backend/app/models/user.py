from sqlalchemy import Boolean, Column, DateTime, String
from sqlalchemy.orm import relationship
from app.database import Base


class User(Base):
    __tablename__ = "users"

    id            = Column(String,  primary_key=True)
    email         = Column(String,  unique=True,  nullable=False, index=True)
    username      = Column(String,  unique=True,  nullable=False)
    first_name    = Column(String,  nullable=False)
    last_name     = Column(String,  nullable=False)
    password_hash = Column(String,  nullable=False)
    is_active     = Column(Boolean, nullable=False, default=True)
    verified_at   = Column(DateTime(timezone=True), nullable=True)
    created_at    = Column(DateTime(timezone=True), nullable=False)

    kyc = relationship("KYC", back_populates="user", uselist=False)
    # Added bidirectional side of the KYC relationship.
    # uselist=False because it's a one-to-one relation.