#!/usr/bin/env bash
# ============================================================================
# docker-up.sh — Start Docker environment (auto-detects dev/prod from src/.env)
# Usage: ./docker-up.sh [-b] [-d|-f] [-n]
#   -b  Build images before starting
#   -d  Detached mode (background)
#   -f  Foreground mode (show logs)
#   -n  No cache (force rebuild from scratch, implies -b)
# ============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/src/.env"

# --------------------------------------------------------------------------
# Read APP_ENV from src/.env
# --------------------------------------------------------------------------
if [ -f "$ENV_FILE" ]; then
    APP_ENV=$(grep -E '^APP_ENV=' "$ENV_FILE" | cut -d'=' -f2 | tr -d '"' | tr -d "'")
else
    echo "WARNING: ${ENV_FILE} not found, defaulting to production"
    APP_ENV="production"
fi

echo "==> APP_ENV: ${APP_ENV}"

# --------------------------------------------------------------------------
# Export PUID/PGID for container user mapping
# --------------------------------------------------------------------------
export PUID=$(id -u)
export PGID=$(id -g)
echo "==> Host user: UID=${PUID} GID=${PGID}"

# --------------------------------------------------------------------------
# Compose file selection
# --------------------------------------------------------------------------
if [ "$APP_ENV" = "local" ] || [ "$APP_ENV" = "development" ]; then
    export BUILD_TARGET="development"
    COMPOSE_FILES="-f docker-compose.yml -f docker-compose.dev.yml"
    echo "==> Mode: DEVELOPMENT"
else
    export BUILD_TARGET="production"
    COMPOSE_FILES="-f docker-compose.yml"
    echo "==> Mode: PRODUCTION"
fi

# --------------------------------------------------------------------------
# Parse flags
# --------------------------------------------------------------------------
DO_BUILD=false
MODE=""
NO_CACHE=""

while getopts "bdfn" opt; do
    case $opt in
        b) DO_BUILD=true ;;
        d) MODE="--detach" ;;
        f) MODE="" ;;
        n) NO_CACHE="--no-cache"; DO_BUILD=true ;;
        *) echo "Usage: $0 [-b] [-d|-f] [-n]"; exit 1 ;;
    esac
done

# --------------------------------------------------------------------------
# Build command
# --------------------------------------------------------------------------
CMD="docker compose ${COMPOSE_FILES}"

if [ "$DO_BUILD" = true ]; then
    echo "==> Building images... ${NO_CACHE:+(no cache)}"
    eval "${CMD} build ${NO_CACHE}"
fi

# --------------------------------------------------------------------------
# Start containers
# --------------------------------------------------------------------------
echo "==> Starting containers..."
eval "${CMD} up ${MODE}"
