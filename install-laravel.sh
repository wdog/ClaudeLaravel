#!/bin/bash
# ============================================================================
# Laravel 12 + FilamentPHP v4 Installation Script
# Creates a new Laravel project in src/ with FilamentPHP and proper configuration
# ============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}"
echo "============================================="
echo "  Laravel 12 + FilamentPHP v4 Installer"
echo "============================================="
echo -e "${NC}"

# Check if src/ directory already exists with Laravel
if [ -d "src" ] && [ -f "src/artisan" ]; then
    echo -e "${RED}ERROR: Laravel project already exists in src/${NC}"
    echo "If you want to reinstall, remove the src/ directory first:"
    echo "  rm -rf src/"
    exit 1
fi

# Default configuration
DB_CONNECTION="mysql"
DB_HOST="db"
DB_PORT="3306"
DB_DATABASE="laravel"
DB_USERNAME="laravel"
DB_PASSWORD="laravel"
APP_ENV="local"
APP_NAME="LaravelApp"

# Interactive configuration
echo -e "${YELLOW}Configuration (press Enter to use defaults):${NC}"
echo ""

read -p "App Name [${APP_NAME}]: " input
APP_NAME=${input:-$APP_NAME}

read -p "Environment (local/production) [${APP_ENV}]: " input
APP_ENV=${input:-$APP_ENV}

read -p "Database Host [${DB_HOST}]: " input
DB_HOST=${input:-$DB_HOST}

read -p "Database Name [${DB_DATABASE}]: " input
DB_DATABASE=${input:-$DB_DATABASE}

read -p "Database User [${DB_USERNAME}]: " input
DB_USERNAME=${input:-$DB_USERNAME}

read -p "Database Password [${DB_PASSWORD}]: " input
DB_PASSWORD=${input:-$DB_PASSWORD}

echo ""
echo -e "${BLUE}Installing Laravel 12...${NC}"

# Create src directory
mkdir -p src

# Install Laravel 12 using Composer
docker run --rm -v "$(pwd)/src:/app" composer:latest \
    create-project laravel/laravel . --prefer-dist

echo -e "${GREEN}✓ Laravel installed${NC}"

# Generate APP_KEY if not exists
if ! grep -q "^APP_KEY=base64:" src/.env; then
    echo -e "${BLUE}Generating APP_KEY...${NC}"
    docker run --rm -v "$(pwd)/src:/var/www/html" -w /var/www/html php:8.4-cli \
        php artisan key:generate --ansi
    echo -e "${GREEN}✓ APP_KEY generated${NC}"
fi

# Configure .env file
echo -e "${BLUE}Configuring .env file...${NC}"

# Update APP_NAME
sed -i "s/^APP_NAME=.*/APP_NAME=\"${APP_NAME}\"/" src/.env

# Update APP_ENV
sed -i "s/^APP_ENV=.*/APP_ENV=${APP_ENV}/" src/.env

# Update APP_URL for HTTPS
sed -i "s|^APP_URL=.*|APP_URL=https://localhost:8443|" src/.env

# Update Database configuration
sed -i "s/^DB_CONNECTION=.*/DB_CONNECTION=${DB_CONNECTION}/" src/.env
sed -i "s/^DB_HOST=.*/DB_HOST=${DB_HOST}/" src/.env
sed -i "s/^DB_PORT=.*/DB_PORT=${DB_PORT}/" src/.env
sed -i "s/^DB_DATABASE=.*/DB_DATABASE=${DB_DATABASE}/" src/.env
sed -i "s/^DB_USERNAME=.*/DB_USERNAME=${DB_USERNAME}/" src/.env
sed -i "s/^DB_PASSWORD=.*/DB_PASSWORD=${DB_PASSWORD}/" src/.env

echo -e "${GREEN}✓ .env configured${NC}"

# Install FilamentPHP v4
echo -e "${BLUE}Installing FilamentPHP v4...${NC}"

