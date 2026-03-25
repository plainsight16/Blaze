===== app/config.py =====
import os
from dotenv import load_dotenv

load_dotenv()

def _require(key: str) -> str:
    value = os.getenv(key)
    if not value:
        raise RuntimeError(f"Missing required environment variable: {key}")
    return value

DATABASE_URL: str = _require("DATABASE_URL")
SECRET_KEY: str   = _require("SECRET_KEY")

SMTP_HOST: str = _require("SMTP_HOST")
SMTP_PORT: int = int(os.getenv("SMTP_PORT", "587"))
SMTP_USER: str = _require("SMTP_USER")
SMTP_PASS: str = _require("SMTP_PASS")

ACCESS_TOKEN_EXPIRE_MINUTES: int  = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES",  "60"))
REFRESH_TOKEN_EXPIRE_DAYS: int    = int(os.getenv("REFRESH_TOKEN_EXPIRE_DAYS",    "30"))
OTP_EXPIRY_MINUTES: int           = int(os.getenv("OTP_EXPIRY_MINUTES",           "5"))
OTP_RATE_LIMIT_SECONDS: int       = int(os.getenv("OTP_RATE_LIMIT_SECONDS",       "60"))

===== app/main.py =====
from fastapi import FastAPI
from app.routes import auth, groups, kyc

app = FastAPI(title="Auth API", version="1.0.0")

app.include_router(auth.router,   prefix="/auth",   tags=["auth"])
app.include_router(groups.router, prefix="/groups", tags=["groups"])
app.include_router(kyc.router, prefix="/kyc", tags=["KYC"])
===== app/database.py =====
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base
from app.config import DATABASE_URL

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(bind=engine, autocommit=False, autoflush=False)
Base = declarative_base()

===== app/__init__.py =====

===== app/models/refresh_token.py =====
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

===== app/models/kyc.py =====
# models/kyc.py

from sqlalchemy import Column, String, JSON, ForeignKey
from sqlalchemy.orm import relationship
import uuid
from app.database import Base


class KYC(Base):
    __tablename__ = "kyc"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String, ForeignKey("users.id"), nullable=False)

    bvn_hash = Column(String, nullable=False, unique=True)

    verified = Column(String, default="false")

    bank_statement = Column(JSON, nullable=True)

    user = relationship("User")
===== app/models/otp.py =====
from sqlalchemy import Boolean, Column, DateTime, Enum, ForeignKey, String
from app.database import Base

import enum


class OTPPurpose(str, enum.Enum):
    email_verification = "email_verification"
    password_reset     = "password_reset"


