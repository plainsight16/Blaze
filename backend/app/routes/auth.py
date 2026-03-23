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


# ── Signup ────────────────────────────────────────────────────

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


# ── Verify email ──────────────────────────────────────────────

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


# ── Resend OTP ────────────────────────────────────────────────

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


# ── Login ─────────────────────────────────────────────────────

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


# ── Refresh ───────────────────────────────────────────────────

@router.post("/refresh", response_model=AccessTokenResponse)
def refresh(
    data: RefreshRequest,
    db: Session = Depends(get_db),
) -> AccessTokenResponse:
    new_refresh, user_id = rotate_refresh_token(data.refresh_token, db)
    access = create_access_token(user_id)
    return AccessTokenResponse(access_token=access)


# ── Logout ────────────────────────────────────────────────────

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


# ── Password reset ────────────────────────────────────────────

@router.post("/forgot-password", response_model=MessageResponse)
def forgot_password(
    data: ForgotPasswordRequest,
    bg: BackgroundTasks,
    db: Session = Depends(get_db),
) -> MessageResponse:
    user = db.query(User).filter(User.email == data.email).first()
    # Always return 200 — don't reveal whether the email exists
    if user and user.is_active:
        try:
            enforce_rate_limit(user.id, OTPPurpose.password_reset, db)
            otp = create_and_store_otp(user.id, OTPPurpose.password_reset, db)
            bg.add_task(send_password_reset_email, data.email, otp)
        except HTTPException:
            pass  # rate limit hit — still return 200

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


# ── Helpers ───────────────────────────────────────────────────

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
