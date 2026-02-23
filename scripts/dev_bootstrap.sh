#!/bin/bash
# =============================================================================
# Development Bootstrap Script
# Sets up the local development environment
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Task Manager API - Development Bootstrap ===${NC}"

# -----------------------------------------------------------------------------
# Check Prerequisites
# -----------------------------------------------------------------------------
echo -e "\n${YELLOW}Checking prerequisites...${NC}"

# Check for Python
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}Python 3 is required but not installed.${NC}"
    exit 1
fi
echo "✓ Python 3 found: $(python3 --version)"

# Check for Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Docker is required but not installed.${NC}"
    exit 1
fi
echo "✓ Docker found: $(docker --version)"

# Check for Docker Compose
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo -e "${RED}Docker Compose is required but not installed.${NC}"
    exit 1
fi
echo "✓ Docker Compose found"

# -----------------------------------------------------------------------------
# Set up Environment File
# -----------------------------------------------------------------------------
echo -e "\n${YELLOW}Setting up environment...${NC}"

if [ ! -f .env ]; then
    cp .env.example .env
    echo "✓ Created .env file from .env.example"
    
    # Generate a random JWT secret
    JWT_SECRET=$(openssl rand -base64 32 2>/dev/null || python3 -c "import secrets; print(secrets.token_urlsafe(32))")
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s|<CHANGE_ME_TO_A_SECURE_RANDOM_STRING>|${JWT_SECRET}|g" .env
    else
        sed -i "s|<CHANGE_ME_TO_A_SECURE_RANDOM_STRING>|${JWT_SECRET}|g" .env
    fi
    echo "✓ Generated JWT secret key"
else
    echo "✓ .env file already exists"
fi

# -----------------------------------------------------------------------------
# Create Python Virtual Environment (optional, for local development without Docker)
# -----------------------------------------------------------------------------
echo -e "\n${YELLOW}Setting up Python virtual environment...${NC}"

if [ ! -d ".venv" ]; then
    python3 -m venv .venv
    echo "✓ Created virtual environment"
fi

# Activate and install dependencies
source .venv/bin/activate
pip install --upgrade pip > /dev/null
pip install -e ".[dev]" > /dev/null
echo "✓ Installed Python dependencies"

# -----------------------------------------------------------------------------
# Install Pre-commit Hooks
# -----------------------------------------------------------------------------
echo -e "\n${YELLOW}Setting up pre-commit hooks...${NC}"

if command -v pre-commit &> /dev/null; then
    pre-commit install
    echo "✓ Installed pre-commit hooks"
else
    pip install pre-commit > /dev/null
    pre-commit install
    echo "✓ Installed pre-commit and hooks"
fi

# -----------------------------------------------------------------------------
# Pull Docker Images
# -----------------------------------------------------------------------------
echo -e "\n${YELLOW}Pulling Docker images...${NC}"

docker pull postgres:15-alpine
echo "✓ Pulled PostgreSQL image"

# -----------------------------------------------------------------------------
# Build Application Image
# -----------------------------------------------------------------------------
echo -e "\n${YELLOW}Building application image...${NC}"

docker build -f docker/Dockerfile -t task-manager-api:dev .
echo "✓ Built application Docker image"

# -----------------------------------------------------------------------------
# Start Services
# -----------------------------------------------------------------------------
echo -e "\n${YELLOW}Starting services...${NC}"

# Use docker compose (v2) or docker-compose (v1)
if docker compose version &> /dev/null; then
    docker compose -f deploy/docker-compose.yml up -d db
else
    docker-compose -f deploy/docker-compose.yml up -d db
fi

echo "✓ Started PostgreSQL"

# Wait for database to be ready
echo "Waiting for database to be ready..."
sleep 5

# -----------------------------------------------------------------------------
# Run Database Migrations
# -----------------------------------------------------------------------------
echo -e "\n${YELLOW}Running database migrations...${NC}"

# For now, we'll create tables via SQLAlchemy
# In production, use Alembic migrations
echo "Note: In development mode, tables are created automatically on startup"

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------
echo -e "\n${GREEN}=== Bootstrap Complete! ===${NC}"
echo ""
echo "To start the full stack:"
echo "  docker-compose -f deploy/docker-compose.yml up --build"
echo ""
echo "To start the API in development mode (with hot reload):"
echo "  source .venv/bin/activate"
echo "  uvicorn app.main:app --reload"
echo ""
echo "To run tests:"
echo "  pytest src/app/tests/ -v"
echo ""
echo "API will be available at:"
echo "  - http://localhost:8000"
echo "  - Swagger docs: http://localhost:8000/docs"
echo ""
