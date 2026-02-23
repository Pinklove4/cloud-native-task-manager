"""Database session configuration."""

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.core.config import settings


# Create database engine
engine = create_engine(
    settings.DATABASE_URL,
    pool_pre_ping=True,  # Enable connection health checks
    pool_size=5,  # Connection pool size
    max_overflow=10,  # Additional connections when pool is full
    echo=settings.DEBUG,  # Log SQL queries in debug mode
)

# Session factory
SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine,
)
