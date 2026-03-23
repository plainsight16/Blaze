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
