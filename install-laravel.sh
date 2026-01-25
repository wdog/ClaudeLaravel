#!/bin/bash

# ============================================================================
# Laravel 12 + FilamentPHP v5 Installation Script
# Creates a new Laravel project in src/ with FilamentPHP and proper configuration
# ============================================================================

set -e

DOCKER_RUN="docker run --rm -u$(id -u):$(id -g) -v $(pwd)/src:/app -w /app"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Show help
show_help() {
    echo -e "${BLUE}Laravel 12 + FilamentPHP v5 Installer${NC}"
    echo ""
    echo "Usage: ./install-laravel.sh [options]"
    echo ""
    echo "Options:"
    echo "  --install, -i        Install new Laravel project (fails if src/ exists)"
    echo "  --install-clean, -c  Remove src/ and database/data/, then install"
    echo "  --force, -f          Skip interactive prompts, use .env.install defaults"
    echo "  --help, -h           Show this help message"
    echo ""
    echo "Examples:"
    echo "Examples:"
    echo "  ./install-laravel.sh -i       # New installation (interactive)"
    echo "  ./install-laravel.sh -c       # Clean and reinstall (interactive)"
    echo "  ./install-laravel.sh -if      # New installation with defaults"
    echo "  ./install-laravel.sh -cf      # Clean and reinstall with defaults"
    echo ""
    echo -e "${YELLOW}Configuration:${NC}"
    echo "  Edit .env.install to customize default values before installing."
    exit 0
}

# Parse command line arguments
DO_INSTALL=false
CLEAN_INSTALL=false
SKIP_INTERACTIVE=false

for arg in "$@"; do
    case $arg in
        --help|-h)
            show_help
            ;;
        --install|-i)
            DO_INSTALL=true
            ;;
        --install-clean|-c)
            DO_INSTALL=true
            CLEAN_INSTALL=true
            ;;
        --force|-f)
            SKIP_INTERACTIVE=true
            ;;
        -*)
            # Handle combined short flags like -if, -cf, -icf
            if [[ "$arg" =~ i ]]; then DO_INSTALL=true; fi
            if [[ "$arg" =~ c ]]; then DO_INSTALL=true; CLEAN_INSTALL=true; fi
            if [[ "$arg" =~ f ]]; then SKIP_INTERACTIVE=true; fi
            ;;
    esac
done

