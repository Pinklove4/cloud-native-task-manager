#!/bin/bash
# =============================================================================
# Database Migration Script
# Manages Alembic migrations for the Task Manager API
# =============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Default values
COMMAND=${1:-"upgrade"}
REVISION=${2:-"head"}

# -----------------------------------------------------------------------------
# Help
# -----------------------------------------------------------------------------
show_help() {
    echo "Usage: ./migrate.sh [COMMAND] [REVISION]"
    echo ""
    echo "Commands:"
    echo "  upgrade [revision]    Apply migrations up to revision (default: head)"
    echo "  downgrade [revision]  Revert migrations down to revision"
    echo "  current               Show current revision"
    echo "  history               Show migration history"
    echo "  generate [message]    Generate new migration"
    echo "  init                  Initialize Alembic (first time setup)"
    echo ""
    echo "Examples:"
    echo "  ./migrate.sh upgrade                # Apply all pending migrations"
    echo "  ./migrate.sh upgrade head           # Apply all pending migrations"
    echo "  ./migrate.sh downgrade -1           # Revert last migration"
    echo "  ./migrate.sh generate 'Add tasks'   # Create new migration"
    echo ""
}

# -----------------------------------------------------------------------------
# Check if running in Docker or local
# -----------------------------------------------------------------------------
check_environment() {
    if [ -f /.dockerenv ]; then
        echo "Running inside Docker container"
        export PYTHONPATH=/app/src
    else
        echo "Running locally"
        # Activate virtual environment if exists
        if [ -d ".venv" ]; then
            source .venv/bin/activate
        fi
        export PYTHONPATH=src
    fi
}

# -----------------------------------------------------------------------------
# Initialize Alembic
# -----------------------------------------------------------------------------
init_alembic() {
    echo -e "${YELLOW}Initializing Alembic...${NC}"
    
    # Check if alembic.ini exists
    if [ -f "alembic.ini" ]; then
        echo -e "${YELLOW}Alembic already initialized${NC}"
        return
    fi
    
    # Initialize alembic
    cd src/app
    alembic init migrations
    
    # Update alembic.ini
    cat > ../../alembic.ini << 'EOF'
[alembic]
script_location = src/app/migrations
prepend_sys_path = .
version_path_separator = os

[post_write_hooks]

[loggers]
keys = root,sqlalchemy,alembic

[handlers]
keys = console

[formatters]
keys = generic

[logger_root]
level = WARN
handlers = console
qualname =

[logger_sqlalchemy]
level = WARN
handlers =
qualname = sqlalchemy.engine

[logger_alembic]
level = INFO
handlers =
qualname = alembic

[handler_console]
class = StreamHandler
args = (sys.stderr,)
level = NOTSET
formatter = generic

[formatter_generic]
format = %(levelname)-5.5s [%(name)s] %(message)s
datefmt = %H:%M:%S
EOF
    
    # Update env.py to use our models
    cat > migrations/env.py << 'EOF'
from logging.config import fileConfig
from sqlalchemy import engine_from_config, pool
from alembic import context
import os
import sys

# Add src to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.dirname(__file__))))

from app.core.config import settings
from app.models.base import Base
from app.models import User, Task

config = context.config
config.set_main_option("sqlalchemy.url", settings.DATABASE_URL)

if config.config_file_name is not None:
    fileConfig(config.config_file_name)

target_metadata = Base.metadata

def run_migrations_offline() -> None:
    url = config.get_main_option("sqlalchemy.url")
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
    )
    with context.begin_transaction():
        context.run_migrations()

def run_migrations_online() -> None:
    connectable = engine_from_config(
        config.get_section(config.config_ini_section, {}),
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )
    with connectable.connect() as connection:
        context.configure(connection=connection, target_metadata=target_metadata)
        with context.begin_transaction():
            context.run_migrations()

if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
EOF
    
    cd ../..
    echo -e "${GREEN}✓ Alembic initialized${NC}"
}

# -----------------------------------------------------------------------------
# Run Migrations
# -----------------------------------------------------------------------------
run_upgrade() {
    echo -e "${YELLOW}Running migrations upgrade to: ${REVISION}${NC}"
    alembic upgrade ${REVISION}
    echo -e "${GREEN}✓ Migrations applied${NC}"
}

run_downgrade() {
    echo -e "${YELLOW}Running migrations downgrade to: ${REVISION}${NC}"
    alembic downgrade ${REVISION}
    echo -e "${GREEN}✓ Migrations reverted${NC}"
}

show_current() {
    echo -e "${YELLOW}Current migration:${NC}"
    alembic current
}

show_history() {
    echo -e "${YELLOW}Migration history:${NC}"
    alembic history --verbose
}

generate_migration() {
    MESSAGE=${2:-"auto migration"}
    echo -e "${YELLOW}Generating migration: ${MESSAGE}${NC}"
    alembic revision --autogenerate -m "${MESSAGE}"
    echo -e "${GREEN}✓ Migration generated${NC}"
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------
case "$COMMAND" in
    help|--help|-h)
        show_help
        ;;
    init)
        check_environment
        init_alembic
        ;;
    upgrade)
        check_environment
        run_upgrade
        ;;
    downgrade)
        check_environment
        run_downgrade
        ;;
    current)
        check_environment
        show_current
        ;;
    history)
        check_environment
        show_history
        ;;
    generate)
        check_environment
        generate_migration "$@"
        ;;
    *)
        echo -e "${RED}Unknown command: ${COMMAND}${NC}"
        show_help
        exit 1
        ;;
esac
