#!/bin/bash

# ============================================================================
# Laravel 12 + FilamentPHP v4 Installation Script
# Creates a new Laravel project in src/ with FilamentPHP and proper configuration
#
# Usage:
#   ./install-laravel.sh           # Normal installation (fails if src/ exists)
#   ./install-laravel.sh --clean   # Clean install (removes src/ and database/data/)
# ============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Parse command line arguments
CLEAN_INSTALL=false
if [ "$1" = "--clean" ] || [ "$1" = "-c" ]; then
    CLEAN_INSTALL=true
fi

echo -e "${BLUE}"
echo "============================================="
echo "  Laravel 12 + FilamentPHP v4 Installer"
echo "============================================="
echo -e "${NC}"

# Stop running containers before installation
# Check if docker-compose.yml exists and has running containers
if [ -f "docker-compose.yml" ]; then
    if docker-compose ps --services --filter "status=running" 2>/dev/null | grep -q .; then
        echo -e "${YELLOW}Stopping running containers...${NC}"
        docker-compose down 2>/dev/null || true
        echo -e "${GREEN}✓ Containers stopped${NC}"
        echo ""
    fi
fi

# Clean install option
if [ "$CLEAN_INSTALL" = true ]; then
    echo -e "${YELLOW}⚠️  CLEAN INSTALL MODE${NC}"
    echo ""
    echo "This will DELETE:"
    echo "  - src/ (entire Laravel application)"
    echo "  - database/data/ (all MySQL data)"
    echo ""
    echo -e "${RED}WARNING: This action is IRREVERSIBLE!${NC}"
    echo ""
    # read -p "Are you sure you want to proceed? (yes/no): " confirmation

    # if [ "$confirmation" != "yes" ]; then
    #     echo -e "${CYAN}Installation cancelled.${NC}"
    #     exit 0
    # fi

    echo ""
    echo -e "${BLUE}Removing existing installation...${NC}"

    # Remove src/ directory with proper permission handling
    if [ -d "src" ]; then
        echo -e "${YELLOW}Removing src/ directory...${NC}"

        # Use Docker to remove vendor/ and node_modules/ with correct permissions
        if [ -d "src/vendor" ] || [ -d "src/node_modules" ]; then
            echo -e "${YELLOW}Removing vendor/ and node_modules/ using Docker (correct permissions)...${NC}"
            docker run --rm -v "$(pwd)/src:/app" alpine:latest sh -c "rm -rf /app/vendor /app/node_modules"
        fi

        # Now remove the rest with regular rm
        if ! rm -rf src/ 2>/dev/null; then
            echo -e "${YELLOW}Permission denied, trying with sudo...${NC}"
            sudo rm -rf src/
        fi

        echo -e "${GREEN}✓ src/ removed${NC}"
    fi

    # Remove database data
    if [ -d "database/data" ]; then
        echo -e "${YELLOW}Removing database/data/ directory...${NC}"

        # Try Docker Alpine first to handle MySQL files with correct permissions
        if [ -n "$(ls -A database/data 2>/dev/null)" ]; then
            echo -e "${YELLOW}Attempting to remove MySQL data using Docker...${NC}"
            if docker run --rm -v "$(pwd)/database/data:/data" alpine:latest sh -c "rm -rf /data/*" 2>/dev/null; then
                echo -e "${GREEN}✓ MySQL data removed via Docker${NC}"
            else
                echo -e "${YELLOW}Docker cleanup failed, trying with sudo...${NC}"
            fi
        fi

        # Fallback to sudo if Docker fails or files still exist
        if [ -n "$(ls -A database/data 2>/dev/null)" ]; then
            echo -e "${YELLOW}Using sudo to remove MySQL data (requires password)...${NC}"
            sudo rm -rf database/data/*
            echo -e "${GREEN}✓ MySQL data removed via sudo${NC}"
        fi

        echo -e "${GREEN}✓ database/data/ cleaned${NC}"
    fi

    echo -e "${GREEN}✓ Cleanup complete${NC}"
    echo ""
fi

# Check if src/ directory already exists with Laravel
if [ -d "src" ] && [ -f "src/artisan" ]; then
    echo -e "${RED}ERROR: Laravel project already exists in src/${NC}"
    echo ""
    echo "Options:"
    echo -e "  1. ${GREEN}Recommended:${NC} Run with --clean flag (handles permissions correctly):"
    echo -e "     ${YELLOW}./install-laravel.sh --clean${NC}"
    echo ""
    echo "  2. Manual removal (may require sudo for vendor/ and database/data/):"
    echo -e "     ${YELLOW}rm -rf src/ database/data/*${NC}"
    echo ""
    exit 1
fi

# Default configuration
DB_CONNECTION="mysql"
DB_HOST="mysql"  # MUST be 'mysql' (Docker container name in docker-compose.yml)
DB_PORT="3306"
DB_DATABASE="laravel"
DB_USERNAME="laravel"
DB_PASSWORD="laravel"
APP_ENV="local"
APP_NAME="LaravelApp"

# Detect LAN IP as default
DEFAULT_HOST=$(ip route get 1.1.1.1 2>/dev/null | grep -oP 'src \K\S+' || echo "localhost")
APP_HOST="${DEFAULT_HOST}"

# Interactive configuration (skip if --clean flag is used)
if [ "$CLEAN_INSTALL" = false ]; then
    echo -e "${YELLOW}Configuration (press Enter to use defaults):${NC}"
    echo ""

    read -p "App Name [${APP_NAME}]: " input
    APP_NAME=${input:-$APP_NAME}

    read -p "Environment (local/production) [${APP_ENV}]: " input
    APP_ENV=${input:-$APP_ENV}

    echo ""
    echo -e "${CYAN}Application Host (IP or domain name):${NC}"
    echo "  Use your LAN IP to access from other devices (phone, tablet, etc.)"
    echo "  Use 'localhost' for local-only development"
    read -p "Host [${DEFAULT_HOST}]: " input
    APP_HOST=${input:-$DEFAULT_HOST}

    # DB_HOST is always 'mysql' for Docker - do not ask user
    echo ""
    echo -e "${CYAN}Database Host: ${DB_HOST} (fixed for Docker)${NC}"

    read -p "Database Name [${DB_DATABASE}]: " input
    DB_DATABASE=${input:-$DB_DATABASE}

    read -p "Database User [${DB_USERNAME}]: " input
    DB_USERNAME=${input:-$DB_USERNAME}

    read -p "Database Password [${DB_PASSWORD}]: " input
    DB_PASSWORD=${input:-$DB_PASSWORD}
else
    echo -e "${YELLOW}Using default configuration (--clean flag)${NC}"
    echo "  App Name: ${APP_NAME}"
    echo "  Environment: ${APP_ENV}"
    echo "  Host: ${APP_HOST}"
    echo "  Database Host: ${DB_HOST} (fixed for Docker)"
    echo "  Database: ${DB_DATABASE}"
    echo "  Database User: ${DB_USERNAME}"
fi

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
    docker run --rm -v "$(pwd)/src:/app" -w /app php:8.4-cli \
        php artisan key:generate --ansi
    echo -e "${GREEN}✓ APP_KEY generated${NC}"
fi

# Configure .env file
echo -e "${BLUE}Configuring .env file...${NC}"

# Update APP_NAME
sed -i "s/^APP_NAME=.*/APP_NAME=\"${APP_NAME}\"/" src/.env

