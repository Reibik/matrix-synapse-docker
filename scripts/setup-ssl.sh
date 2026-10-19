#!/bin/bash

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

if [ ! -f .env ]; then
    echo -e "${RED}.env file not found${NC}"
    exit 1
fi

source .env

if [ -z "$DOMAIN" ] || [ -z "$SSL_EMAIL" ]; then
    echo -e "${RED}DOMAIN or SSL_EMAIL not set in .env${NC}"
    exit 1
fi

echo -e "${GREEN}Obtaining SSL certificate for $DOMAIN${NC}"

# Obtain certificate
docker-compose run --rm certbot certonly --webroot --webroot-path=/var/www/certbot \
    --email $SSL_EMAIL --agree-tos --no-eff-email -d $DOMAIN

if [ $? -eq 0 ]; then
    echo -e "${GREEN}SSL certificate obtained successfully${NC}"
    echo "Enabling HTTPS in nginx configuration..."

    # Enable HTTPS in nginx config
    sed -i 's/# location \/ {/location \/ {/g' nginx/matrix.conf
    sed -i 's/#     return 301/    return 301/g' nginx/matrix.conf
    sed -i 's/# }/}/g' nginx/matrix.conf
    sed -i 's/# server {/server {/g' nginx/matrix.conf
    sed -i 's/#     listen/    listen/g' nginx/matrix.conf
    sed -i 's/#     server_name/    server_name/g' nginx/matrix.conf
    sed -i 's/#     ssl_/    ssl_/g' nginx/matrix.conf
    sed -i 's/#     client_/    client_/g' nginx/matrix.conf
    sed -i 's/#     location/    location/g' nginx/matrix.conf
    sed -i 's/#     proxy_/    proxy_/g' nginx/matrix.conf

    # Reload nginx
    docker-compose restart nginx

    echo -e "${GREEN}HTTPS enabled and nginx reloaded${NC}"
else
    echo -e "${RED}Failed to obtain SSL certificate${NC}"
    exit 1
fi
