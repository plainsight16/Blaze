import uuid
from datetime import datetime
from pydantic import BaseModel, EmailStr


# -- Group responses -------------------------------------------

class GroupResponse(BaseModel):
    id:          uuid.UUID
    name:        str
    description: str | None
    type:        str
    owner_id:    uuid.UUID | None
    is_active:   bool
    created_at:  datetime

    model_config = {"from_attributes": True}


class GroupSummaryResponse(BaseModel):
    """Lightweight group info for list endpoints."""
    id:          uuid.UUID
    name:        str
    description: str | None
    type:        str

    model_config = {"from_attributes": True}


# -- Membership responses --------------------------------------

class MemberResponse(BaseModel):
    user_id:   uuid.UUID
    username:  str
    email:     str
    role:      str
    joined_at: datetime


class MyMembershipResponse(BaseModel):
    """A group as seen from the current user's membership."""
    group_id:  uuid.UUID
    name:      str
    type:      str
    role:      str
    joined_at: datetime


# -- Request responses -----------------------------------------

class GroupRequestResponse(BaseModel):
    """A join request or invite, as seen by an admin."""
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
    """An invite as seen by the invited user."""
    id:         uuid.UUID
    group_id:   uuid.UUID
    group_name: str
    status:     str
    created_at: datetime


# -- Requests (incoming payloads) ------------------------------

class CreateGroupRequest(BaseModel):
    name:        str
    description: str | None = None
    type:        str = "public"   # 'public' | 'private'


class InviteUserRequest(BaseModel):
    """Admin invites a user by email or username."""
    email:    EmailStr | None = None
    username: str | None = None

    model_config = {"from_attributes": True}


class UpdateMemberRoleRequest(BaseModel):
    role: str   # 'member' | 'admin'