"""Database session configuration."""

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.core.config import settings


def get_engine_args() -> dict:
    """Get engine configuration based on database type."""
    # SQLite doesn't support connection pooling parameters
    if settings.DATABASE_URL.startswith("sqlite"):
        return {
            "connect_args": {"check_same_thread": False},
            "echo": settings.DEBUG,
        }
    # PostgreSQL and other databases support pooling
    return {
        "pool_pre_ping": True,  # Enable connection health checks
        "pool_size": 5,  # Connection pool size
        "max_overflow": 10,  # Additional connections when pool is full
        "echo": settings.DEBUG,  # Log SQL queries in debug mode
    }


# Create database engine
engine = create_engine(settings.DATABASE_URL, **get_engine_args())

# Session factory
SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine,
)
