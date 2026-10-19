#!/bin/bash

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

BACKUP_DIR="./backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="matrix_backup_$TIMESTAMP"

echo -e "${GREEN}Starting Matrix Synapse backup...${NC}"

mkdir -p $BACKUP_DIR/$BACKUP_NAME

# Backup PostgreSQL database
echo "Backing up PostgreSQL database..."
docker-compose exec -T postgres pg_dump -U synapse synapse > $BACKUP_DIR/$BACKUP_NAME/database.sql

# Backup Synapse data (media, keys, etc.)
echo "Backing up Synapse data..."
docker-compose exec -T synapse tar czf /tmp/synapse_data.tar.gz /data
docker cp synapse:/tmp/synapse_data.tar.gz $BACKUP_DIR/$BACKUP_NAME/
docker-compose exec -T synapse rm /tmp/synapse_data.tar.gz

# Backup configuration
echo "Backing up configuration..."
cp .env $BACKUP_DIR/$BACKUP_NAME/
cp docker-compose.yml $BACKUP_DIR/$BACKUP_NAME/
cp -r nginx $BACKUP_DIR/$BACKUP_NAME/

# Create final archive
echo "Creating backup archive..."
cd $BACKUP_DIR
tar czf $BACKUP_NAME.tar.gz $BACKUP_NAME
rm -rf $BACKUP_NAME

echo -e "${GREEN}Backup completed: $BACKUP_DIR/$BACKUP_NAME.tar.gz${NC}"
echo "Backup size: $(du -h $BACKUP_NAME.tar.gz | cut -f1)"
