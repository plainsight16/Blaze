import logging
import uuid
from datetime import datetime, timezone

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models.group import Group, GroupRequest, UserGroup
from app.models.user import User
from app.services import wallet_service


logger = logging.getLogger(__name__)


# -- Internal helpers ------------------------------------------

def _get_group_or_404(group_id: str, db: Session) -> Group:
    group = db.query(Group).filter(
        Group.id == group_id,
        Group.is_active == True,  # noqa: E712
    ).first()
    if not group:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Group not found.")
    return group


def _get_membership(user_id: str, group_id: str, db: Session) -> UserGroup | None:
    return db.query(UserGroup).filter(
        UserGroup.user_id  == user_id,
        UserGroup.group_id == group_id,
    ).first()


def _require_membership(user_id: str, group_id: str, db: Session) -> UserGroup:
    membership = _get_membership(user_id, group_id, db)
    if not membership:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Not a member of this group.")
    return membership


def _require_admin(user_id: str, group_id: str, db: Session) -> None:
    membership = _require_membership(user_id, group_id, db)
    if membership.role != "admin":
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Admin access required.")


def _resolve_target_user(email: str | None, username: str | None, db: Session) -> User:
    if not email and not username:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Provide either email or username.")
    query = db.query(User)
    if email:
        user = query.filter(User.email == email).first()
    else:
        user = query.filter(User.username == username).first()
    if not user:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "User not found.")
    if not user.is_active:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "User account is inactive.")
    return user


def _get_pending_request(user_id: str, group_id: str, db: Session) -> GroupRequest | None:
    return db.query(GroupRequest).filter(
        GroupRequest.user_id  == user_id,
        GroupRequest.group_id == group_id,
        GroupRequest.status   == "pending",
    ).first()


def _approve_into_group(user_id: str, group_id: str, db: Session) -> None:
    """Create a UserGroup row — shared by approve and accept paths."""
    db.add(UserGroup(
        user_id   = user_id,
        group_id  = group_id,
        role      = "member",
        joined_at = datetime.now(timezone.utc),
    ))


# -- Group CRUD ------------------------------------------------

async def create_group(name: str, description: str | None, type_: str, owner: User, db: Session) -> Group:
    """
    Create a new group and provision an Interswitch wallet.

    The group wallet is used to:
    - Receive contributions from members
    - Hold funds until payout cycle
    - Disburse payouts to members
    """
    if type_ not in ("public", "private"):
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Type must be 'public' or 'private'.")
    if db.query(Group).filter(Group.name == name).first():
        raise HTTPException(status.HTTP_409_CONFLICT, "Group name already taken.")

    group = Group(
        id          = str(uuid.uuid4()),
        name        = name,
        description = description,
        type        = type_,
        owner_id    = owner.id,
        is_active   = True,
        created_at  = datetime.now(timezone.utc),
    )
    db.add(group)
    db.flush()

    # Owner automatically becomes an admin member
    db.add(UserGroup(
        user_id   = owner.id,
        group_id  = group.id,
        role      = "admin",
        joined_at = datetime.now(timezone.utc),
    ))

    # Provision Interswitch wallet for the group
    try:
        await wallet_service.provision_group_wallet(db=db, group=group)
        logger.info(f"Wallet provisioned for group {group.id}: {group.isw_wallet_id}")
    except Exception as e:
        # Log the error but don't fail group creation
        # Group can operate without wallet initially, admin can retry later
        logger.error(f"Failed to provision wallet for group {group.id}: {e}")

    db.commit()
    return group


def search_groups(query: str, db: Session) -> list[Group]:
    """Search public active groups by name (case-insensitive substring)."""
    return (
        db.query(Group)
        .filter(
            Group.is_active == True,  # noqa: E712
            Group.type      == "public",
            Group.name.ilike(f"%{query}%"),
        )
        .order_by(Group.name)
        .limit(50)
        .all()
    )


def get_group(actor: User, group_id: str, db: Session) -> Group:
    """Get group details. Must be a member to view."""
    group = _get_group_or_404(group_id, db)
    _require_membership(actor.id, group_id, db)
    return group


def delete_group(actor: User, group_id: str, db: Session) -> None:
    group = _get_group_or_404(group_id, db)
    if group.owner_id != actor.id:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Only the owner can delete the group.")
    group.is_active = False
    db.commit()