class OTP(Base):
    __tablename__ = "otp_codes"

    id         = Column(String,   primary_key=True)
    user_id    = Column(String,   ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    purpose    = Column(Enum(OTPPurpose, name="otp_purpose"), nullable=False)
    otp_hash   = Column(String,   nullable=False)
    expires_at = Column(DateTime(timezone=True), nullable=False)
    is_used    = Column(Boolean,  nullable=False, default=False)
    created_at = Column(DateTime(timezone=True), nullable=False)

===== app/models/user.py =====
from sqlalchemy import Boolean, Column, DateTime, String
from app.database import Base


class User(Base):
    __tablename__ = "users"

    id            = Column(String,   primary_key=True)
    email         = Column(String,   unique=True,  nullable=False, index=True)
    username      = Column(String,   unique=True,  nullable=False)
    first_name    = Column(String,   nullable=False)
    last_name     = Column(String,   nullable=False)
    password_hash = Column(String,   nullable=False)
    is_active     = Column(Boolean,  nullable=False, default=True)
    verified_at   = Column(DateTime(timezone=True), nullable=True)
    created_at    = Column(DateTime(timezone=True), nullable=False)

===== app/models/group.py =====
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
===== app/models/__init__.py =====
from app.models import user, refresh_token, otp, group  # noqa: F401
===== app/schemas/auth.py =====
from pydantic import BaseModel, EmailStr


# -- Requests --------------------------------------------------

class SignupRequest(BaseModel):
    email:      EmailStr
    username:   str
    first_name: str
    last_name:  str
    password:   str


class VerifyOTPRequest(BaseModel):
    email:   EmailStr
    otp:     str
    purpose: str = "email_verification"


class ResendOTPRequest(BaseModel):
    email:   EmailStr
    purpose: str = "email_verification"


class LoginRequest(BaseModel):
    email:    EmailStr
    password: str


class RefreshRequest(BaseModel):
    refresh_token: str


class ForgotPasswordRequest(BaseModel):
    email: EmailStr


class ResetPasswordRequest(BaseModel):
    email:    EmailStr
    otp:      str
    password: str


class LogoutRequest(BaseModel):
    refresh_token: str


# -- Responses -------------------------------------------------

class MessageResponse(BaseModel):
    message: str


class TokenResponse(BaseModel):
    access_token:  str
    refresh_token: str
    token_type:    str = "bearer"


class AccessTokenResponse(BaseModel):
    access_token: str
    token_type:   str = "bearer"

===== app/schemas/kyc.py =====
from pydantic import BaseModel, Field
from typing import List


class KYCRequest(BaseModel):
    bvn: str = Field(..., min_length=11, max_length=11)


class MonthOnMonth(BaseModel):
    phone: str
    totalDebit: float
    debitCount: float
    totalCredit: float
    creditCount: float
    yearMonth: str
    averageBalance: float


class AverageValue(BaseModel):
    totalDebit: float
    debitCount: float
    totalCredit: float
    creditCount: float
    averageBalance: float


class BankStatement(BaseModel):
    monthOnMonth: List[MonthOnMonth]
    averageValue: AverageValue


class KYCResponseData(BaseModel):
    bvn: str
    firstName: str
    lastName: str
    phone: str
    bankStatement: BankStatement


class KYCResponse(BaseModel):
    responseCode: str
    responseMessage: str
    data: KYCResponseData
===== app/schemas/groups.py =====
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
===== app/schemas/__init__.py =====

===== app/routes/auth.py =====
import uuid
from datetime import datetime, timezone

from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.models.otp import OTPPurpose
from app.models.user import User
from app.schemas.auth import (
    AccessTokenResponse,
    ForgotPasswordRequest,
    LoginRequest,
    LogoutRequest,
    MessageResponse,
    RefreshRequest,
    ResendOTPRequest,
    ResetPasswordRequest,
    SignupRequest,
    TokenResponse,
    VerifyOTPRequest,
)
from app.services.email import send_password_reset_email, send_verification_email
from app.services.otp import consume_otp, create_and_store_otp, enforce_rate_limit
from app.services.token import (
    issue_refresh_token,
    revoke_all_refresh_tokens,
    revoke_refresh_token,
    rotate_refresh_token,
)
from app.utils.dependencies import get_current_user, get_db
from app.utils.security import create_access_token, hash_password, verify_password

router = APIRouter()


# -- Signup ----------------------------------------------------

@router.post("/signup", response_model=MessageResponse, status_code=status.HTTP_201_CREATED)
def signup(
    data: SignupRequest,
    bg: BackgroundTasks,
    db: Session = Depends(get_db),
) -> MessageResponse:
    if db.query(User).filter(User.email == data.email).first():
        raise HTTPException(status.HTTP_409_CONFLICT, "Email already registered.")
    if db.query(User).filter(User.username == data.username).first():
        raise HTTPException(status.HTTP_409_CONFLICT, "Username already taken.")

    user = User(
        id            = str(uuid.uuid4()),
        email         = data.email,
        username      = data.username,
        first_name    = data.first_name,
        last_name     = data.last_name,
        password_hash = hash_password(data.password),
        is_active     = True,
        verified_at   = None,
        created_at    = datetime.now(timezone.utc),
    )
    db.add(user)
    db.commit()

    enforce_rate_limit(user.id, OTPPurpose.email_verification, db)
    otp = create_and_store_otp(user.id, OTPPurpose.email_verification, db)
    bg.add_task(send_verification_email, data.email, otp)

    return MessageResponse(message="Account created. Check your email for a verification code.")


# -- Verify email ----------------------------------------------

@router.post("/verify-otp", response_model=MessageResponse)
def verify_otp(
    data: VerifyOTPRequest,
    db: Session = Depends(get_db),
) -> MessageResponse:
    user = _get_user_by_email(data.email, db)
    if user.verified_at:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Account already verified.")

    purpose = _parse_purpose(data.purpose)
    consume_otp(user.id, purpose, data.otp, db)

    if purpose == OTPPurpose.email_verification:
        user.verified_at = datetime.now(timezone.utc)
        db.commit()

    return MessageResponse(message="Account verified.")


# -- Resend OTP ------------------------------------------------

@router.post("/resend-otp", response_model=MessageResponse)
def resend_otp(
    data: ResendOTPRequest,
    bg: BackgroundTasks,
    db: Session = Depends(get_db),
) -> MessageResponse:
    user = _get_user_by_email(data.email, db)
    purpose = _parse_purpose(data.purpose)

    if purpose == OTPPurpose.email_verification and user.verified_at:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Account already verified.")

    enforce_rate_limit(user.id, purpose, db)
    otp = create_and_store_otp(user.id, purpose, db)

    if purpose == OTPPurpose.email_verification:
        bg.add_task(send_verification_email, data.email, otp)
    else:
        bg.add_task(send_password_reset_email, data.email, otp)

    return MessageResponse(message="Code sent.")


# -- Login -----------------------------------------------------

@router.post("/login", response_model=TokenResponse)
def login(
    data: LoginRequest,
    db: Session = Depends(get_db),
) -> TokenResponse:
    user = db.query(User).filter(User.email == data.email).first()
    if not user or not verify_password(data.password, user.password_hash):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Invalid email or password.")
    if not user.is_active:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Account deactivated.")
    if not user.verified_at:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Account not verified.")

    access  = create_access_token(user.id)
    refresh = issue_refresh_token(user.id, db)
    return TokenResponse(access_token=access, refresh_token=refresh)


# -- Refresh ---------------------------------------------------

@router.post("/refresh", response_model=AccessTokenResponse)
def refresh(
    data: RefreshRequest,
    db: Session = Depends(get_db),
) -> AccessTokenResponse:
    new_refresh, user_id = rotate_refresh_token(data.refresh_token, db)
    access = create_access_token(user_id)
    return AccessTokenResponse(access_token=access)


# -- Logout ----------------------------------------------------

@router.post("/logout", response_model=MessageResponse)
def logout(
    data: LogoutRequest,
    db: Session = Depends(get_db),
) -> MessageResponse:
    revoke_refresh_token(data.refresh_token, db)
    return MessageResponse(message="Logged out.")


@router.post("/logout-all", response_model=MessageResponse)
def logout_all(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> MessageResponse:
    revoke_all_refresh_tokens(current_user.id, db)
    return MessageResponse(message="Logged out of all devices.")


# -- Password reset --------------------------------------------

@router.post("/forgot-password", response_model=MessageResponse)
def forgot_password(
    data: ForgotPasswordRequest,
    bg: BackgroundTasks,
    db: Session = Depends(get_db),
) -> MessageResponse:
    user = db.query(User).filter(User.email == data.email).first()
    # Always return 200 â don't reveal whether the email exists
    if user and user.is_active:
        try:
            enforce_rate_limit(user.id, OTPPurpose.password_reset, db)
            otp = create_and_store_otp(user.id, OTPPurpose.password_reset, db)
            bg.add_task(send_password_reset_email, data.email, otp)
        except HTTPException:
            pass  # rate limit hit â still return 200

    return MessageResponse(message="If that email is registered, a reset code has been sent.")


@router.post("/reset-password", response_model=MessageResponse)
def reset_password(
    data: ResetPasswordRequest,
    db: Session = Depends(get_db),
) -> MessageResponse:
    user = _get_user_by_email(data.email, db)
    consume_otp(user.id, OTPPurpose.password_reset, data.otp, db)

    user.password_hash = hash_password(data.password)
    db.commit()

    # Invalidate all sessions after password change
    revoke_all_refresh_tokens(user.id, db)

    return MessageResponse(message="Password updated. Please log in again.")


# -- Helpers ---------------------------------------------------

def _get_user_by_email(email: str, db: Session) -> User:
    user = db.query(User).filter(User.email == email).first()
    if not user:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "No account found for that email.")
    return user


def _parse_purpose(raw: str) -> OTPPurpose:
    try:
        return OTPPurpose(raw)
    except ValueError:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, f"Invalid purpose: {raw!r}")

