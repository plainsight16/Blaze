import uuid
from datetime import datetime

from pydantic import BaseModel, EmailStr, field_validator
from app.schemas.wallet import WalletResponse


# -- Group ---------------------------------------------------------------------

class GroupResponse(BaseModel):
    id:          uuid.UUID
    name:        str
    description: str | None
    type:        str
    owner_id:    uuid.UUID | None
    is_active:   bool
    created_at:  datetime
    monthly_con: int
    wallet: WalletResponse | None

    model_config = {"from_attributes": True}


class GroupSummaryResponse(BaseModel):
    id:          uuid.UUID
    name:        str
    description: str | None
    type:        str
    monthly_con: int

    model_config = {"from_attributes": True}


# -- Membership ----------------------------------------------------------------

class MemberResponse(BaseModel):
    user_id:   uuid.UUID
    username:  str
    email:     str
    role:      str
    joined_at: datetime


class MyMembershipResponse(BaseModel):
    group_id:  uuid.UUID
    name:      str
    type:      str
    role:      str
    joined_at: datetime


# -- Requests / Invites --------------------------------------------------------

class GroupRequestResponse(BaseModel):
    id:           uuid.UUID
    group_id:     uuid.UUID
    user_id:      uuid.UUID
    username:     str
    email:        str
    direction:    str
    status:       str
    initiated_by: uuid.UUID
    created_at:   datetime


class MyInviteResponse(BaseModel):
    id:         uuid.UUID
    group_id:   uuid.UUID
    group_name: str
    status:     str
    created_at: datetime


# -- Incoming payloads ---------------------------------------------------------

class CreateGroupRequest(BaseModel):
    name:        str
    description: str | None = None
    type:        str = "public"
    monthly_con: int = 1000

    @field_validator("type")
    @classmethod
    def valid_type(cls, v: str) -> str:
        if v not in ("public", "private"):
            raise ValueError("type must be 'public' or 'private'.")
        return v

    @field_validator("monthly_con")
    @classmethod
    def positive_contribution(cls, v: int) -> int:
        if v < 0:
            raise ValueError("monthly_con must be non-negative.")
        return v


class InviteUserRequest(BaseModel):
    email:    EmailStr | None = None
    username: str | None      = None

    @field_validator("username")
    @classmethod
    def one_identifier(cls, v: str | None, info) -> str | None:
        # Full cross-field validation is done in the service layer
        return v


class UpdateMemberRoleRequest(BaseModel):
    role: str

    @field_validator("role")
    @classmethod
    def valid_role(cls, v: str) -> str:
        if v not in ("member", "admin"):
            raise ValueError("role must be 'member' or 'admin'.")
        return v