def configure_group(
    actor: User,
    group_id: str,
    contribution_amount: float | None,
    frequency: str | None,
    cycle_length: int | None,
    max_members: int | None,
    start_date: str | None,
    db: Session,
) -> Group:
    """
    Configure group contribution settings. Admin only.

    Can only be done while group is in 'open' status.
    """
    from datetime import date as date_type

    group = _get_group_or_404(group_id, db)
    _require_admin(actor.id, group_id, db)

    if group.status != "open":
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            "Cannot modify configuration after group has started.",
        )

    # Validate frequency
    if frequency and frequency not in ("daily", "weekly", "monthly"):
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            "Frequency must be 'daily', 'weekly', or 'monthly'.",
        )

    # Validate contribution amount
    if contribution_amount is not None:
        if contribution_amount < 500 or contribution_amount > 1_000_000:
            raise HTTPException(
                status.HTTP_400_BAD_REQUEST,
                "Contribution amount must be between ₦500 and ₦1,000,000.",
            )

    # Validate cycle length
    if cycle_length is not None:
        if cycle_length < 2 or cycle_length > 30:
            raise HTTPException(
                status.HTTP_400_BAD_REQUEST,
                "Cycle length must be between 2 and 30 members.",
            )

    # Apply updates
    if contribution_amount is not None:
        group.contribution_amount = contribution_amount
    if frequency is not None:
        group.frequency = frequency
    if cycle_length is not None:
        group.cycle_length = cycle_length
        group.max_members = cycle_length  # max members = cycle length for Ajo
    if max_members is not None:
        group.max_members = max_members
    if start_date is not None:
        group.start_date = date_type.fromisoformat(start_date)

    db.commit()
    db.refresh(group)
    return group


async def provision_wallet(actor: User, group_id: str, db: Session) -> Group:
    """
    Provision or retry wallet provisioning for a group. Admin only.

    Used when initial wallet provisioning failed during group creation.
    """
    group = _get_group_or_404(group_id, db)
    _require_admin(actor.id, group_id, db)

    if group.has_wallet:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            "Group already has a wallet.",
        )

    try:
        await wallet_service.provision_group_wallet(db=db, group=group)
        db.commit()
        db.refresh(group)
        logger.info(f"Wallet provisioned for group {group.id}: {group.isw_wallet_id}")
        return group
    except Exception as e:
        logger.error(f"Failed to provision wallet for group {group.id}: {e}")
        raise HTTPException(
            status.HTTP_502_BAD_GATEWAY,
            f"Wallet provisioning failed: {e}",
        )


# -- Membership ------------------------------------------------

def list_my_groups(user: User, db: Session) -> list[dict]:
    rows = (
        db.query(UserGroup, Group)
        .join(Group, Group.id == UserGroup.group_id)
        .filter(
            UserGroup.user_id == user.id,
            Group.is_active   == True,  # noqa: E712
        )
        .all()
    )
    return [
        {
            "group_id":  ug.group_id,
            "name":      g.name,
            "type":      g.type,
            "role":      ug.role,
            "joined_at": ug.joined_at,
        }
        for ug, g in rows
    ]


def list_members(actor: User, group_id: str, db: Session) -> list[dict]:
    _get_group_or_404(group_id, db)
    _require_membership(actor.id, group_id, db)

    rows = (
        db.query(UserGroup, User)
        .join(User, User.id == UserGroup.user_id)
        .filter(UserGroup.group_id == group_id)
        .all()
    )
    return [
        {
            "user_id":   ug.user_id,
            "username":  u.username,
            "email":     u.email,
            "role":      ug.role,
            "joined_at": ug.joined_at,
        }
        for ug, u in rows
    ]


def update_member_role(actor: User, group_id: str, target_user_id: str, role: str, db: Session) -> None:
    if role not in ("member", "admin"):
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Role must be 'member' or 'admin'.")
    _get_group_or_404(group_id, db)
    _require_admin(actor.id, group_id, db)

    membership = _get_membership(target_user_id, group_id, db)
    if not membership:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "User is not a member.")

    membership.role = role
    db.commit()


def remove_member(actor: User, group_id: str, target_user_id: str, db: Session) -> None:
    _get_group_or_404(group_id, db)
    _require_admin(actor.id, group_id, db)

    if target_user_id == actor.id:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Use /leave to remove yourself.")

    membership = _get_membership(target_user_id, group_id, db)
    if not membership:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "User is not a member.")

    db.delete(membership)
    db.commit()


def leave_group(actor: User, group_id: str, db: Session) -> None:
    group = _get_group_or_404(group_id, db)
    membership = _require_membership(actor.id, group_id, db)

    if group.owner_id == actor.id:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            "Owner cannot leave. Transfer ownership or delete the group.",
        )

    db.delete(membership)
    db.commit()


# -- Join requests (user → group) ------------------------------

def request_to_join(actor: User, group_id: str, db: Session) -> GroupRequest:
    group = _get_group_or_404(group_id, db)

    if group.type and group.type == "private":
        raise HTTPException(status.HTTP_403_FORBIDDEN, "This group is private. You need an invite.")

    if _get_membership(actor.id, group_id, db):
        raise HTTPException(status.HTTP_409_CONFLICT, "Already a member.")

    if _get_pending_request(actor.id, group_id, db):
        raise HTTPException(status.HTTP_409_CONFLICT, "You already have a pending request.")

    req = GroupRequest(
        id           = str(uuid.uuid4()),
        group_id     = group_id,
        user_id      = actor.id,
        initiated_by = actor.id,
        direction    = "join_request",
        status       = "pending",
        created_at   = datetime.now(timezone.utc),
    )
    db.add(req)
    db.commit()
    return req


