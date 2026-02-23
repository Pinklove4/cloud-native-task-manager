"""Tests for authentication endpoints."""

import pytest


class TestRegister:
    """Tests for user registration."""
    
    def test_register_success(self, client):
        """Test successful user registration."""
        response = client.post(
            "/auth/register",
            json={
                "email": "newuser@example.com",
                "username": "newuser",
                "password": "securepassword123",
            },
        )
        
        assert response.status_code == 201
        data = response.json()
        assert data["email"] == "newuser@example.com"
        assert data["username"] == "newuser"
        assert data["is_active"] is True
        assert "id" in data
        assert "password" not in data
        assert "hashed_password" not in data
    
    def test_register_duplicate_email(self, client, test_user):
        """Test registration with existing email fails."""
        response = client.post(
            "/auth/register",
            json={
                "email": test_user["email"],
                "username": "differentuser",
                "password": "password123",
            },
        )
        
        assert response.status_code == 400
        assert "Email already registered" in response.json()["detail"]
    
    def test_register_duplicate_username(self, client, test_user):
        """Test registration with existing username fails."""
        response = client.post(
            "/auth/register",
            json={
                "email": "different@example.com",
                "username": test_user["username"],
                "password": "password123",
            },
        )
        
        assert response.status_code == 400
        assert "Username already taken" in response.json()["detail"]
    
    def test_register_invalid_email(self, client):
        """Test registration with invalid email fails."""
        response = client.post(
            "/auth/register",
            json={
                "email": "invalid-email",
                "username": "testuser",
                "password": "password123",
            },
        )
        
        assert response.status_code == 422
    
    def test_register_short_password(self, client):
        """Test registration with short password fails."""
        response = client.post(
            "/auth/register",
            json={
                "email": "test@example.com",
                "username": "testuser",
                "password": "short",
            },
        )
        
        assert response.status_code == 422


class TestLogin:
    """Tests for user login."""
    
    def test_login_with_email_success(self, client, test_user):
        """Test successful login with email."""
        response = client.post(
            "/auth/login",
            data={
                "username": test_user["email"],
                "password": test_user["password"],
            },
        )
        
        assert response.status_code == 200
        data = response.json()
        assert "access_token" in data
        assert data["token_type"] == "bearer"
    
    def test_login_with_username_success(self, client, test_user):
        """Test successful login with username."""
        response = client.post(
            "/auth/login",
            data={
                "username": test_user["username"],
                "password": test_user["password"],
            },
        )
        
        assert response.status_code == 200
        data = response.json()
        assert "access_token" in data
    
    def test_login_wrong_password(self, client, test_user):
        """Test login with wrong password fails."""
        response = client.post(
            "/auth/login",
            data={
                "username": test_user["email"],
                "password": "wrongpassword",
            },
        )
        
        assert response.status_code == 401
        assert "Incorrect" in response.json()["detail"]
    
    def test_login_nonexistent_user(self, client):
        """Test login with non-existent user fails."""
        response = client.post(
            "/auth/login",
            data={
                "username": "nonexistent@example.com",
                "password": "password123",
            },
        )
        
        assert response.status_code == 401
