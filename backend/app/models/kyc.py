from sqlalchemy import Boolean, Column, String, JSON, ForeignKey
from sqlalchemy.orm import relationship
import uuid
from app.database import Base


class KYC(Base):
    __tablename__ = "kyc"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, unique=True)
    # unique=True added: one KYC record per user is already enforced in the
    # service layer, but the DB constraint makes it authoritative and prevents
    # race-condition duplicates.
    # ondelete="CASCADE" added: orphaned KYC rows were left behind when a user
    # was deleted because the original FK had no cascade rule.

    bvn_hash = Column(String, nullable=False, unique=True)

    verified = Column(String, nullable=False, default="false")
    # nullable=False added: "false" default is meaningless if the column can be NULL.
    # Consider migrating this to a Boolean column in a future revision.

    bank_statement = Column(JSON, nullable=True)

    user = relationship("User", back_populates="kyc")
    # back_populates added to keep the relationship bidirectional and consistent
    # with SQLAlchemy best practice. Requires adding `kyc` relationship to User.