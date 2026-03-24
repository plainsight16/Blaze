import uuid
from datetime import datetime, timezone

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models.group import Group, UserGroup
from app.models.user import User


def _get_group_or_404(group_id: str, db: Session) -> Group:
    group = db.query(Group).filter(Group.id == group_id, Group.is_active == True).first()  # noqa: E712
    if not group:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Group not found.")
    return group


def _get_membership_or_403(user_id: str, group_id: str, db: Session) -> UserGroup:
    membership = db.query(UserGroup).filter(
        UserGroup.user_id == user_id,
        UserGroup.group_id == group_id,
    ).first()
    if not membership:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Not a member of this group.")
    return membership


def require_admin(user_id: str, group_id: str, db: Session) -> None:
    membership = _get_membership_or_403(user_id, group_id, db)
    if membership.role != "admin":
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Admin access required.")


def create_group(name: str, description: str | None, owner: User, db: Session) -> Group:
    if db.query(Group).filter(Group.name == name).first():
        raise HTTPException(status.HTTP_409_CONFLICT, "Group name already taken.")

    group = Group(
        id          = str(uuid.uuid4()),
        name        = name,
        description = description,
        owner_id    = owner.id,
        is_active   = True,
        created_at  = datetime.now(timezone.utc),
    )
    db.add(group)
    db.flush()  # get the id before commit

    # Creator automatically joins as admin
    db.add(UserGroup(
        user_id   = owner.id,
        group_id  = group.id,
        role      = "admin",
        joined_at = datetime.now(timezone.utc),
    ))
    db.commit()
    return group


def join_group(user: User, group_id: str, db: Session) -> UserGroup:
    group = _get_group_or_404(group_id, db)
    existing = db.query(UserGroup).filter(
        UserGroup.user_id == user.id,
        UserGroup.group_id == group.id,
    ).first()
    if existing:
        raise HTTPException(status.HTTP_409_CONFLICT, "Already a member.")

    membership = UserGroup(
        user_id   = user.id,
        group_id  = group.id,
        role      = "member",
        joined_at = datetime.now(timezone.utc),
    )
    db.add(membership)
    db.commit()
    return membership


def leave_group(user: User, group_id: str, db: Session) -> None:
    group = _get_group_or_404(group_id, db)
    membership = _get_membership_or_403(user.id, group.id, db)

    if group.owner_id == user.id:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Owner cannot leave. Transfer ownership or delete the group.")

    db.delete(membership)
    db.commit()


def remove_member(admin: User, group_id: str, target_user_id: str, db: Session) -> None:
    _get_group_or_404(group_id, db)
    require_admin(admin.id, group_id, db)

    if target_user_id == admin.id:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Use /leave to remove yourself.")

    membership = db.query(UserGroup).filter(
        UserGroup.user_id == target_user_id,
        UserGroup.group_id == group_id,
    ).first()
    if not membership:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "User is not a member.")

    db.delete(membership)
    db.commit()


def list_members(user: User, group_id: str, db: Session) -> list[dict]:
    _get_group_or_404(group_id, db)
    _get_membership_or_403(user.id, group_id, db)

    rows = (
        db.query(UserGroup, User)
        .join(User, User.id == UserGroup.user_id)
        .filter(UserGroup.group_id == group_id)
        .all()
    )
    return [
        {
            "user_id":   u.id,
            "username":  u.username,
            "email":     u.email,
            "role":      ug.role,
            "joined_at": ug.joined_at,
        }
        for ug, u in rows
    ]


def list_user_groups(user: User, db: Session) -> list[dict]:
    rows = (
        db.query(UserGroup, Group)
        .join(Group, Group.id == UserGroup.group_id)
        .filter(UserGroup.user_id == user.id, Group.is_active == True)  # noqa: E712
        .all()
    )
    return [
        {
            "group_id":  g.id,
            "name":      g.name,
            "role":      ug.role,
            "joined_at": ug.joined_at,
        }
        for ug, g in rows
    ]


def update_member_role(admin: User, group_id: str, target_user_id: str, role: str, db: Session) -> None:
    if role not in ("member", "admin"):
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Role must be 'member' or 'admin'.")
    _get_group_or_404(group_id, db)
    require_admin(admin.id, group_id, db)

    membership = db.query(UserGroup).filter(
        UserGroup.user_id == target_user_id,
        UserGroup.group_id == group_id,
    ).first()
    if not membership:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "User is not a member.")

    membership.role = role
    db.commit()


def delete_group(admin: User, group_id: str, db: Session) -> None:
    group = _get_group_or_404(group_id, db)
    if group.owner_id != admin.id:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Only the owner can delete the group.")

    group.is_active = False  # soft delete
    db.commit()