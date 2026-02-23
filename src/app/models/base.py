"""SQLAlchemy base model and metadata."""

from datetime import datetime, timezone

from sqlalchemy import Column, DateTime, Integer
from sqlalchemy.orm import DeclarativeBase


class Base(DeclarativeBase):
    """Base class for all SQLAlchemy models."""
    
    pass


class TimestampMixin:
    """Mixin for created_at and updated_at timestamps."""
    
    created_at = Column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
    )
    updated_at = Column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
        nullable=False,
    )
