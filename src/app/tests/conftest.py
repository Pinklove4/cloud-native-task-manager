"""Test configuration and fixtures."""

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.core.deps import get_db
from app.main import app
from app.models.base import Base


# In-memory SQLite for testing
SQLALCHEMY_DATABASE_URL = "sqlite:///:memory:"

engine = create_engine(
    SQLALCHEMY_DATABASE_URL,
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


def override_get_db():
    """Override database dependency for tests."""
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()


@pytest.fixture(scope="function")
def db():
    """Create test database tables and return session."""
    Base.metadata.create_all(bind=engine)
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()
        Base.metadata.drop_all(bind=engine)


@pytest.fixture(scope="function")
def client(db):
    """Create test client with database override."""
    app.dependency_overrides[get_db] = override_get_db
    Base.metadata.create_all(bind=engine)
    
    with TestClient(app) as test_client:
        yield test_client
    
    Base.metadata.drop_all(bind=engine)
    app.dependency_overrides.clear()


@pytest.fixture
def test_user(client):
    """Create a test user and return credentials."""
    user_data = {
        "email": "test@example.com",
        "username": "testuser",
        "password": "testpassword123",
    }
    response = client.post("/auth/register", json=user_data)
    assert response.status_code == 201
    return user_data


@pytest.fixture
def auth_headers(client, test_user):
    """Get authentication headers for test user."""
    response = client.post(
        "/auth/login",
        data={
            "username": test_user["email"],
            "password": test_user["password"],
        },
    )
    assert response.status_code == 200
    token = response.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}
