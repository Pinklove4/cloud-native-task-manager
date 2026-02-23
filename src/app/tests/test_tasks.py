"""Tests for task endpoints."""

import pytest


class TestCreateTask:
    """Tests for task creation."""
    
    def test_create_task_success(self, client, auth_headers):
        """Test successful task creation."""
        response = client.post(
            "/tasks",
            json={
                "title": "Test Task",
                "description": "This is a test task",
                "status": "todo",
            },
            headers=auth_headers,
        )
        
        assert response.status_code == 201
        data = response.json()
        assert data["title"] == "Test Task"
        assert data["description"] == "This is a test task"
        assert data["status"] == "todo"
        assert "id" in data
        assert "created_at" in data
        assert "updated_at" in data
    
    def test_create_task_minimal(self, client, auth_headers):
        """Test task creation with minimal data."""
        response = client.post(
            "/tasks",
            json={"title": "Minimal Task"},
            headers=auth_headers,
        )
        
        assert response.status_code == 201
        data = response.json()
        assert data["title"] == "Minimal Task"
        assert data["status"] == "todo"
        assert data["description"] is None
    
    def test_create_task_unauthenticated(self, client):
        """Test task creation without auth fails."""
        response = client.post(
            "/tasks",
            json={"title": "Test Task"},
        )
        
        assert response.status_code == 401
    
    def test_create_task_empty_title(self, client, auth_headers):
        """Test task creation with empty title fails."""
        response = client.post(
            "/tasks",
            json={"title": ""},
            headers=auth_headers,
        )
        
        assert response.status_code == 422


class TestListTasks:
    """Tests for listing tasks."""
    
    def test_list_tasks_empty(self, client, auth_headers):
        """Test listing tasks when none exist."""
        response = client.get("/tasks", headers=auth_headers)
        
        assert response.status_code == 200
        data = response.json()
        assert data["tasks"] == []
        assert data["total"] == 0
    
    def test_list_tasks_with_tasks(self, client, auth_headers):
        """Test listing tasks returns user's tasks."""
        # Create some tasks
        for i in range(3):
            client.post(
                "/tasks",
                json={"title": f"Task {i}"},
                headers=auth_headers,
            )
        
        response = client.get("/tasks", headers=auth_headers)
        
        assert response.status_code == 200
        data = response.json()
        assert len(data["tasks"]) == 3
        assert data["total"] == 3
    
    def test_list_tasks_with_status_filter(self, client, auth_headers):
        """Test filtering tasks by status."""
        # Create tasks with different statuses
        client.post(
            "/tasks",
            json={"title": "Todo Task", "status": "todo"},
            headers=auth_headers,
        )
        client.post(
            "/tasks",
            json={"title": "Doing Task", "status": "doing"},
            headers=auth_headers,
        )
        
        response = client.get("/tasks?status=todo", headers=auth_headers)
        
        assert response.status_code == 200
        data = response.json()
        assert len(data["tasks"]) == 1
        assert data["tasks"][0]["title"] == "Todo Task"
    
    def test_list_tasks_pagination(self, client, auth_headers):
        """Test task pagination."""
        # Create 5 tasks
        for i in range(5):
            client.post(
                "/tasks",
                json={"title": f"Task {i}"},
                headers=auth_headers,
            )
        
        # Get first page
        response = client.get("/tasks?page=1&page_size=2", headers=auth_headers)
        
        assert response.status_code == 200
        data = response.json()
        assert len(data["tasks"]) == 2
        assert data["total"] == 5
        assert data["page"] == 1
        assert data["page_size"] == 2


class TestGetTask:
    """Tests for getting a single task."""
    
    def test_get_task_success(self, client, auth_headers):
        """Test getting a task by ID."""
        # Create a task
        create_response = client.post(
            "/tasks",
            json={"title": "Test Task"},
            headers=auth_headers,
        )
        task_id = create_response.json()["id"]
        
        # Get the task
        response = client.get(f"/tasks/{task_id}", headers=auth_headers)
        
        assert response.status_code == 200
        assert response.json()["title"] == "Test Task"
    
    def test_get_task_not_found(self, client, auth_headers):
        """Test getting non-existent task returns 404."""
        response = client.get("/tasks/99999", headers=auth_headers)
        
        assert response.status_code == 404


class TestUpdateTask:
    """Tests for updating tasks."""
    
    def test_update_task_success(self, client, auth_headers):
        """Test updating a task."""
        # Create a task
        create_response = client.post(
            "/tasks",
            json={"title": "Original Title"},
            headers=auth_headers,
        )
        task_id = create_response.json()["id"]
        
        # Update the task
        response = client.put(
            f"/tasks/{task_id}",
            json={"title": "Updated Title", "status": "doing"},
            headers=auth_headers,
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["title"] == "Updated Title"
        assert data["status"] == "doing"
    
    def test_update_task_partial(self, client, auth_headers):
        """Test partial task update."""
        # Create a task
        create_response = client.post(
            "/tasks",
            json={"title": "Test Task", "description": "Original"},
            headers=auth_headers,
        )
        task_id = create_response.json()["id"]
        
        # Update only status
        response = client.put(
            f"/tasks/{task_id}",
            json={"status": "done"},
            headers=auth_headers,
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["title"] == "Test Task"
        assert data["description"] == "Original"
        assert data["status"] == "done"
    
    def test_update_task_not_found(self, client, auth_headers):
        """Test updating non-existent task returns 404."""
        response = client.put(
            "/tasks/99999",
            json={"title": "Test"},
            headers=auth_headers,
        )
        
        assert response.status_code == 404


class TestDeleteTask:
    """Tests for deleting tasks."""
    
    def test_delete_task_success(self, client, auth_headers):
        """Test deleting a task."""
        # Create a task
        create_response = client.post(
            "/tasks",
            json={"title": "Test Task"},
            headers=auth_headers,
        )
        task_id = create_response.json()["id"]
        
        # Delete the task
        response = client.delete(f"/tasks/{task_id}", headers=auth_headers)
        
        assert response.status_code == 204
        
        # Verify it's deleted
        get_response = client.get(f"/tasks/{task_id}", headers=auth_headers)
        assert get_response.status_code == 404
    
    def test_delete_task_not_found(self, client, auth_headers):
        """Test deleting non-existent task returns 404."""
        response = client.delete("/tasks/99999", headers=auth_headers)
        
        assert response.status_code == 404
