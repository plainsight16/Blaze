from pydantic import BaseModel, EmailStr, field_validator


# ── Requests ──────────────────────────────────────────────────────────────────

class SignupRequest(BaseModel):
    email:      EmailStr
    username:   str
    first_name: str
    last_name:  str
    password:   str

    @field_validator("username")
    @classmethod
    def username_alphanumeric(cls, v: str) -> str:
        v = v.strip()
        if not v.replace("_", "").isalnum():
            raise ValueError("Username may only contain letters, numbers, and underscores.")
        if len(v) < 3:
            raise ValueError("Username must be at least 3 characters.")
        return v

    @field_validator("password")
    @classmethod
    def password_strength(cls, v: str) -> str:
        if len(v) < 8:
            raise ValueError("Password must be at least 8 characters.")
        return v


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

    @field_validator("password")
    @classmethod
    def password_strength(cls, v: str) -> str:
        if len(v) < 8:
            raise ValueError("Password must be at least 8 characters.")
        return v


class LogoutRequest(BaseModel):
    refresh_token: str


# ── Responses ─────────────────────────────────────────────────────────────────

class MessageResponse(BaseModel):
    message: str


class TokenResponse(BaseModel):
    access_token:  str
    refresh_token: str
    token_type:    str = "bearer"


class AccessTokenResponse(BaseModel):
    access_token: str
    token_type:   str = "bearer"