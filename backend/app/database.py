"""
SQLAlchemy engine + session factory.

Supabase notes
──────────────
- Use the *Transaction* pooler URI (port 6543) for serverless / short-lived
  connections.  Set pool_pre_ping=True so stale connections are detected and
  recycled automatically.
- If you switch to the *Session* pooler (port 5432) for long-lived processes,
  remove pool_pre_ping and tune pool_size / max_overflow as needed.
"""
from collections.abc import Generator

from sqlalchemy import create_engine
from sqlalchemy.orm import DeclarativeBase, Session, sessionmaker

from app.config import DATABASE_URL

engine = create_engine(
    DATABASE_URL,
    pool_pre_ping=True,   # detects stale connections (important for Supabase pooler)
    echo=False,           # set True locally for SQL debug output
)

SessionLocal: sessionmaker[Session] = sessionmaker(
    bind=engine,
    autocommit=False,
    autoflush=False,
)


class Base(DeclarativeBase):
    """Shared declarative base for all ORM models."""


def get_db() -> Generator[Session, None, None]:
    """FastAPI dependency — yields a DB session and guarantees close."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()