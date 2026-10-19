#!/bin/bash

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}Matrix Synapse Update Script${NC}"
echo "=============================="
echo

# Check if running as root (optional for update)
if [ "$EUID" -ne 0 ]; then
    echo -e "${YELLOW}Note: Running without root. Some operations may require sudo.${NC}"
fi

# Check if docker-compose.yml exists
if [ ! -f docker-compose.yml ]; then
    echo -e "${RED}docker-compose.yml not found. Are you in the project directory?${NC}"
    exit 1
fi

# Show current version
echo -e "${YELLOW}Current Synapse version:${NC}"
docker-compose exec synapse python -c "import synapse; print(synapse.__version__)" 2>/dev/null || echo "Unable to determine (container may be stopped)"
echo

# Warning
echo -e "${YELLOW}WARNING:${NC}"
echo "This will update Matrix Synapse to the latest version."
echo "It's recommended to create a backup before updating."
echo

read -p "Create backup before updating? (Y/n): " create_backup

if [[ ! $create_backup =~ ^[Nn]$ ]]; then
    if [ -f ./scripts/backup.sh ]; then
        echo -e "${GREEN}Creating backup...${NC}"
        ./scripts/backup.sh
        echo
    else
        echo -e "${RED}Backup script not found. Please backup manually.${NC}"
        read -p "Continue without backup? (y/N): " continue_anyway
        if [[ ! $continue_anyway =~ ^[Yy]$ ]]; then
            exit 0
        fi
    fi
fi

# Pull latest images
echo -e "${GREEN}Pulling latest Docker images...${NC}"
docker-compose pull

# Check if there are updates
if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to pull images. Check your internet connection.${NC}"
    exit 1
fi

# Show what will be updated
echo
echo -e "${YELLOW}Images to update:${NC}"
docker-compose images

echo
read -p "Proceed with update? (Y/n): " proceed

if [[ $proceed =~ ^[Nn]$ ]]; then
    echo "Update cancelled."
    exit 0
fi

# Stop services
echo
echo -e "${GREEN}Stopping services...${NC}"
docker-compose stop

# Start services with new images
echo -e "${GREEN}Starting services with updated images...${NC}"
docker-compose up -d

# Wait for services to start
echo -e "${GREEN}Waiting for services to start...${NC}"
sleep 10

# Check health
echo
echo -e "${YELLOW}Checking service health...${NC}"

# Check PostgreSQL
if docker-compose exec -T postgres pg_isready -U synapse > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} PostgreSQL is running"
else
    echo -e "${RED}✗${NC} PostgreSQL is not responding"
fi

# Check Synapse
sleep 5
if docker-compose exec -T synapse curl -f http://localhost:8008/health > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Synapse is running"
else
    echo -e "${RED}✗${NC} Synapse is not responding"
    echo -e "${YELLOW}Checking logs...${NC}"
    docker-compose logs --tail=20 synapse
fi

# Show new version
echo
echo -e "${YELLOW}New Synapse version:${NC}"
docker-compose exec synapse python -c "import synapse; print(synapse.__version__)" 2>/dev/null || echo "Unable to determine"

# Run database migrations if needed
echo
echo -e "${YELLOW}Checking for database migrations...${NC}"
docker-compose exec synapse python -m synapse.app.homeserver --config-path=/data/homeserver.yaml --run-migrations

echo
echo -e "${GREEN}Update completed!${NC}"
echo
echo "Useful commands:"
echo "  - View logs: docker-compose logs -f synapse"
echo "  - Check status: ./scripts/status.sh"
echo "  - Rollback: ./scripts/restore.sh (restore from backup)"
