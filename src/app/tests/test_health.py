"""Tests for health check endpoints."""

import pytest


class TestHealth:
    """Tests for health endpoints."""
    
    def test_health_check(self, client):
        """Test health check returns healthy status."""
        response = client.get("/health")
        
        assert response.status_code == 200
        data = response.json()
        assert data["status"] in ["healthy", "degraded"]
        assert "database" in data
        assert "version" in data
    
    def test_readiness_check(self, client):
        """Test readiness probe."""
        response = client.get("/ready")
        
        assert response.status_code == 200
        assert response.json()["ready"] is True
    
    def test_liveness_check(self, client):
        """Test liveness probe."""
        response = client.get("/live")
        
        assert response.status_code == 200
        assert response.json()["alive"] is True
