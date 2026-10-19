#!/bin/bash

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}Matrix Synapse Status${NC}"
echo "===================="
echo

# Check if containers are running
echo -e "${YELLOW}Container Status:${NC}"
docker-compose ps

echo
echo -e "${YELLOW}Service Health:${NC}"

# Check PostgreSQL
if docker-compose exec -T postgres pg_isready -U synapse > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} PostgreSQL is running"
else
    echo -e "${RED}✗${NC} PostgreSQL is not responding"
fi

# Check Synapse
if docker-compose exec -T synapse curl -f http://localhost:8008/health > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Synapse is running"
else
    echo -e "${RED}✗${NC} Synapse is not responding"
fi

# Check Nginx
if docker-compose exec -T nginx nginx -t > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Nginx configuration is valid"
else
    echo -e "${RED}✗${NC} Nginx configuration has errors"
fi

echo
echo -e "${YELLOW}Disk Usage:${NC}"
docker-compose exec -T postgres du -sh /var/lib/postgresql/data 2>/dev/null || echo "PostgreSQL data: N/A"
docker-compose exec -T synapse du -sh /data 2>/dev/null || echo "Synapse data: N/A"

echo
echo -e "${YELLOW}Recent Logs (last 10 lines):${NC}"
docker-compose logs --tail=10

echo
echo "For full logs: docker-compose logs -f [service_name]"
echo "Services: postgres, synapse, nginx, certbot"
