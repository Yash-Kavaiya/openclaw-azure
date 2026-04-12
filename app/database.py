"""
Database Configuration for OpenClaw
Supports PostgreSQL (Azure) or SQLite (lightweight/dev).
"""
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.orm import DeclarativeBase
from sqlalchemy import Column, DateTime, func
import logging

from config import settings

logger = logging.getLogger(__name__)

# Use SQLite if no PostgreSQL URL configured
_db_url = settings.DATABASE_URL
_is_sqlite = _db_url.startswith("sqlite")

_engine_kwargs = {
    "echo": settings.DEBUG,
}

if not _is_sqlite:
    _engine_kwargs.update({
        "pool_size": settings.DB_POOL_SIZE,
        "max_overflow": settings.DB_MAX_OVERFLOW,
        "pool_pre_ping": True,
    })

engine = create_async_engine(_db_url, **_engine_kwargs)

AsyncSessionLocal = async_sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autocommit=False,
    autoflush=False,
)


class Base(DeclarativeBase):
    """Base class for all SQLAlchemy models."""

    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )


async def get_db() -> AsyncSession:
    """Dependency injection for database sessions."""
    async with AsyncSessionLocal() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()