# Update APP_ENV
sed -i "s/^APP_ENV=.*/APP_ENV=${APP_ENV}/" src/.env

# Update APP_URL for HTTPS (always use HTTPS with self-signed certificate)
# Always use port 443 (standard HTTPS port)
APP_URL="https://${APP_HOST}"
sed -i "s|^APP_URL=.*|APP_URL=${APP_URL}|" src/.env

# Set ASSET_URL to ensure assets are served via HTTPS
# Check if ASSET_URL exists in .env, if not add it
if grep -q "^ASSET_URL=" src/.env; then
    sed -i "s|^ASSET_URL=.*|ASSET_URL=${APP_URL}|" src/.env
else
    echo "ASSET_URL=${APP_URL}" >> src/.env
fi

echo -e "${GREEN}✓ APP_URL and ASSET_URL set to ${APP_URL}${NC}"


# Set VITE_HMR_HOST to ensure assets are served via HTTPS
# Check if VITE_HMR_HOST exists in .env, if not add it
if grep -q "^VITE_HMR_HOST=" src/.env; then
    sed -i "s|^VITE_HMR_HOST=.*|VITE_HMR_HOST=${APP_HOST}|" src/.env
else
    echo "VITE_HMR_HOST=${APP_HOST}" >> src/.env
fi

