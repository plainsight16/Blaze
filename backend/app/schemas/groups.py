import uuid
from datetime import date, datetime
from decimal import Decimal
from pydantic import BaseModel, EmailStr


# -- Group responses ----
class GroupResponse(BaseModel):
    id:          uuid.UUID
    name:        str
    description: str | None
    type:        str
    status:      str
    owner_id:    uuid.UUID | None
    is_active:   bool
    created_at:  datetime

    # Contribution configuration
    contribution_amount: Decimal | None
    frequency:           str | None
    cycle_length:        int | None
    max_members:         int | None
    start_date:          date | None
    current_cycle:       int
    current_position:    int

    # Wallet status
    has_wallet:          bool
    virtual_account:     str | None
    bank:                str | None

    model_config = {"from_attributes": True}

    @classmethod
    def from_group(cls, group) -> "GroupResponse":
        """Create response from Group model with computed fields."""
        return cls(
            id=group.id,
            name=group.name,
            description=group.description,
            type=group.type,
            status=group.status,
            owner_id=group.owner_id,
            is_active=group.is_active,
            created_at=group.created_at,
            contribution_amount=group.contribution_amount,
            frequency=group.frequency,
            cycle_length=group.cycle_length,
            max_members=group.max_members,
            start_date=group.start_date,
            current_cycle=group.current_cycle,
            current_position=group.current_position,
            has_wallet=group.has_wallet,
            virtual_account=group.isw_virtual_acct_no,
            bank=group.isw_virtual_acct_bank,
        )


class GroupSummaryResponse(BaseModel):
    """Lightweight group info for list endpoints."""
    id:          uuid.UUID
    name:        str
    description: str | None
    type:        str

    model_config = {"from_attributes": True}


# -- Membership responses ----
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


# -- Request responses --
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


# -- Requests (incoming payloads) ----
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


class ConfigureGroupRequest(BaseModel):
    """Configure contribution settings for a group."""
    contribution_amount: float | None = None   # ₦500 - ₦1,000,000
    frequency:           str | None = None     # daily | weekly | monthly
    cycle_length:        int | None = None     # 2 - 30 members
    max_members:         int | None = None     # Max participants
    start_date:          str | None = None     # ISO date string (YYYY-MM-DD)