docker run --rm -v "$(pwd)/src:/app" -w /app composer:latest \
    require filament/filament:"^4.0" -W --ignore-platform-reqs

echo -e "${GREEN}✓ FilamentPHP v4 installed${NC}"

# Install Filament Panel
echo -e "${BLUE}Setting up Filament Panel...${NC}"

docker run --rm -v "$(pwd)/src:/var/www/html" -w /var/www/html php:8.4-cli \
    php artisan filament:install --panels

echo -e "${GREEN}✓ Filament Panel configured${NC}"

# Install Laravel Debugbar if APP_ENV=local
if [ "$APP_ENV" = "local" ]; then
    echo -e "${BLUE}Installing Laravel Debugbar (development)...${NC}"
    docker run --rm -v "$(pwd)/src:/app" -w /app composer:latest \
        require barryvdh/laravel-debugbar --dev --ignore-platform-reqs
    echo -e "${GREEN}✓ Laravel Debugbar installed${NC}"
fi

# Set proper permissions and ownership
echo -e "${BLUE}Setting permissions and ownership...${NC}"
chmod -R 775 src/storage src/bootstrap/cache

# Fix ownership - all files should belong to current user, not root
CURRENT_USER=$(id -u)
CURRENT_GROUP=$(id -g)
echo "Changing ownership from root to ${CURRENT_USER}:${CURRENT_GROUP}..."
sudo chown -R ${CURRENT_USER}:${CURRENT_GROUP} src/

echo -e "${GREEN}✓ Permissions and ownership set${NC}"

# Create .gitignore for database/data if not exists
if [ ! -f ".gitignore" ]; then
    echo -e "${BLUE}Creating .gitignore...${NC}"
    cat > .gitignore <<'EOF'
# Database data
database/data/*
!database/data/.gitkeep

# Environment files
.env
.env.local
.env.*.local

# IDE
.idea/
.vscode/
*.swp
*.swo
.DS_Store
EOF
    echo -e "${GREEN}✓ .gitignore created${NC}"
fi

# Create database/data directory
mkdir -p database/data
touch database/data/.gitkeep

# Create database/config directory with my.cnf if not exists
if [ ! -f "database/config/my.cnf" ]; then
    echo -e "${BLUE}Creating MySQL configuration...${NC}"
    mkdir -p database/config
    cat > database/config/my.cnf <<'EOF'
[mysqld]
# Performance
max_connections = 200
innodb_buffer_pool_size = 256M
innodb_log_file_size = 64M
innodb_flush_log_at_trx_commit = 2
innodb_flush_method = O_DIRECT

# Character Set
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci

# Security
bind-address = 0.0.0.0

# Logging
general_log = 0
slow_query_log = 1
slow_query_log_file = /var/lib/mysql/slow-query.log
long_query_time = 2

[client]
default-character-set = utf8mb4
EOF
    echo -e "${GREEN}✓ MySQL configuration created${NC}"
fi

echo ""
echo -e "${GREEN}============================================="
echo "  Installation Complete!"
echo "=============================================${NC}"
echo ""
echo -e "${BLUE}Project Details:${NC}"
echo "  App Name: ${APP_NAME}"
echo "  Environment: ${APP_ENV}"
echo "  Database: ${DB_DATABASE}"
echo "  Database User: ${DB_USERNAME}"
echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo "  1. Build and start containers:"
echo -e "     ${YELLOW}docker-compose -f docker-compose.yml -f docker-compose.dev.yml up --build${NC}"
echo ""
echo "  2. Access your application:"
echo -e "     ${YELLOW}https://localhost:8443${NC}"
echo ""
echo "  3. Access Filament Admin Panel:"
echo -e "     ${YELLOW}https://localhost:8443/admin${NC}"
echo ""
echo "  4. Create Filament admin user (inside container):"
echo -e "     ${YELLOW}docker exec -it laravel-app php artisan make:filament-user${NC}"
echo ""
echo -e "${GREEN}Happy coding! 🚀${NC}"