echo -e "${GREEN}✓ VITE_HMR_HOST set to ${APP_HOST}${NC}"






# Update Database configuration
# Laravel 12 has commented DB_ lines by default, so we need to uncomment and set them
sed -i "s/^DB_CONNECTION=.*/DB_CONNECTION=${DB_CONNECTION}/" src/.env
sed -i "s/^# DB_HOST=.*/DB_HOST=${DB_HOST}/" src/.env || sed -i "s/^DB_HOST=.*/DB_HOST=${DB_HOST}/" src/.env
sed -i "s/^# DB_PORT=.*/DB_PORT=${DB_PORT}/" src/.env || sed -i "s/^DB_PORT=.*/DB_PORT=${DB_PORT}/" src/.env
sed -i "s/^# DB_DATABASE=.*/DB_DATABASE=${DB_DATABASE}/" src/.env || sed -i "s/^DB_DATABASE=.*/DB_DATABASE=${DB_DATABASE}/" src/.env
sed -i "s/^# DB_USERNAME=.*/DB_USERNAME=${DB_USERNAME}/" src/.env || sed -i "s/^DB_USERNAME=.*/DB_USERNAME=${DB_USERNAME}/" src/.env
sed -i "s/^# DB_PASSWORD=.*/DB_PASSWORD=${DB_PASSWORD}/" src/.env || sed -i "s/^DB_PASSWORD=.*/DB_PASSWORD=${DB_PASSWORD}/" src/.env

echo -e "${GREEN}✓ .env configured${NC}"

# Install FilamentPHP v4
echo -e "${BLUE}Installing FilamentPHP v4...${NC}"

docker run --rm -v "$(pwd)/src:/app" -w /app composer:latest \
    require filament/filament:"^4.0" -W --ignore-platform-reqs

echo -e "${GREEN}✓ FilamentPHP v4 installed${NC}"

# Install Filament Panel
echo -e "${BLUE}Setting up Filament Panel...${NC}"

docker run --rm -v "$(pwd)/src:/app" -w /app php:8.4-cli \
    php artisan filament:install --panels --no-interaction

echo -e "${GREEN}✓ Filament Panel configured${NC}"

# Install Laravel Debugbar if APP_ENV=local
if [ "$APP_ENV" = "local" ]; then
    echo -e "${BLUE}Installing Laravel Debugbar (development)...${NC}"
    docker run --rm -v "$(pwd)/src:/app" -w /app composer:latest \
        require barryvdh/laravel-debugbar --dev --ignore-platform-reqs
    echo -e "${GREEN}✓ Laravel Debugbar installed${NC}"
fi

# Configure Vite for development
if [ "$APP_ENV" = "local" ]; then
    echo -e "${BLUE}Configuring Vite for HTTPS and HMR...${NC}"

    # Patch vite.config.js to add HTTPS, HMR host, and Filament theme
    # Create temp file first, then move with sudo
    cat > /tmp/vite.config.js.tmp <<'VITE_CONFIG'
import { defineConfig, loadEnv } from 'vite';
import tailwindcss from '@tailwindcss/vite';
import laravel, { refreshPaths } from 'laravel-vite-plugin'
import fs from 'fs';

