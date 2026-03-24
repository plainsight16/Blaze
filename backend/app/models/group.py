import uuid
from datetime import datetime, timezone

from sqlalchemy import Boolean, Column, DateTime, ForeignKey, String, UniqueConstraint
from sqlalchemy.orm import relationship

from app.database import Base


class Group(Base):
    __tablename__ = "groups"

    id          = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    name        = Column(String, unique=True, nullable=False, index=True)
    description = Column(String, nullable=True)
    owner_id    = Column(String, ForeignKey("users.id", ondelete="SET NULL"), nullable=True, index=True)
    is_active   = Column(Boolean, nullable=False, default=True)
    created_at  = Column(DateTime(timezone=True), nullable=False)

    memberships = relationship("UserGroup", back_populates="group", cascade="all, delete-orphan")


class UserGroup(Base):
    __tablename__ = "user_groups"

    user_id   = Column(String, ForeignKey("users.id",  ondelete="CASCADE"), primary_key=True)
    group_id  = Column(String, ForeignKey("groups.id", ondelete="CASCADE"), primary_key=True)
    role      = Column(String, nullable=False, default="member")  # "member" | "admin"
    joined_at = Column(DateTime(timezone=True), nullable=False)

    group = relationship("Group", back_populates="memberships")