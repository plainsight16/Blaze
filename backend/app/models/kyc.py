# models/kyc.py

from sqlalchemy import Column, String, JSON, ForeignKey
from sqlalchemy.orm import relationship
import uuid
from app.database import Base


class KYC(Base):
    __tablename__ = "kyc"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String, ForeignKey("users.id"), nullable=False)

    bvn_hash = Column(String, nullable=False, unique=True)

    verified = Column(String, default="false")

    bank_statement = Column(JSON, nullable=True)

    user = relationship("User")