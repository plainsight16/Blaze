from fastapi import FastAPI, Depends, HTTPException, BackgroundTasks
from sqlalchemy import create_engine, Column, String, Boolean, DateTime
from sqlalchemy.orm import sessionmaker, declarative_base, Session
from pydantic import BaseModel, EmailStr
from passlib.context import CryptContext
from datetime import datetime, timedelta
from jose import jwt
import os, random, smtplib, uuid
from email.mime.text import MIMEText
from dotenv import load_dotenv

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL")
SECRET_KEY = os.getenv("SECRET_KEY")

ACCESS_TOKEN_EXPIRE_MINUTES = 60
OTP_EXPIRY_MINUTES = 5
OTP_RATE_LIMIT_SECONDS = 60  # 1 OTP per minute

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(bind=engine)
Base = declarative_base()

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

app = FastAPI()

# =====================
# Models
# =====================
class User(Base):
    __tablename__ = "users"
    id = Column(String, primary_key=True)
    email = Column(String)
    username = Column(String)
    first_name = Column(String)
    last_name = Column(String)
    password_hash = Column(String)
    is_verified = Column(Boolean)

class OTP(Base):
    __tablename__ = "otp_codes"
    id = Column(String, primary_key=True)
    email = Column(String)
    otp_hash = Column(String)
    expires_at = Column(DateTime)
    is_used = Column(Boolean)
    created_at = Column(DateTime)

# =====================
# Schemas
# =====================
class SignupRequest(BaseModel):
    email: EmailStr
    username: str
    first_name: str
    last_name: str
    password: str

class VerifyOTPRequest(BaseModel):
    email: EmailStr
    otp: str

class LoginRequest(BaseModel):
    email: EmailStr
    password: str

# =====================
# Helpers
# =====================
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def hash_password(p): return pwd_context.hash(p)
def verify_password(p, h): return pwd_context.verify(p, h)

def generate_otp():
    return str(random.randint(100000, 999999))

def create_token(email: str):
    payload = {
        "sub": email,
        "exp": datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    }
    return jwt.encode(payload, SECRET_KEY, algorithm="HS256")

# =====================
# Email (background)
# =====================
def send_email(to_email, otp):
    msg = MIMEText(f"Your OTP is: {otp}")
    msg["Subject"] = "Your OTP Code"
    msg["From"] = os.getenv("SMTP_USER")
    msg["To"] = to_email

    with smtplib.SMTP(os.getenv("SMTP_HOST"), int(os.getenv("SMTP_PORT"))) as server:
        server.starttls()
        server.login(os.getenv("SMTP_USER"), os.getenv("SMTP_PASS"))
        server.send_message(msg)

# =====================
# Core logic
# =====================
def enforce_rate_limit(email: str, db: Session):
    last_otp = db.query(OTP)\
        .filter(OTP.email == email)\
        .order_by(OTP.created_at.desc())\
        .first()

    if last_otp:
        diff = (datetime.utcnow() - last_otp.created_at).total_seconds()
        if diff < OTP_RATE_LIMIT_SECONDS:
            raise HTTPException(429, "Too many requests. Try later.")

def create_and_store_otp(email: str, db: Session):
    otp = generate_otp()

    otp_record = OTP(
        id=str(uuid.uuid4()),
        email=email,
        otp_hash=hash_password(otp),
        expires_at=datetime.utcnow() + timedelta(minutes=OTP_EXPIRY_MINUTES),
        is_used=False,
        created_at=datetime.utcnow()
    )
    db.add(otp_record)
    db.commit()

    return otp

# =====================
# Routes
# =====================

@app.post("/signup")
def signup(data: SignupRequest, bg: BackgroundTasks, db: Session = Depends(get_db)):
    if db.query(User).filter(User.email == data.email).first():
        raise HTTPException(400, "Email already exists")

    if db.query(User).filter(User.username == data.username).first():
        raise HTTPException(400, "Username taken")

    enforce_rate_limit(data.email, db)

    user = User(
        id=str(uuid.uuid4()),
        email=data.email,
        username=data.username,
        first_name=data.first_name,
        last_name=data.last_name,
        password_hash=hash_password(data.password),
        is_verified=False
    )
    db.add(user)

    otp = create_and_store_otp(data.email, db)

    bg.add_task(send_email, data.email, otp)

    return {"message": "OTP sent"}


@app.post("/resend-otp")
def resend_otp(email: EmailStr, bg: BackgroundTasks, db: Session = Depends(get_db)):
    enforce_rate_limit(email, db)

    otp = create_and_store_otp(email, db)

    bg.add_task(send_email, email, otp)

    return {"message": "OTP resent"}


@app.post("/verify-otp")
def verify_otp(data: VerifyOTPRequest, db: Session = Depends(get_db)):
    otp_record = db.query(OTP)\
        .filter(OTP.email == data.email, OTP.is_used == False)\
        .order_by(OTP.created_at.desc())\
        .first()

    if not otp_record:
        raise HTTPException(400, "OTP not found")

    if datetime.utcnow() > otp_record.expires_at:
        raise HTTPException(400, "Expired")

    if not verify_password(data.otp, otp_record.otp_hash):
        raise HTTPException(400, "Invalid OTP")

    otp_record.is_used = True

    user = db.query(User).filter(User.email == data.email).first()
    user.is_verified = True

    db.commit()

    return {"message": "Verified"}


@app.post("/login")
def login(data: LoginRequest, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == data.email).first()

    if not user or not verify_password(data.password, user.password_hash):
        raise HTTPException(400, "Invalid credentials")

    if not user.is_verified:
        raise HTTPException(400, "Not verified")

    token = create_token(user.email)

    return {"access_token": token}