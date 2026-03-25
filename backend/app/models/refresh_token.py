from sqlalchemy import Boolean, Column, DateTime, ForeignKey, String
from app.database import Base


class RefreshToken(Base):
    __tablename__ = "refresh_tokens"

    id         = Column(String,  primary_key=True)
    user_id    = Column(String,  ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    token_hash = Column(String,  nullable=False, unique=True)
    expires_at = Column(DateTime(timezone=True), nullable=False)
    revoked    = Column(Boolean, nullable=False, default=False)
    created_at = Column(DateTime(timezone=True), nullable=False)