def approve_request(actor: User, group_id: str, request_id: str, db: Session) -> None:
    _get_group_or_404(group_id, db)
    _require_admin(actor.id, group_id, db)

    req = db.query(GroupRequest).filter(
        GroupRequest.id       == request_id,
        GroupRequest.group_id == group_id,
        GroupRequest.direction == "join_request",
        GroupRequest.status    == "pending",
    ).first()
    if not req:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Request not found.")

    req.status      = "approved"
    req.resolved_at = datetime.now(timezone.utc)
    _approve_into_group(req.user_id, group_id, db)
    db.delete(req)
    db.commit()


def reject_request(actor: User, group_id: str, request_id: str, db: Session) -> None:
    _get_group_or_404(group_id, db)
    _require_admin(actor.id, group_id, db)

    req = db.query(GroupRequest).filter(
        GroupRequest.id        == request_id,
        GroupRequest.group_id  == group_id,
        GroupRequest.direction == "join_request",
        GroupRequest.status    == "pending",
    ).first()
    if not req:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Request not found.")

    req.status      = "rejected"
    req.resolved_at = datetime.now(timezone.utc)
    db.commit()


def list_join_requests(actor: User, group_id: str, db: Session) -> list[dict]:
    _get_group_or_404(group_id, db)
    _require_admin(actor.id, group_id, db)

    rows = (
        db.query(GroupRequest, User)
        .join(User, User.id == GroupRequest.user_id)
        .filter(
            GroupRequest.group_id  == group_id,
            GroupRequest.direction == "join_request",
            GroupRequest.status    == "pending",
        )
        .all()
    )
    return [
        {
            "id":           req.id,
            "group_id":     req.group_id,
            "user_id":      req.user_id,
            "username":     u.username,
            "email":        u.email,
            "direction":    req.direction,
            "status":       req.status,
            "initiated_by": req.initiated_by,
            "created_at":   req.created_at,
        }
        for req, u in rows
    ]


# -- Invites (admin → user) ------------------------------------

def invite_user(actor: User, group_id: str, email: str | None, username: str | None, db: Session) -> GroupRequest:
    _get_group_or_404(group_id, db)
    _require_admin(actor.id, group_id, db)

    target = _resolve_target_user(email, username, db)

    if _get_membership(target.id, group_id, db):
        raise HTTPException(status.HTTP_409_CONFLICT, "User is already a member.")

    if _get_pending_request(target.id, group_id, db):
        raise HTTPException(status.HTTP_409_CONFLICT, "User already has a pending request or invite.")

    req = GroupRequest(
        id           = str(uuid.uuid4()),
        group_id     = group_id,
        user_id      = target.id,
        initiated_by = actor.id,
        direction    = "invite",
        status       = "pending",
        created_at   = datetime.now(timezone.utc),
    )
    db.add(req)
    db.commit()
    return req


def accept_invite(actor: User, request_id: str, db: Session) -> None:
    req = db.query(GroupRequest).filter(
        GroupRequest.id        == request_id,
        GroupRequest.user_id   == actor.id,
        GroupRequest.direction == "invite",
        GroupRequest.status    == "pending",
    ).first()
    if not req:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Invite not found.")

    _get_group_or_404(req.group_id, db)  # ensure group still active

    req.status      = "accepted"
    req.resolved_at = datetime.now(timezone.utc)
    _approve_into_group(actor.id, req.group_id, db)
    db.delete(req)
    db.commit()


def decline_invite(actor: User, request_id: str, db: Session) -> None:
    req = db.query(GroupRequest).filter(
        GroupRequest.id        == request_id,
        GroupRequest.user_id   == actor.id,
        GroupRequest.direction == "invite",
        GroupRequest.status    == "pending",
    ).first()
    if not req:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Invite not found.")

    req.status      = "declined"
    req.resolved_at = datetime.now(timezone.utc)
    db.commit()


def list_my_invites(actor: User, db: Session) -> list[dict]:
    rows = (
        db.query(GroupRequest, Group)
        .join(Group, Group.id == GroupRequest.group_id)
        .filter(
            GroupRequest.user_id   == actor.id,
            GroupRequest.direction == "invite",
            GroupRequest.status    == "pending",
            Group.is_active        == True,  # noqa: E712
        )
        .all()
    )
    return [
        {
            "id":         req.id,
            "group_id":   req.group_id,
            "group_name": g.name,
            "status":     req.status,
            "created_at": req.created_at,
        }
        for req, g in rows
    ]