export default defineConfig(({ mode }) => {
    // Load env file based on `mode` in the current working directory.
    const env = loadEnv(mode, process.cwd(), '');
    const hmrHost = env.VITE_HMR_HOST || 'localhost';

    return {
        plugins: [
            laravel({
                input: [
                    'resources/css/app.css',
                    'resources/js/app.js',
                    'resources/css/filament/dinner/theme.css'
                ],
                refresh: [
                    ...refreshPaths,
                    "app/Livewire/**",
                    "app/Filament/**",
                    "app/Providers/Filament/**",
                    "resources/views/**"
                ],
                detectTls: false,
            }),
            tailwindcss(),
        ],
        server: {
            https: {
                key: fs.readFileSync('/etc/nginx/ssl/nginx.key'),
                cert: fs.readFileSync('/etc/nginx/ssl/nginx.crt'),
            },
            host: "0.0.0.0",
            port: 5173,
            strictPort: true,
            hmr: {
                protocol: 'wss',
                clientPort: 5173,
                host: hmrHost,
            },
            watch: {
                // usePolling: true, // Uncomment if file watching doesn't work
            }
        },
    };
});
VITE_CONFIG

    # Move temp file to src/ with sudo and fix ownership
    sudo mv /tmp/vite.config.js.tmp src/vite.config.js
    sudo chown ${CURRENT_USER}:${CURRENT_GROUP} src/vite.config.js
    sudo chmod 644 src/vite.config.js

    echo -e "${GREEN}✓ vite.config.js configured for HTTPS and HMR${NC}"

    # Development: install dependencies only (Vite will run in dev mode)
    echo -e "${BLUE}Installing NPM dependencies (Vite, etc.)...${NC}"
    docker run --rm -v "$(pwd)/src:/app" -w /app node:20-alpine \
        npm install
    echo -e "${GREEN}✓ NPM dependencies installed${NC}"



else
    # Production: install dependencies and build assets
    echo -e "${BLUE}Installing NPM dependencies...${NC}"
    docker run --rm -v "$(pwd)/src:/app" -w /app node:20-alpine \
        npm install
    echo -e "${GREEN}✓ NPM dependencies installed${NC}"

    echo -e "${BLUE}Building production assets...${NC}"
    docker run --rm -v "$(pwd)/src:/app" -w /app node:20-alpine \
        npm run build
    echo -e "${GREEN}✓ Production assets built${NC}"
fi

# Set proper permissions and ownership
echo -e "${BLUE}Setting permissions and ownership...${NC}"

# Get current user/group IDs
CURRENT_USER=$(id -u)
CURRENT_GROUP=$(id -g)

# Use Docker to fix ownership (avoids sudo for most files)
echo -e "${YELLOW}Fixing ownership using Docker (${CURRENT_USER}:${CURRENT_GROUP})...${NC}"
docker run --rm -v "$(pwd)/src:/app" alpine:latest sh -c "chown -R ${CURRENT_USER}:${CURRENT_GROUP} /app"

# Create storage subdirectories if they don't exist
echo -e "${YELLOW}Ensuring storage directories exist...${NC}"
mkdir -p src/storage/framework/{cache,sessions,views,testing}
mkdir -p src/storage/{app,logs}

# Set permissions with sudo to ensure they work correctly with Docker
# 777 = rwxrwxrwx (needed for both host user and www-data in container)
echo -e "${YELLOW}Setting permissions (requires sudo)...${NC}"
sudo chmod -R 775 src
sudo chmod -R 777 src/storage src/bootstrap/cache src/public

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
mkdir -p database/{data,config}
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
echo -e "     ${YELLOW}https://${IP}${NC} (HTTPS - self-signed certificate)"
echo -e "     ${YELLOW}http://${IP}${NC} (HTTP - redirects to HTTPS)"
echo ""
echo -e "  ${GREEN}Note:${NC} Your browser will show a security warning because we use"
echo "  a self-signed SSL certificate. This is normal for development."
echo "  Click 'Advanced' and 'Proceed to ${IP}' to continue."
echo ""
echo "  3. Access Filament Admin Panel:"
echo -e "     ${YELLOW}https://${IP}/admin${NC}"
echo ""
echo "  4. Create Filament admin user (inside container):"
echo -e "     ${YELLOW}docker exec -it laravel-app php artisan make:filament-user${NC}"
echo ""
echo -e "${CYAN}Tip:${NC} To reinstall from scratch, use:"
echo -e "     ${YELLOW}./install-laravel.sh --clean${NC}"
echo ""
echo -e "${CYAN}Fix storage permissions if needed:${NC}"
echo -e "     ${YELLOW}docker exec -it laravel-app chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache${NC}"
sudo chmod -R 775 ap/cache${NC}"
echo -e "     ${YELLOW}docker exec -it laravel-app chmod -R 775 /var/www/html/storage /var/www/html/bootstr
echo ""
echo -e "${GREEN}Happy coding! 🚀${NC}"
