#!/bin/bash

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

BACKUP_DIR="./backups"

echo -e "${GREEN}Matrix Synapse Restore${NC}"
echo

if [ ! -d "$BACKUP_DIR" ]; then
    echo -e "${RED}Backup directory not found${NC}"
    exit 1
fi

echo "Available backups:"
ls -lh $BACKUP_DIR/*.tar.gz 2>/dev/null || { echo -e "${RED}No backups found${NC}"; exit 1; }

echo
read -p "Enter backup filename (without path): " backup_file

if [ ! -f "$BACKUP_DIR/$backup_file" ]; then
    echo -e "${RED}Backup file not found${NC}"
    exit 1
fi

echo -e "${YELLOW}WARNING: This will overwrite current data!${NC}"
read -p "Continue? (yes/NO): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Restore cancelled"
    exit 0
fi

# Extract backup
echo "Extracting backup..."
TEMP_DIR=$(mktemp -d)
tar xzf $BACKUP_DIR/$backup_file -C $TEMP_DIR
BACKUP_NAME=$(basename $backup_file .tar.gz)

# Stop services
echo "Stopping services..."
docker-compose stop synapse postgres

# Restore database
echo "Restoring PostgreSQL database..."
docker-compose start postgres
sleep 5
docker-compose exec -T postgres dropdb -U synapse synapse --if-exists
docker-compose exec -T postgres createdb -U synapse synapse
docker-compose exec -T postgres psql -U synapse synapse < $TEMP_DIR/$BACKUP_NAME/database.sql

# Restore Synapse data
echo "Restoring Synapse data..."
docker cp $TEMP_DIR/$BACKUP_NAME/synapse_data.tar.gz synapse:/tmp/
docker-compose exec -T synapse tar xzf /tmp/synapse_data.tar.gz -C /
docker-compose exec -T synapse rm /tmp/synapse_data.tar.gz

# Clean up
rm -rf $TEMP_DIR

# Start services
echo "Starting services..."
docker-compose start

echo -e "${GREEN}Restore completed successfully${NC}"
echo "Please check logs: docker-compose logs -f"
