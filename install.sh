#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Print colored message
print_message() {
    echo -e "${GREEN}[*]${NC} $1"
}

print_error() {
    echo -e "${RED}[!]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    print_error "Please run as root (use sudo)"
    exit 1
fi

# Check if running on Ubuntu
if [ ! -f /etc/lsb-release ]; then
    print_error "This script is designed for Ubuntu 22.04/24.04"
    exit 1
fi

source /etc/lsb-release
if [[ "$DISTRIB_ID" != "Ubuntu" ]]; then
    print_error "This script is designed for Ubuntu"
    exit 1
fi

print_message "Starting Matrix Synapse installation..."
print_message "Distribution: $DISTRIB_DESCRIPTION"

# Check if .env file exists
if [ ! -f .env ]; then
    print_error ".env file not found!"
    print_message "Please copy .env.example to .env and configure it:"
    print_message "  cp .env.example .env"
    print_message "  nano .env"
    exit 1
fi

# Load environment variables
source .env

# Validate required variables
if [ -z "$DOMAIN" ] || [ "$DOMAIN" == "matrix.example.com" ]; then
    print_error "Please configure DOMAIN in .env file"
    exit 1
fi

if [ -z "$POSTGRES_PASSWORD" ] || [ "$POSTGRES_PASSWORD" == "CHANGE_THIS_STRONG_PASSWORD" ]; then
    print_error "Please set POSTGRES_PASSWORD in .env file"
    exit 1
fi

if [ -z "$SSL_EMAIL" ] || [ "$SSL_EMAIL" == "admin@example.com" ]; then
    print_error "Please set SSL_EMAIL in .env file"
    exit 1
fi

print_message "Configuration validated successfully"
print_message "Domain: $DOMAIN"
print_message "SSL Email: $SSL_EMAIL"

# Update system
print_message "Updating system packages..."
apt-get update -qq
apt-get upgrade -y -qq

# Install Docker if not installed
if ! command -v docker &> /dev/null; then
    print_message "Installing Docker..."
    apt-get install -y -qq ca-certificates curl gnupg lsb-release

    # Add Docker's official GPG key
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

    # Set up Docker repository
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

    apt-get update -qq
    apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-compose-plugin

    # Enable Docker service
    systemctl enable docker
    systemctl start docker

    print_message "Docker installed successfully"
else
    print_message "Docker is already installed"
fi

# Install Docker Compose if not installed
if ! command -v docker-compose &> /dev/null; then
    print_message "Installing Docker Compose..."
    DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
    curl -L "https://github.com/docker/compose/releases/download/v${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    print_message "Docker Compose installed successfully"
else
    print_message "Docker Compose is already installed"
fi

# Replace domain in nginx config
print_message "Configuring nginx..."
sed -i "s/DOMAIN_PLACEHOLDER/$DOMAIN/g" nginx/matrix.conf

# Check DNS
print_message "Checking DNS configuration..."
if host $DOMAIN > /dev/null 2>&1; then
    SERVER_IP=$(host $DOMAIN | grep "has address" | head -n 1 | awk '{print $4}')
    LOCAL_IP=$(curl -s ifconfig.me)

    if [ "$SERVER_IP" == "$LOCAL_IP" ]; then
        print_message "DNS is configured correctly ($SERVER_IP)"
    else
        print_warning "DNS mismatch! Domain points to $SERVER_IP but server IP is $LOCAL_IP"
        print_warning "SSL certificate will fail if DNS is not correct"
        read -p "Continue anyway? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
else
    print_warning "Cannot resolve domain $DOMAIN"
    print_warning "Please make sure DNS is configured before continuing"
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Start services
print_message "Starting Docker containers..."
docker-compose up -d postgres

print_message "Waiting for PostgreSQL to be ready..."
sleep 10

# Generate Synapse configuration
print_message "Generating Synapse configuration..."
docker-compose run --rm -e SYNAPSE_SERVER_NAME=$DOMAIN -e SYNAPSE_REPORT_STATS=$SYNAPSE_REPORT_STATS synapse generate

print_message "Starting all services..."
docker-compose up -d

print_message "Waiting for services to start..."
sleep 15

# Obtain SSL certificate
print_message "Obtaining SSL certificate from Let's Encrypt..."
docker-compose run --rm certbot certonly --webroot --webroot-path=/var/www/certbot \
    --email $SSL_EMAIL --agree-tos --no-eff-email -d $DOMAIN

if [ $? -eq 0 ]; then
    print_message "SSL certificate obtained successfully"

    # Enable HTTPS in nginx config
    print_message "Enabling HTTPS in nginx..."
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
    sed -i 's/#     location \.well-known/    location \.well-known/g' nginx/matrix.conf
    sed -i 's/#     }/    }/g' nginx/matrix.conf
    sed -i 's/#         proxy_/        proxy_/g' nginx/matrix.conf
    sed -i 's/#         return/        return/g' nginx/matrix.conf
    sed -i 's/#         add_header/        add_header/g' nginx/matrix.conf
    sed -i 's/#         client_/        client_/g' nginx/matrix.conf

    # Reload nginx
    docker-compose restart nginx

    print_message "HTTPS enabled successfully"
else
    print_warning "Failed to obtain SSL certificate"
    print_warning "You can try again later with: ./scripts/setup-ssl.sh"
fi

# Create admin user
if [ ! -z "$ADMIN_USERNAME" ] && [ ! -z "$ADMIN_PASSWORD" ]; then
    print_message "Creating admin user..."
    docker-compose exec -T synapse register_new_matrix_user \
        -u $ADMIN_USERNAME -p $ADMIN_PASSWORD -a -c /data/homeserver.yaml \
        http://localhost:8008

    if [ $? -eq 0 ]; then
        print_message "Admin user created: @$ADMIN_USERNAME:$DOMAIN"
    else
        print_warning "Failed to create admin user automatically"
        print_warning "You can create it manually with: ./scripts/create-user.sh"
    fi
fi

print_message ""
print_message "=================================================="
print_message "Matrix Synapse installation completed!"
print_message "=================================================="
print_message ""
print_message "Server URL: https://$DOMAIN"
print_message "Admin user: @$ADMIN_USERNAME:$DOMAIN"
print_message ""
print_message "You can now:"
print_message "  - Connect with Element: https://app.element.io"
print_message "  - Create more users: ./scripts/create-user.sh"
print_message "  - View logs: docker-compose logs -f"
print_message "  - Check status: docker-compose ps"
print_message ""
print_message "Useful commands:"
print_message "  - Stop: docker-compose stop"
print_message "  - Start: docker-compose start"
print_message "  - Restart: docker-compose restart"
print_message "  - Backup: ./scripts/backup.sh"
print_message ""
