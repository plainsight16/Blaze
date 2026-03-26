import smtplib
from email.mime.text import MIMEText

from app.config import SMTP_HOST, SMTP_PASS, SMTP_PORT, SMTP_USER


def _send(to: str, subject: str, body_text: str) -> None:
    msg = MIMEText(body_text, "plain")
    msg["Subject"] = subject
    msg["From"]    = f"Blaze <{SMTP_USER}>"
    msg["To"]      = to

    with smtplib.SMTP(SMTP_HOST, SMTP_PORT) as server:
        server.starttls()
        server.login(SMTP_USER, SMTP_PASS)
        server.send_message(msg)


def send_verification_email(to: str, otp: str) -> None:
    _send(
        to,
        subject="Verify your account",
        body_text=f"Your verification code is: {otp}\n\nExpires in 5 minutes.",
    )


def send_password_reset_email(to: str, otp: str) -> None:
    _send(
        to,
        subject="Reset your password",
        body_text=f"Your password reset code is: {otp}\n\nExpires in 5 minutes.",
    )