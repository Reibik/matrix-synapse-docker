#!/bin/bash

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}Creating new Matrix user${NC}"
echo

read -p "Username: " username
read -sp "Password: " password
echo
read -p "Make admin? (y/N): " is_admin

ADMIN_FLAG=""
if [[ $is_admin =~ ^[Yy]$ ]]; then
    ADMIN_FLAG="-a"
fi

docker-compose exec synapse register_new_matrix_user \
    -u $username -p $password $ADMIN_FLAG -c /data/homeserver.yaml \
    http://localhost:8008

if [ $? -eq 0 ]; then
    source .env
    echo -e "${GREEN}User created successfully: @$username:$DOMAIN${NC}"
else
    echo -e "${RED}Failed to create user${NC}"
    exit 1
fi
