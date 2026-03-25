import logging

from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker, declarative_base

from app.config import DATABASE_URL


logger = logging.getLogger(__name__)


def _normalize_database_url(url: str) -> str:
    """Accept legacy postgres:// URLs by rewriting them for SQLAlchemy."""
    if url.startswith("postgres://"):
        return "postgresql://" + url[len("postgres://"):]
    return url


def _engine_kwargs(url: str) -> dict:
    """Provide sane defaults for local development connectivity."""
    if url.startswith("postgresql://"):
        return {
            "pool_pre_ping": True,
            "connect_args": {"connect_timeout": 5},
        }
    return {}


_normalized_database_url = _normalize_database_url(DATABASE_URL)
engine = create_engine(_normalized_database_url, **_engine_kwargs(_normalized_database_url))
SessionLocal = sessionmaker(bind=engine, autocommit=False, autoflush=False)
Base = declarative_base()


def initialize_database() -> None:
    """
    Create missing tables and patch legacy schemas in-place.

    This repo does not currently use Alembic migrations. The bootstrap below
    keeps existing local databases usable as models evolve.
    """
    from app import models  # noqa: F401

    Base.metadata.create_all(bind=engine)
    _sync_legacy_schema()


def _sync_legacy_schema() -> None:
    statements = [
        # ------------------------------------------------------------------
        # users
        # ------------------------------------------------------------------
        "ALTER TABLE users ADD COLUMN IF NOT EXISTS phone_number VARCHAR(20)",
        "ALTER TABLE users ADD COLUMN IF NOT EXISTS bvn_verified BOOLEAN NOT NULL DEFAULT FALSE",
        "ALTER TABLE users ADD COLUMN IF NOT EXISTS bvn_hash VARCHAR(64)",
        "ALTER TABLE users ADD COLUMN IF NOT EXISTS kyc_completed_at TIMESTAMPTZ",
        "ALTER TABLE users ADD COLUMN IF NOT EXISTS isw_wallet_id VARCHAR(50)",
        "ALTER TABLE users ADD COLUMN IF NOT EXISTS isw_merchant_code VARCHAR(20)",
        "ALTER TABLE users ADD COLUMN IF NOT EXISTS isw_virtual_acct_no VARCHAR(20)",
        "ALTER TABLE users ADD COLUMN IF NOT EXISTS isw_virtual_acct_bank VARCHAR(50)",
        "ALTER TABLE users ADD COLUMN IF NOT EXISTS wallet_pin_encrypted VARCHAR(255)",
        "CREATE UNIQUE INDEX IF NOT EXISTS ix_users_phone_number ON users (phone_number)",
        "CREATE INDEX IF NOT EXISTS ix_users_isw_wallet_id ON users (isw_wallet_id)",

        # ------------------------------------------------------------------
        # groups
        # ------------------------------------------------------------------
        "ALTER TABLE groups ADD COLUMN IF NOT EXISTS status VARCHAR(15) NOT NULL DEFAULT 'open'",
        "ALTER TABLE groups ADD COLUMN IF NOT EXISTS contribution_amount NUMERIC(12, 2)",
        "ALTER TABLE groups ADD COLUMN IF NOT EXISTS frequency VARCHAR(10)",
        "ALTER TABLE groups ADD COLUMN IF NOT EXISTS cycle_length INTEGER",
        "ALTER TABLE groups ADD COLUMN IF NOT EXISTS max_members INTEGER",
        "ALTER TABLE groups ADD COLUMN IF NOT EXISTS start_date DATE",
        "ALTER TABLE groups ADD COLUMN IF NOT EXISTS current_cycle INTEGER NOT NULL DEFAULT 0",
        "ALTER TABLE groups ADD COLUMN IF NOT EXISTS current_position INTEGER NOT NULL DEFAULT 1",
        "ALTER TABLE groups ADD COLUMN IF NOT EXISTS isw_wallet_id VARCHAR(50)",
        "ALTER TABLE groups ADD COLUMN IF NOT EXISTS isw_merchant_code VARCHAR(20)",
        "ALTER TABLE groups ADD COLUMN IF NOT EXISTS isw_virtual_acct_no VARCHAR(20)",
        "ALTER TABLE groups ADD COLUMN IF NOT EXISTS isw_virtual_acct_bank VARCHAR(50)",
        "ALTER TABLE groups ADD COLUMN IF NOT EXISTS wallet_pin_encrypted VARCHAR(255)",
        "CREATE INDEX IF NOT EXISTS ix_groups_isw_wallet_id ON groups (isw_wallet_id)",

        # ------------------------------------------------------------------
        # group_requests
        # ------------------------------------------------------------------
        "ALTER TABLE group_requests ADD COLUMN IF NOT EXISTS initiated_by VARCHAR",
        "ALTER TABLE group_requests ADD COLUMN IF NOT EXISTS direction VARCHAR",
        "ALTER TABLE group_requests ADD COLUMN IF NOT EXISTS resolved_at TIMESTAMPTZ",

        # ------------------------------------------------------------------
        # wallet_transactions
        # ------------------------------------------------------------------
        "CREATE INDEX IF NOT EXISTS ix_wallet_tx_owner ON wallet_transactions (wallet_owner_type, wallet_owner_id)",
        "CREATE INDEX IF NOT EXISTS ix_wallet_tx_status_created ON wallet_transactions (status, created_at)",
    ]

    with engine.begin() as conn:
        for statement in statements:
            conn.execute(text(statement))

    logger.info("Database schema initialization completed")
