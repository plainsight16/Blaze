from pydantic import BaseModel, EmailStr


# ── Requests ──────────────────────────────────────────────────

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


# ── Responses ─────────────────────────────────────────────────

class MessageResponse(BaseModel):
    message: str


class TokenResponse(BaseModel):
    access_token:  str
    refresh_token: str
    token_type:    str = "bearer"


class AccessTokenResponse(BaseModel):
    access_token: str
    token_type:   str = "bearer"
