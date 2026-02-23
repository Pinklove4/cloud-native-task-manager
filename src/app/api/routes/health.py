"""Health check endpoints."""

from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy import text
from sqlalchemy.orm import Session

from app.core.deps import get_db


router = APIRouter()


class HealthResponse(BaseModel):
    """Health check response model."""
    
    status: str
    database: str
    version: str


@router.get("/health", response_model=HealthResponse)
def health_check(db: Session = Depends(get_db)) -> HealthResponse:
    """
    Health check endpoint for container orchestration.
    
    Checks:
    - Application is running
    - Database connection is working
    """
    # Check database connectivity
    try:
        db.execute(text("SELECT 1"))
        db_status = "healthy"
    except Exception:
        db_status = "unhealthy"
    
    overall_status = "healthy" if db_status == "healthy" else "degraded"
    
    return HealthResponse(
        status=overall_status,
        database=db_status,
        version="1.0.0",
    )


@router.get("/ready")
def readiness_check() -> dict:
    """Readiness probe for Kubernetes."""
    return {"ready": True}


@router.get("/live")
def liveness_check() -> dict:
    """Liveness probe for Kubernetes."""
    return {"alive": True}
