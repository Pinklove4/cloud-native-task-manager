"""Task management endpoints."""

from datetime import datetime
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query, status
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from app.core.deps import get_current_user, get_db
from app.models.task import Task, TaskStatus
from app.models.user import User


router = APIRouter()


# Request/Response Models
class TaskCreate(BaseModel):
    """Task creation request model."""
    
    title: str = Field(..., min_length=1, max_length=255)
    description: Optional[str] = Field(None, max_length=5000)
    status: TaskStatus = TaskStatus.TODO


class TaskUpdate(BaseModel):
    """Task update request model."""
    
    title: Optional[str] = Field(None, min_length=1, max_length=255)
    description: Optional[str] = Field(None, max_length=5000)
    status: Optional[TaskStatus] = None


class TaskResponse(BaseModel):
    """Task response model."""
    
    id: int
    title: str
    description: Optional[str]
    status: TaskStatus
    owner_id: int
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True


class TaskListResponse(BaseModel):
    """Task list response with pagination info."""
    
    tasks: List[TaskResponse]
    total: int
    page: int
    page_size: int


@router.get("", response_model=TaskListResponse)
def list_tasks(
    status_filter: Optional[TaskStatus] = Query(None, alias="status"),
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> TaskListResponse:
    """
    List all tasks for the current user.
    
    - **status**: Filter by task status (optional)
    - **page**: Page number (default: 1)
    - **page_size**: Items per page (default: 20, max: 100)
    """
    query = db.query(Task).filter(Task.owner_id == current_user.id)
    
    # Apply status filter if provided
    if status_filter:
        query = query.filter(Task.status == status_filter)
    
    # Get total count
    total = query.count()
    
    # Apply pagination
    offset = (page - 1) * page_size
    tasks = query.order_by(Task.created_at.desc()).offset(offset).limit(page_size).all()
    
    return TaskListResponse(
        tasks=tasks,
        total=total,
        page=page,
        page_size=page_size,
    )


@router.post("", response_model=TaskResponse, status_code=status.HTTP_201_CREATED)
def create_task(
    task_data: TaskCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> Task:
    """
    Create a new task.
    
    - **title**: Task title (required, 1-255 characters)
    - **description**: Task description (optional, max 5000 characters)
    - **status**: Task status (default: todo)
    """
    task = Task(
        title=task_data.title,
        description=task_data.description,
        status=task_data.status,
        owner_id=current_user.id,
    )
    
    db.add(task)
    db.commit()
    db.refresh(task)
    
    return task


@router.get("/{task_id}", response_model=TaskResponse)
def get_task(
    task_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> Task:
    """
    Get a specific task by ID.
    
    Returns 404 if task doesn't exist or doesn't belong to current user.
    """
    task = db.query(Task).filter(
        Task.id == task_id,
        Task.owner_id == current_user.id,
    ).first()
    
    if not task:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Task not found",
        )
    
    return task


@router.put("/{task_id}", response_model=TaskResponse)
def update_task(
    task_id: int,
    task_data: TaskUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> Task:
    """
    Update a task.
    
    Only provided fields will be updated.
    Returns 404 if task doesn't exist or doesn't belong to current user.
    """
    task = db.query(Task).filter(
        Task.id == task_id,
        Task.owner_id == current_user.id,
    ).first()
    
    if not task:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Task not found",
        )
    
    # Update only provided fields
    update_data = task_data.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(task, field, value)
    
    db.commit()
    db.refresh(task)
    
    return task


@router.delete("/{task_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_task(
    task_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> None:
    """
    Delete a task.
    
    Returns 404 if task doesn't exist or doesn't belong to current user.
    """
    task = db.query(Task).filter(
        Task.id == task_id,
        Task.owner_id == current_user.id,
    ).first()
    
    if not task:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Task not found",
        )
    
    db.delete(task)
    db.commit()
