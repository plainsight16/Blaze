import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.routes import auth, groups, kyc, wallet
from app.config import ENVIRONMENT
from app.database import initialize_database


# Configure logging
logging.basicConfig(
    level=logging.DEBUG if ENVIRONMENT == "development" else logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan events."""
    logger.info(f"Starting AjoApp API (environment: {ENVIRONMENT})")
    logger.info("Initializing database schema")
    initialize_database()
    logger.info("Database schema ready")
    yield
    logger.info("Shutting down AjoApp API")


app = FastAPI(
    title="AjoApp API",
    description="Digital Rotating Savings Platform - Interswitch Hackathon",
    version="1.0.0",
    lifespan=lifespan,
)


# =============================================================================
# CORS Middleware
# =============================================================================
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"] if ENVIRONMENT == "development" else [],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# =============================================================================
# Routes
# =============================================================================
app.include_router(auth.router, prefix="/auth", tags=["Authentication"])
app.include_router(kyc.router)  # /kyc prefix defined in router
app.include_router(wallet.router)  # /wallet prefix defined in router
app.include_router(groups.router, prefix="/groups", tags=["Groups"])


# =============================================================================
# Health Check
# =============================================================================
@app.get("/health", tags=["Health"])
async def health_check():
    """API health check endpoint."""
    return {
        "status": "healthy",
        "environment": ENVIRONMENT,
    }


@app.get("/", tags=["Health"])
async def root():
    """Root endpoint."""
    return {
        "name": "AjoApp API",
        "version": "1.0.0",
        "docs": "/docs",
    }
