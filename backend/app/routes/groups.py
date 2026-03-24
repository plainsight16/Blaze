from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.models.user import User
from app.schemas.auth import MessageResponse
from app.schemas.groups import (
    CreateGroupRequest,
    GroupResponse,
    MemberResponse,
    MembershipResponse,
    UpdateMemberRoleRequest,
)
from app.services import groups as svc
from app.utils.dependencies import get_current_user, get_db

router = APIRouter()


@router.post("", response_model=GroupResponse, status_code=status.HTTP_201_CREATED)
def create_group(
    data: CreateGroupRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> GroupResponse:
    group = svc.create_group(data.name, data.description, current_user, db)
    return GroupResponse.model_validate(group)


@router.get("/me", response_model=list[MembershipResponse])
def my_groups(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> list[MembershipResponse]:
    return svc.list_user_groups(current_user, db)


@router.post("/add", response_model=MessageResponse)
def join_group(
    username: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> MessageResponse:
    svc.join_group(current_user, username, db)
    return MessageResponse(message="Added to group.")

@router.post("/join", response_model=MessageResponse)
def join_group(
    group_name: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> MessageResponse:
    svc.join_group(current_user, group_name, db)
    return MessageResponse(message="Joined group.")

@router.post("/{group_id}/leave", response_model=MessageResponse)
def leave_group(
    group_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> MessageResponse:
    svc.leave_group(current_user, group_id, db)
    return MessageResponse(message="Left group.")


@router.get("/{group_id}/members", response_model=list[MemberResponse])
def list_members(
    group_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> list[MemberResponse]:
    return svc.list_members(current_user, group_id, db)


@router.delete("/{group_id}/members/{user_id}", response_model=MessageResponse)
def remove_member(
    group_id: str,
    user_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> MessageResponse:
    svc.remove_member(current_user, group_id, user_id, db)
    return MessageResponse(message="Member removed.")


@router.patch("/{group_id}/members/{user_id}/role", response_model=MessageResponse)
def update_role(
    group_id: str,
    user_id: str,
    data: UpdateMemberRoleRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> MessageResponse:
    svc.update_member_role(current_user, group_id, user_id, data.role, db)
    return MessageResponse(message="Role updated.")


@router.delete("/{group_id}", response_model=MessageResponse)
def delete_group(
    group_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> MessageResponse:
    svc.delete_group(current_user, group_id, db)
    return MessageResponse(message="Group deleted.")
