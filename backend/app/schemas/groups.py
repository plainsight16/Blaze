from datetime import datetime
from pydantic import BaseModel
import uuid


# -- Responses -------------------------------------------------

class GroupResponse(BaseModel):
    id:          uuid.UUID
    name:        str
    description: str | None
    owner_id:    uuid.UUID | None
    is_active:   bool
    created_at:  datetime

    model_config = {"from_attributes": True}


class MemberResponse(BaseModel):
    user_id:   uuid.UUID
    username:  str
    email:     str
    role:      str
    joined_at: datetime


class MembershipResponse(BaseModel):
    group_id:  uuid.UUID
    name:      str
    role:      str
    joined_at: datetime


# -- Requests --------------------------------------------------

class CreateGroupRequest(BaseModel):
    name:        str
    description: str | None = None


class UpdateGroupRequest(BaseModel):
    name:        str | None = None
    description: str | None = None


class UpdateMemberRoleRequest(BaseModel):
    role: str  # "member" | "admin"