# Show help if no arguments
if [ $# -eq 0 ]; then
    show_help
fi

# Exit if not installing
if [ "$DO_INSTALL" = false ]; then
    show_help
fi

echo -e "${BLUE}"
echo "============================================="
echo "  Laravel 12 + FilamentPHP v5 Installer"
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

# Clean install - remove existing data
if [ "$CLEAN_INSTALL" = true ]; then
    if [ -d "src" ]; then
        echo -e "${YELLOW}Removing src/ directory...${NC}"
        if ! rm -rf src/ 2>/dev/null; then
            sudo rm -rf src/
        fi
        echo -e "${GREEN}✓ src/ removed${NC}"
    fi

    if [ -d "database/data" ] && [ -n "$(ls -A database/data 2>/dev/null)" ]; then
        echo -e "${YELLOW}Removing database/data/...${NC}"
        sudo rm -rf database/data/*
        echo -e "${GREEN}✓ database/data/ removed${NC}"
    fi
    echo ""
fi

# Check if src/ directory already exists (only for --install, not --install-clean)
if [ -d "src" ] && [ -f "src/artisan" ]; then
    echo -e "${RED}ERROR: Laravel project already exists in src/${NC}"
    echo ""
    echo "Use --install-clean (-c) to remove and reinstall."
    exit 1
fi

# Load defaults from .env.install if exists, otherwise use hardcoded defaults
if [ -f ".env.install" ]; then
    source .env.install
    echo -e "${GREEN}✓ Loaded configuration from .env.install${NC}"
    echo ""
else
    # Default configuration
    APP_NAME="LaravelApp"
    APP_ENV="local"
    DB_CONNECTION="mysql"
    DB_HOST="mysql"
    DB_PORT="3306"
    DB_DATABASE="laravel"
    DB_USERNAME="laravel"
    DB_PASSWORD="laravel"
fi

# DB_HOST must always be 'mysql' (Docker container name)
DB_HOST="mysql"

# Detect LAN IP as default
DEFAULT_HOST=$(ip route get 1.1.1.1 2>/dev/null | grep -oP 'src \K\S+' || echo "localhost")
APP_HOST="${DEFAULT_HOST}"

# Interactive configuration (skip if -y flag)
if [ "$SKIP_INTERACTIVE" = false ]; then
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
    echo -e "${GREEN}Using configuration from .env.install:${NC}"
    echo "  App Name: ${APP_NAME}"
    echo "  Environment: ${APP_ENV}"
    echo "  Host: ${APP_HOST}"
    echo "  Database: ${DB_DATABASE}"
    echo "  Database User: ${DB_USERNAME}"
    echo ""
fi

echo ""
echo -e "${BLUE}Installing Laravel 12...${NC}"

# Create src directory
mkdir -p src

# Install Laravel 12 using Composer
$DOCKER_RUN -v "$(pwd)/src:/app" composer:latest \
    create-project laravel/laravel . --prefer-dist

echo -e "${GREEN}✓ Laravel installed${NC}"

# Generate APP_KEY if not exists
if ! grep -q "^APP_KEY=base64:" src/.env; then
    echo -e "${BLUE}Generating APP_KEY...${NC}"
    $DOCKER_RUN  -v "$(pwd)/src:/app" -w /app php:8.4-cli \
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

# Install FilamentPHP v5
echo -e "${BLUE}Installing FilamentPHP v5...${NC}"

$DOCKER_RUN  -v "$(pwd)/src:/app" -w /app composer:latest \
    require filament/filament:"^5.0" -W --ignore-platform-reqs

echo -e "${GREEN}✓ FilamentPHP v5 installed${NC}"

# Install Filament Panel
echo -e "${BLUE}Setting up Filament Panel...${NC}"

$DOCKER_RUN  -v "$(pwd)/src:/app" -w /app php:8.4-cli \
    php artisan filament:install --panels --no-interaction

echo -e "${GREEN}✓ Filament Panel configured${NC}"

# Install Laravel Debugbar if APP_ENV=local
if [ "$APP_ENV" = "local" ]; then
    echo -e "${BLUE}Installing Laravel Debugbar (development)...${NC}"
    $DOCKER_RUN  -v "$(pwd)/src:/app" -w /app composer:latest \
        require barryvdh/laravel-debugbar --dev --ignore-platform-reqs
    echo -e "${GREEN}✓ Laravel Debugbar installed${NC}"
fi

# Configure Vite (for both development and production)
echo -e "${BLUE}Configuring Vite...${NC}"

# Create vite.config.js - uses @vitejs/plugin-basic-ssl for HTTPS
cat > /tmp/vite.config.js.tmp <<'VITE_CONFIG'
import { defineConfig, loadEnv } from 'vite';
import tailwindcss from '@tailwindcss/vite';
import laravel, { refreshPaths } from 'laravel-vite-plugin'
import basicSsl from '@vitejs/plugin-basic-ssl';

export default defineConfig(({ mode }) => {
    const env = loadEnv(mode, process.cwd(), '');
    const hmrHost = env.VITE_HMR_HOST || 'localhost';

    return {
        plugins: [
            laravel({
                input: [
                    'resources/css/app.css',
                    'resources/js/app.js',
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
            basicSsl(),
        ],
        server: {
            host: "0.0.0.0",
            port: 5173,
            strictPort: true,
            cors: true,
            hmr: {
                protocol: 'wss',
                host: hmrHost,
            },
        },
    };
});
VITE_CONFIG

# Move temp file to src/ with sudo and fix ownership
sudo mv /tmp/vite.config.js.tmp src/vite.config.js
sudo chown ${CURRENT_USER}:${CURRENT_GROUP} src/vite.config.js
sudo chmod 644 src/vite.config.js

echo -e "${GREEN}✓ vite.config.js configured${NC}"

# Install NPM dependencies and build assets
echo -e "${BLUE}Installing NPM dependencies...${NC}"
$DOCKER_RUN node:current-alpine npm install
echo -e "${GREEN}✓ NPM dependencies installed${NC}"

# Install Vite SSL plugin for HTTPS in development
echo -e "${BLUE}Installing Vite SSL plugin...${NC}"
$DOCKER_RUN node:current-alpine npm install -D @vitejs/plugin-basic-ssl
echo -e "${GREEN}✓ Vite SSL plugin installed${NC}"

if [ "$APP_ENV" = "production" ]; then
    echo -e "${BLUE}Building production assets...${NC}"
    $DOCKER_RUN node:current-alpine npm run build
    echo -e "${GREEN}✓ Production assets built${NC}"
fi

# Set proper permissions and ownership
echo -e "${BLUE}Setting permissions and ownership...${NC}"

# Get current user/group IDs
CURRENT_USER=$(id -u)
CURRENT_GROUP=$(id -g)

# Use Docker to fix ownership (avoids sudo for most files)
echo -e "${YELLOW}Fixing ownership using Docker (${CURRENT_USER}:${CURRENT_GROUP})...${NC}"
$DOCKER_RUN alpine:latest sh -c "chown -R ${CURRENT_USER}:${CURRENT_GROUP} /app"

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
echo -e "     ${YELLOW}docker exec -it laravel-app chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache${NC}"
echo ""
echo -e "${GREEN}Happy coding! 🚀${NC}"
