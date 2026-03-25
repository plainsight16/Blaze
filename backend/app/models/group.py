from sqlalchemy import Column, DateTime, ForeignKey, String, Boolean, UniqueConstraint, Integer
from sqlalchemy.orm import relationship
from app.database import Base


class Group(Base):
    __tablename__ = "groups"

    id          = Column(String,  primary_key=True)
    name        = Column(String,  unique=True, nullable=False, index=True)
    description = Column(String,  nullable=True)
    type        = Column(String,  nullable=False, default="public")   # "public" | "private"
    owner_id    = Column(String,  ForeignKey("users.id", ondelete="SET NULL"), nullable=True, index=True)
    is_active   = Column(Boolean, nullable=False, default=True)
    created_at  = Column(DateTime(timezone=True), nullable=False)

    memberships = relationship("UserGroup",    back_populates="group", cascade="all, delete-orphan")
    requests    = relationship("GroupRequest", back_populates="group", cascade="all, delete-orphan")

    monthly_con = Column(Integer, nullable=False, default=1000)


class UserGroup(Base):
    __tablename__ = "user_groups"

    user_id   = Column(String, ForeignKey("users.id",  ondelete="CASCADE"), primary_key=True)
    group_id  = Column(String, ForeignKey("groups.id", ondelete="CASCADE"), primary_key=True)
    role      = Column(String, nullable=False, default="member")  # "member" | "admin"
    joined_at = Column(DateTime(timezone=True), nullable=False)

    group = relationship("Group", back_populates="memberships")


class GroupRequest(Base):
    __tablename__ = "group_requests"

    id           = Column(String,  primary_key=True)
    group_id     = Column(String,  ForeignKey("groups.id", ondelete="CASCADE"), nullable=False, index=True)
    user_id      = Column(String,  ForeignKey("users.id",  ondelete="CASCADE"), nullable=False, index=True)
    initiated_by = Column(String,  ForeignKey("users.id",  ondelete="CASCADE"), nullable=False)
    direction    = Column(String,  nullable=False)   # "join_request" | "invite"
    status       = Column(String,  nullable=False, default="pending")  # "pending" | "approved" | "rejected" | "accepted" | "declined"
    created_at   = Column(DateTime(timezone=True), nullable=False)
    resolved_at  = Column(DateTime(timezone=True), nullable=True)

    group = relationship("Group", back_populates="requests")

    __table_args__ = (
        UniqueConstraint("group_id", "user_id", name="uq_group_request_pair"),
    )