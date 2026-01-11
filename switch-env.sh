#!/bin/bash
# ============================================================================
# Environment Switcher - Switch between local and production
# ============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Check if src/.env exists
if [ ! -f "src/.env" ]; then
    echo -e "${RED}ERROR: src/.env not found!${NC}"
    echo "Please run ./install-laravel.sh first"
    exit 1
fi

# Get current environment
CURRENT_ENV=$(grep -E "^APP_ENV=" src/.env | cut -d '=' -f2 | tr -d ' "' || echo "unknown")

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}  Environment Switcher${NC}"
echo -e "${BLUE}================================${NC}"
echo ""
echo -e "${CYAN}Current environment: ${CURRENT_ENV}${NC}"
echo ""

# Determine target environment
if [ "$1" = "local" ] || [ "$1" = "production" ]; then
    TARGET_ENV="$1"
else
    echo "Available environments:"
    echo "  1) local      - Development mode with Vite HMR"
    echo "  2) production - Production mode with built assets"
    echo ""
    read -p "Select environment (1 or 2): " choice

    case $choice in
        1)
            TARGET_ENV="local"
            ;;
        2)
            TARGET_ENV="production"
            ;;
        *)
            echo -e "${RED}Invalid choice${NC}"
            exit 1
            ;;
    esac
fi

# Check if already in target environment
if [ "$CURRENT_ENV" = "$TARGET_ENV" ]; then
    echo -e "${GREEN}Already in ${TARGET_ENV} mode${NC}"
    read -p "Rebuild containers anyway? (y/n): " rebuild
    if [ "$rebuild" != "y" ]; then
        exit 0
    fi
fi

echo ""
echo -e "${YELLOW}Switching to ${TARGET_ENV} mode...${NC}"
echo ""

# Update .env file based on target
if [ "$TARGET_ENV" = "local" ]; then
    echo -e "${BLUE}Configuring for local development...${NC}"
    sed -i 's/^APP_ENV=.*/APP_ENV=local/' src/.env
    sed -i 's/^APP_DEBUG=.*/APP_DEBUG=true/' src/.env
    echo -e "${GREEN}✓ .env updated to local mode${NC}"

elif [ "$TARGET_ENV" = "production" ]; then
    echo -e "${BLUE}Configuring for production...${NC}"
    sed -i 's/^APP_ENV=.*/APP_ENV=production/' src/.env
    sed -i 's/^APP_DEBUG=.*/APP_DEBUG=false/' src/.env
    echo -e "${GREEN}✓ .env updated to production mode${NC}"

    # Check if assets are built
    if [ ! -d "src/public/build" ] || [ -z "$(ls -A src/public/build 2>/dev/null)" ]; then
        echo ""
        echo -e "${YELLOW}Building production assets...${NC}"
        docker run --rm -v "$(pwd)/src:/app" -w /app node:20-alpine sh -c "npm install && npm run build"
        echo -e "${GREEN}✓ Production assets built${NC}"
    else
        echo -e "${CYAN}Production assets already exist${NC}"
        read -p "Rebuild assets? (y/n): " rebuild_assets
        if [ "$rebuild_assets" = "y" ]; then
            echo -e "${YELLOW}Rebuilding production assets...${NC}"
            docker run --rm -v "$(pwd)/src:/app" -w /app node:20-alpine npm run build
            echo -e "${GREEN}✓ Production assets rebuilt${NC}"
        fi
    fi
fi

echo ""
echo -e "${YELLOW}Restarting containers...${NC}"
echo ""

# Restart containers with new environment
./docker-up.sh --build

echo ""
echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}  Environment switched!${NC}"
echo -e "${GREEN}================================${NC}"
echo ""
echo -e "${CYAN}Now running in ${TARGET_ENV} mode${NC}"
echo ""

if [ "$TARGET_ENV" = "local" ]; then
    echo -e "${BLUE}Development features:${NC}"
    echo "  - Vite HMR enabled"
    echo "  - Debug mode enabled"
    echo "  - Laravel Debugbar available"
    echo "  - Hot reload on file changes"
elif [ "$TARGET_ENV" = "production" ]; then
    echo -e "${BLUE}Production features:${NC}"
    echo "  - Compiled assets only"
    echo "  - Debug mode disabled"
    echo "  - Optimized performance"
    echo "  - No Vite dev server"
fi
echo ""
