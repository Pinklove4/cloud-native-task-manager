"""User model for authentication."""

from sqlalchemy import Boolean, Column, Integer, String
from sqlalchemy.orm import relationship

from app.models.base import Base, TimestampMixin


class User(Base, TimestampMixin):
    """User model for authentication and task ownership."""
    
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), unique=True, index=True, nullable=False)
    username = Column(String(100), unique=True, index=True, nullable=False)
    hashed_password = Column(String(255), nullable=False)
    is_active = Column(Boolean, default=True, nullable=False)
    
    # Relationship to tasks
    tasks = relationship("Task", back_populates="owner", cascade="all, delete-orphan")
    
    def __repr__(self) -> str:
        return f"<User(id={self.id}, username={self.username})>"
