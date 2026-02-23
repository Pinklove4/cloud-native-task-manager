"""Task model for task management."""

import enum

from sqlalchemy import Column, Enum, ForeignKey, Integer, String, Text
from sqlalchemy.orm import relationship

from app.models.base import Base, TimestampMixin


class TaskStatus(str, enum.Enum):
    """Task status enumeration."""
    
    TODO = "todo"
    DOING = "doing"
    DONE = "done"


class Task(Base, TimestampMixin):
    """Task model for task management."""
    
    __tablename__ = "tasks"
    
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(255), nullable=False)
    description = Column(Text, nullable=True)
    status = Column(
        Enum(TaskStatus),
        default=TaskStatus.TODO,
        nullable=False,
    )
    owner_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    
    # Relationship to user
    owner = relationship("User", back_populates="tasks")
    
    def __repr__(self) -> str:
        return f"<Task(id={self.id}, title={self.title}, status={self.status})>"