===== app/routes/kyc.py =====
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.models.user import User
from app.schemas.kyc import KYCRequest
from app.services.kyc import verify_bvn, attach_bank_statement
from app.utils.dependencies import get_current_user, get_db

router = APIRouter()

@router.post("/verify")
def verify_kyc(payload: KYCRequest, db: Session = Depends(get_db), cur_user: User = Depends(get_current_user)):
    user_id = cur_user.id
    try:
        kyc = verify_bvn(db, user_id, payload.bvn)    
        return {
            "responseCode": "00",
            "responseMessage": "BVN verified",
            "data": {"kycId": kyc.id}
        }

    except ValueError as e:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, detail=str(e))


@router.post("/generate-statement")
def generate_statement(db: Session = Depends(get_db), cur_user: User = Depends(get_current_user)):
    user_id = cur_user.id
    try:
        statement = attach_bank_statement(db, user_id)

        return {
            "responseCode": "00",
            "responseMessage": "Statement generated",
            "data": statement
        }

    except ValueError as e:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, detail=str(e))
===== app/routes/groups.py =====
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.models.user import User
from app.schemas.auth import MessageResponse
from app.schemas.groups import (
    CreateGroupRequest,
    GroupRequestResponse,
    GroupResponse,
    GroupSummaryResponse,
    InviteUserRequest,
    MemberResponse,
    MyInviteResponse,
    MyMembershipResponse,
    UpdateMemberRoleRequest,
)
from app.services import groups as svc
from app.utils.dependencies import get_current_user, get_db

