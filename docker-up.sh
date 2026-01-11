#!/bin/bash
# ============================================================================
# Docker Compose Wrapper - Auto-detects dev/prod from src/.env
# ============================================================================

set -e

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}  Laravel Docker Startup${NC}"
echo -e "${BLUE}================================${NC}"
echo ""

# Stop running containers before starting
if [ -f "docker-compose.yml" ]; then
    if docker-compose ps --services --filter "status=running" 2>/dev/null | grep -q .; then
        echo -e "${YELLOW}Stopping running containers...${NC}"
        docker-compose down 2>/dev/null || true
        echo -e "${GREEN}✓ Containers stopped${NC}"
        echo ""
    fi
fi

# Check if src/.env exists
if [ ! -f "src/.env" ]; then
    echo -e "${RED}ERROR: src/.env not found!${NC}"
    echo ""
    echo "Please either:"
    echo "  1. Run ./install-laravel.sh to create a new project"
    echo "  2. Clone your Laravel project into src/ directory"
    echo ""
    exit 1
fi

# Read APP_ENV from src/.env
APP_ENV=$(grep -E "^APP_ENV=" src/.env | cut -d '=' -f2 | tr -d ' "' || echo "production")

# Determine build target
if [ "$APP_ENV" = "local" ] || [ "$APP_ENV" = "dev" ] || [ "$APP_ENV" = "development" ]; then
    BUILD_TARGET="development"
    MODE="Development"
else
    BUILD_TARGET="production"
    MODE="Production"
fi

echo -e "${GREEN}Detected Environment: ${APP_ENV}${NC}"
echo -e "${GREEN}Build Target: ${BUILD_TARGET}${NC}"
echo -e "${GREEN}Mode: ${MODE}${NC}"
echo ""

# Read database config from src/.env
DB_DATABASE=$(grep -E "^DB_DATABASE=" src/.env | cut -d '=' -f2 | tr -d ' "' || echo "laravel")
DB_USERNAME=$(grep -E "^DB_USERNAME=" src/.env | cut -d '=' -f2 | tr -d ' "' || echo "laravel")
DB_PASSWORD=$(grep -E "^DB_PASSWORD=" src/.env | cut -d '=' -f2 | tr -d ' "' || echo "secret")

echo -e "${BLUE}Database Configuration:${NC}"
echo "  Database: ${DB_DATABASE}"
echo "  Username: ${DB_USERNAME}"
echo "  Password: ${DB_PASSWORD:0:3}***"
echo ""

# Get current user UID/GID for permission mapping
export PUID=$(id -u)
export PGID=$(id -g)

# Extract host from APP_URL in .env for Vite HMR
APP_URL=$(grep -E "^APP_URL=" src/.env | cut -d '=' -f2 | tr -d ' "' || echo "https://localhost")
# Remove protocol and port, keep only hostname/IP
HOST_IP=$(echo "$APP_URL" | sed -E 's|^https?://||' | sed -E 's|:[0-9]+$||' | sed -E 's|/.*$||')
export HOST_IP

echo -e "${BLUE}Network Configuration:${NC}"
echo "  APP_URL: ${APP_URL}"
echo "  Vite Host: ${HOST_IP}"
echo "  Vite will be accessible at: http://${HOST_IP}:5173"
echo ""

# Parse command line arguments
BUILD_FLAG=""
DETACH_FLAG="-d"  # Detached by default
FOREGROUND=false
for arg in "$@"; do
    case $arg in
        --build|-b)
            BUILD_FLAG="--build"
            ;;
        --foreground|-f)
            DETACH_FLAG=""
            FOREGROUND=true
            ;;
        *)
            ;;
    esac
done

# Export variables for docker-compose
export BUILD_TARGET
export DB_DATABASE
export DB_USERNAME
export DB_PASSWORD

echo -e "${YELLOW}Starting containers...${NC}"
echo ""

# Determine which compose files to use
if [ "$APP_ENV" = "local" ]; then
    COMPOSE_FILES="-f docker-compose.yml -f docker-compose.dev.yml"
else
    COMPOSE_FILES="-f docker-compose.yml"
fi

# Run docker-compose with appropriate files
docker-compose $COMPOSE_FILES up $BUILD_FLAG $DETACH_FLAG

# Show access URLs
echo ""
echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}  Application Started!${NC}"
echo -e "${GREEN}================================${NC}"
echo ""
echo -e "${BLUE}Access your application:${NC}"
echo "  HTTPS: https://localhost (or https://${HOST_IP})"
echo "  Filament Admin: https://localhost/admin"
if [ "$BUILD_TARGET" = "development" ]; then
    echo "  Vite HMR: http://${HOST_IP}:5173"
fi
echo ""
echo -e "${BLUE}Useful commands:${NC}"
echo "  docker exec -it laravel-app php artisan migrate [--force]"
echo "  docker exec -it laravel-app php artisan [command]"
echo "  docker exec -it laravel-app composer [command]"
if [ "$BUILD_TARGET" = "development" ]; then
    echo "  docker exec -it laravel-app npm [command]"
fi
echo ""
echo -e "${BLUE}View logs:${NC}"
echo "  docker-compose logs -f"
echo "  docker logs -f laravel-app"
echo ""
