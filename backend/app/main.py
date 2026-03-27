"""
Application entrypoint.

Startup order:
  1. Import all models (populates SQLAlchemy metadata for Alembic).
  2. Create the FastAPI app with CORS and global exception handling.
  3. Register routers.
"""
from fastapi import FastAPI, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

import app.models  # noqa: F401
from app.config import ALLOWED_ORIGINS
from app.database import Base, engine
from app.routes import auth, groups, home, kyc, wallet

# ── App ───────────────────────────────────────────────────────────────────────

app = FastAPI(
    title       = "Auth API",
    version     = "1.0.0",
    description = "Authentication, KYC, and group management API.",
)


@app.on_event("startup")
def ensure_schema() -> None:
    """
    Temporary stopgap until Alembic lands in the repo.
    Ensures new tables such as wallets exist for manual testing.
    """
    Base.metadata.create_all(bind=engine)

# ── CORS ──────────────────────────────────────────────────────────────────────

app.add_middleware(
    CORSMiddleware,
    allow_origins     = ALLOWED_ORIGINS,
    allow_credentials = True,
    allow_methods     = ["*"],
    allow_headers     = ["*"],
)

# ── Global exception handlers ─────────────────────────────────────────────────

@app.exception_handler(Exception)
async def unhandled_exception_handler(request: Request, exc: Exception) -> JSONResponse:
    """
    Catch-all for unhandled exceptions.
    Returns a generic 500 so internal error details are never leaked to clients.
    In production, plug in Sentry / structured logging here.
    """
    # TODO: log exc with your logging/APM framework
    return JSONResponse(
        status_code = status.HTTP_500_INTERNAL_SERVER_ERROR,
        content     = {"detail": "An unexpected error occurred. Please try again later."},
    )

# ── Routers ───────────────────────────────────────────────────────────────────

app.include_router(home.router,   prefix="",   tags=["Docs"])
app.include_router(auth.router,   prefix="/auth",   tags=["Auth"])
app.include_router(kyc.router,    prefix="/kyc",    tags=["KYC"])
app.include_router(wallet.router, prefix="/wallet", tags=["Wallet"])
app.include_router(groups.router, prefix="/groups", tags=["Groups"])


# ── Health check ──────────────────────────────────────────────────────────────

@app.get("/health", tags=["Health"], include_in_schema=False)
def health() -> dict:
    return {"status": "ok"}