router = APIRouter()


# -- Discovery -------------------------------------------------

@router.get("", response_model=list[GroupSummaryResponse])
def search_groups(
    q: str = Query(..., min_length=1, description="Search term"),
    db: Session = Depends(get_db),
    _: User = Depends(get_current_user),
) -> list[GroupSummaryResponse]:
    return svc.search_groups(q, db)


# -- My groups & invites ---------------------------------------

@router.get("/me", response_model=list[MyMembershipResponse])
def my_groups(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> list[MyMembershipResponse]:
    return svc.list_my_groups(current_user, db)


@router.get("/me/invites", response_model=list[MyInviteResponse])
def my_invites(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> list[MyInviteResponse]:
    return svc.list_my_invites(current_user, db)


@router.post("/me/invites/{request_id}/accept", response_model=MessageResponse)
def accept_invite(
    request_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> MessageResponse:
    svc.accept_invite(current_user, request_id, db)
    return MessageResponse(message="Invite accepted. Welcome to the group.")


@router.post("/me/invites/{request_id}/decline", response_model=MessageResponse)
def decline_invite(
    request_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> MessageResponse:
    svc.decline_invite(current_user, request_id, db)
    return MessageResponse(message="Invite declined.")


# -- Group management ------------------------------------------

@router.post("", response_model=GroupResponse, status_code=status.HTTP_201_CREATED)
def create_group(
    data: CreateGroupRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> GroupResponse:
    group = svc.create_group(data.name, data.description, data.type, current_user, db)
    return GroupResponse.model_validate(group)


@router.delete("/{group_id}", response_model=MessageResponse)
def delete_group(
    group_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> MessageResponse:
    svc.delete_group(current_user, group_id, db)
    return MessageResponse(message="Group deleted.")


# -- Membership ------------------------------------------------

@router.get("/{group_id}/members", response_model=list[MemberResponse])
def list_members(
    group_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> list[MemberResponse]:
    return svc.list_members(current_user, group_id, db)


@router.post("/{group_id}/leave", response_model=MessageResponse)
def leave_group(
    group_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> MessageResponse:
    svc.leave_group(current_user, group_id, db)
    return MessageResponse(message="You have left the group.")


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


# -- Join requests (user â group) ------------------------------

@router.post("/{group_id}/request", response_model=MessageResponse, status_code=status.HTTP_201_CREATED)
def request_to_join(
    group_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> MessageResponse:
    svc.request_to_join(current_user, group_id, db)
    return MessageResponse(message="Join request sent.")


@router.get("/{group_id}/requests", response_model=list[GroupRequestResponse])
def list_join_requests(
    group_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> list[GroupRequestResponse]:
    return svc.list_join_requests(current_user, group_id, db)


@router.post("/{group_id}/requests/{request_id}/approve", response_model=MessageResponse)
def approve_request(
    group_id: str,
    request_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> MessageResponse:
    svc.approve_request(current_user, group_id, request_id, db)
    return MessageResponse(message="Request approved.")


@router.post("/{group_id}/requests/{request_id}/reject", response_model=MessageResponse)
def reject_request(
    group_id: str,
    request_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> MessageResponse:
    svc.reject_request(current_user, group_id, request_id, db)
    return MessageResponse(message="Request rejected.")


# -- Invites (admin â user) ------------------------------------

@router.post("/{group_id}/invite", response_model=MessageResponse, status_code=status.HTTP_201_CREATED)
def invite_user(
    group_id: str,
    data: InviteUserRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> MessageResponse:
    svc.invite_user(current_user, group_id, data.email, data.username, db)
    return MessageResponse(message="Invite sent.")
===== app/routes/__init__.py =====

===== app/services/token.py =====
import uuid
from datetime import datetime, timezone

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models.refresh_token import RefreshToken
from app.utils.security import _sha256, generate_refresh_token, refresh_token_expiry


def issue_refresh_token(user_id: str, db: Session) -> str:
    """Create a refresh token record and return the raw token."""
    raw, digest = generate_refresh_token()
    record = RefreshToken(
        id         = str(uuid.uuid4()),
        user_id    = user_id,
        token_hash = digest,
        expires_at = refresh_token_expiry(),
        revoked    = False,
        created_at = datetime.now(timezone.utc),
    )
    db.add(record)
    db.commit()
    return raw


def rotate_refresh_token(raw: str, db: Session) -> tuple[str, str]:
    """
    Validate raw refresh token, revoke it, issue a new one.
    Returns (new_raw_token, user_id).
    """
    digest = _sha256(raw)
    record = db.query(RefreshToken).filter(RefreshToken.token_hash == digest).first()

    if not record or record.revoked:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Invalid refresh token.")
    if datetime.now(timezone.utc) > record.expires_at.replace(tzinfo=timezone.utc):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Refresh token expired.")

    user_id = record.user_id
    record.revoked = True
    db.commit()

    new_raw = issue_refresh_token(user_id, db)
    return new_raw, user_id


def revoke_refresh_token(raw: str, db: Session) -> None:
    """Revoke a single refresh token (logout)."""
    digest = _sha256(raw)
    record = db.query(RefreshToken).filter(RefreshToken.token_hash == digest).first()
    if record and not record.revoked:
        record.revoked = True
        db.commit()


def revoke_all_refresh_tokens(user_id: str, db: Session) -> None:
    """Revoke all tokens for a user (logout all devices)."""
    db.query(RefreshToken).filter(
        RefreshToken.user_id == user_id,
        RefreshToken.revoked == False,  # noqa: E712
    ).update({"revoked": True})
    db.commit()

===== app/services/kyc.py =====
from sqlalchemy.orm import Session
from app.models.kyc import KYC
from app.models.user import User
from app.utils.security import hash_bvn

import random
from typing import Dict, Any


def verify_bvn(db: Session, user_id: str, bvn: str):
    if not bvn.isdigit() or len(bvn) != 11:
        raise ValueError("Invalid BVN")

    bvn_hashed = hash_bvn(bvn)

    existing_bvn = db.query(KYC).filter(KYC.bvn_hash == bvn_hashed).first()
    existing_user = db.query(KYC).filter(KYC.user_id == user_id).first()
    if existing_bvn:
        raise ValueError("BVN already linked to another account")
    elif existing_user:
        raise ValueError("User already linked to a BVN")

    kyc = KYC(
        user_id=user_id,
        bvn_hash=bvn_hashed,
        verified="true"
    )

    db.add(kyc)
    db.commit()
    db.refresh(kyc)

    return kyc

def generate_bank_statement() -> Dict[str, Any]:
    months = ["2024-04", "2024-05", "2024-06"]

    month_data = []
    total_debit = total_credit = 0
    debit_count = credit_count = 0
    balance_sum = 0

    for m in months:
        td = random.randint(1000, 500000)
        tc = random.randint(0, 1000000)
        dc = random.randint(1, 20)
        cc = random.randint(0, 15)
        ab = random.uniform(0, 300000)

        total_debit += td
        total_credit += tc
        debit_count += dc
        credit_count += cc
        balance_sum += ab

        month_data.append({
            "totalDebit": float(td),
            "debitCount": float(dc),
            "totalCredit": float(tc),
            "creditCount": float(cc),
            "yearMonth": m,
            "averageBalance": float(round(ab, 2))
        })

    avg_len = len(months)

    return {
        "monthOnMonth": month_data,
        "averageValue": {
            "totalDebit": total_debit / avg_len,
            "debitCount": debit_count / avg_len,
            "totalCredit": total_credit / avg_len,
            "creditCount": credit_count / avg_len,
            "averageBalance": balance_sum / avg_len
        }
    }

def attach_bank_statement(db: Session, user_id: str):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise ValueError("User not found")

    kyc = db.query(KYC).filter(KYC.user_id == user_id).first()
    if not kyc or not kyc.verified:
        raise ValueError("KYC not verified")

    statement = generate_bank_statement()

    kyc.bank_statement = statement
    db.commit()
    db.refresh(kyc)

    return statement
===== app/services/groups.py =====
import uuid
from datetime import datetime, timezone

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models.group import Group, GroupRequest, UserGroup
from app.models.user import User
from app.models.kyc import KYC


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

def _get_user_eligibility(user_id: str, monthly_con: str, db: Session) -> bool | None:
    kyc_row = db.query(KYC).filter(KYC.user_id == user_id).first()
    bank_statement = kyc_row.bank_statement
    print(type(bank_statement))
    eligibility = (bank_statement["averageValue"]["averageBalance"] // 3) >= monthly_con
    return eligibility

def _approve_into_group(user_id: str, group_id: str, db: Session) -> None:
    """Create a UserGroup row â shared by approve and accept paths."""
    db.add(UserGroup(
        user_id   = user_id,
        group_id  = group_id,
        role      = "member",
        joined_at = datetime.now(timezone.utc),
    ))


# -- Group CRUD ------------------------------------------------

def create_group(name: str, description: str | None, type_: str, owner: User, db: Session) -> Group:
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


def delete_group(actor: User, group_id: str, db: Session) -> None:
    group = _get_group_or_404(group_id, db)
    if group.owner_id != actor.id:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Only the owner can delete the group.")
    group.is_active = False
    db.commit()


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


# -- Join requests (user â group) ------------------------------

def request_to_join(actor: User, group_id: str, db: Session) -> GroupRequest:
    group = _get_group_or_404(group_id, db)

    if group.type and group.type == "private":
        raise HTTPException(status.HTTP_403_FORBIDDEN, "This group is private. You need an invite.")

    if _get_membership(actor.id, group_id, db):
        raise HTTPException(status.HTTP_409_CONFLICT, "Already a member.")

    if _get_pending_request(actor.id, group_id, db):
        raise HTTPException(status.HTTP_409_CONFLICT, "You already have a pending request.")

    if not _get_user_eligibility(actor.bank_statement, group.monthly_con, db):
        raise HTTPException(status.HTTP_409_CONFLICT, "You are not eligible to join this group.")

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


# -- Invites (admin â user) ------------------------------------

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
===== app/services/otp.py =====
import uuid
from datetime import datetime, timezone

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.config import OTP_EXPIRY_MINUTES, OTP_RATE_LIMIT_SECONDS
from app.models.otp import OTP, OTPPurpose
from app.utils.security import generate_otp, verify_otp

from datetime import timedelta


def enforce_rate_limit(user_id: str, purpose: OTPPurpose, db: Session) -> None:
    last = (
        db.query(OTP)
        .filter(OTP.user_id == user_id, OTP.purpose == purpose)
        .order_by(OTP.created_at.desc())
        .first()
    )
    if last:
        elapsed = (datetime.now(timezone.utc) - last.created_at.replace(tzinfo=timezone.utc)).total_seconds()
        if elapsed < OTP_RATE_LIMIT_SECONDS:
            wait = int(OTP_RATE_LIMIT_SECONDS - elapsed)
            raise HTTPException(status.HTTP_429_TOO_MANY_REQUESTS, f"Try again in {wait}s.")


def create_and_store_otp(user_id: str, purpose: OTPPurpose, db: Session) -> str:
    """Invalidate any live OTPs for this user+purpose, create a fresh one, return raw code."""
    db.query(OTP).filter(
        OTP.user_id == user_id,
        OTP.purpose == purpose,
        OTP.is_used == False,  # noqa: E712
    ).update({"is_used": True})

    raw, digest = generate_otp()
    record = OTP(
        id         = str(uuid.uuid4()),
        user_id    = user_id,
        purpose    = purpose,
        otp_hash   = digest,
        expires_at = datetime.now(timezone.utc) + timedelta(minutes=OTP_EXPIRY_MINUTES),
        is_used    = False,
        created_at = datetime.now(timezone.utc),
    )
    db.add(record)
    db.commit()
    return raw


def consume_otp(user_id: str, purpose: OTPPurpose, raw: str, db: Session) -> None:
    """Validate and mark OTP used. Raises HTTPException on any failure."""
    record = (
        db.query(OTP)
        .filter(
            OTP.user_id == user_id,
            OTP.purpose == purpose,
            OTP.is_used == False,  # noqa: E712
        )
        .order_by(OTP.created_at.desc())
        .first()
    )
    if not record:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "No active code found.")
    if datetime.now(timezone.utc) > record.expires_at.replace(tzinfo=timezone.utc):
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Code has expired.")
    if not verify_otp(raw, record.otp_hash):
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Invalid code.")

    record.is_used = True
    db.commit()

===== app/services/__init__.py =====

===== app/services/email.py =====
import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

from app.config import SMTP_HOST, SMTP_PASS, SMTP_PORT, SMTP_USER


def _send(to: str, subject: str, body_text: str, body_html: str) -> None:
    msg = MIMEMultipart("alternative")
    msg["Subject"] = subject
    msg["From"]    = SMTP_USER
    msg["To"]      = to
    msg.attach(MIMEText(body_text, "plain"))
    msg.attach(MIMEText(body_html, "html"))
    with smtplib.SMTP(SMTP_HOST, SMTP_PORT) as server:
        server.starttls()
        server.login(SMTP_USER, SMTP_PASS)
        server.send_message(msg)


def send_verification_email(to: str, otp: str) -> None:
    _send(
        to,
        subject   = "Verify your account",
        body_text = f"Your verification code is: {otp}\n\nExpires in 5 minutes.",
        body_html = f"""
        <p>Your verification code is:</p>
        <h2 style="letter-spacing:4px">{otp}</h2>
        <p>Expires in 5 minutes. If you didn't request this, ignore this email.</p>
        """,
    )


def send_password_reset_email(to: str, otp: str) -> None:
    _send(
        to,
        subject   = "Reset your password",
        body_text = f"Your password reset code is: {otp}\n\nExpires in 5 minutes.",
        body_html = f"""
        <p>Your password reset code is:</p>
        <h2 style="letter-spacing:4px">{otp}</h2>
        <p>Expires in 5 minutes. If you didn't request this, ignore this email.</p>
        """,
    )

===== app/utils/dependencies.py =====
from collections.abc import Generator

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jose import JWTError
from sqlalchemy.orm import Session

from app.database import SessionLocal
from app.models.user import User
from app.utils.security import decode_access_token

_bearer = HTTPBearer()


def get_db() -> Generator[Session, None, None]:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(_bearer),
    db: Session = Depends(get_db),
) -> User:
    try:
        user_id = decode_access_token(credentials.credentials)
    except JWTError:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Invalid or expired token.")

    user = db.query(User).filter(User.id == user_id).first()
    if not user or not user.is_active:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "User not found or deactivated.")
    if not user.verified_at:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Account not verified.")

    return user

===== app/utils/security.py =====
import hashlib
import hmac
import secrets
from datetime import datetime, timedelta, timezone

from jose import JWTError, jwt
from passlib.context import CryptContext

from app.config import ACCESS_TOKEN_EXPIRE_MINUTES, REFRESH_TOKEN_EXPIRE_DAYS, SECRET_KEY

_pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
ALGORITHM = "HS256"


# -- Passwords -------------------------------------------------

def hash_password(password: str) -> str:
    return _pwd_context.hash(password)


def verify_password(plain: str, hashed: str) -> bool:
    return _pwd_context.verify(plain, hashed)


# -- OTP tokens ------------------------------------------------

def generate_otp() -> tuple[str, str]:
    """Return (raw_6char_code, sha256_hex_digest). Store digest; send raw."""
    raw = secrets.token_hex(3)          # 6 hex chars, looks like a code
    digest = _sha256(raw)
    return raw, digest


def verify_otp(raw: str, stored_digest: str) -> bool:
    return hmac.compare_digest(_sha256(raw), stored_digest)


def _sha256(value: str) -> str:
    return hashlib.sha256(value.encode()).hexdigest()


# -- JWT access tokens -----------------------------------------

def create_access_token(user_id: str) -> str:
    expire = datetime.now(timezone.utc) + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    return jwt.encode({"sub": str(user_id), "exp": expire}, SECRET_KEY, algorithm=ALGORITHM)


def decode_access_token(token: str) -> str:
    """Return user_id or raise JWTError."""
    payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
    user_id: str = payload.get("sub")
    if not user_id:
        raise JWTError("Missing subject")
    return user_id


# -- Refresh tokens --------------------------------------------

def generate_refresh_token() -> tuple[str, str]:
    """Return (raw_token, sha256_hex_digest). Store digest; send raw."""
    raw = secrets.token_urlsafe(64)
    return raw, _sha256(raw)


def refresh_token_expiry() -> datetime:
    return datetime.now(timezone.utc) + timedelta(days=REFRESH_TOKEN_EXPIRE_DAYS)


import hashlib
import os


def hash_bvn(bvn: str) -> str:
    salt = os.getenv("BVN_SALT", "default_salt")  # use env in prod
    return hashlib.sha256(f"{bvn}{salt}".encode()).hexdigest()

===== app/utils/__init__.py =====

