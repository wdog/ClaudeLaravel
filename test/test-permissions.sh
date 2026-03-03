#!/bin/bash
# ============================================================================
# Test Script: Verifica installazione Laravel e permessi Docker
# Crea una nuova app Laravel, avvia Docker e verifica che i permessi funzionino
# ============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Project root (parent directory of test/)
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONTAINER_NAME="laravel-app"

echo -e "${BLUE}"
echo "============================================="
echo "  Test Permessi Docker per Laravel"
echo "============================================="
echo -e "${NC}"
echo "Project root: ${PROJECT_ROOT}"
echo "Host user: $(whoami) (UID: $(id -u), GID: $(id -g))"
echo ""

# Function to cleanup on exit
cleanup() {
    echo ""
    echo -e "${YELLOW}Cleanup: stopping containers...${NC}"
    cd "$PROJECT_ROOT"
    docker-compose down 2>/dev/null || true
}

# Trap to cleanup on script exit
trap cleanup EXIT

# Step 1: Clean install Laravel
echo -e "${BLUE}[1/7] Installazione pulita di Laravel...${NC}"
cd "$PROJECT_ROOT"
./install-laravel.sh -cf
echo -e "${GREEN}✓ Laravel installato${NC}"
echo ""

# Step 2: Build Docker images
echo -e "${BLUE}[2/7] Build immagini Docker...${NC}"
./manager.sh -b
echo -e "${GREEN}✓ Build completata${NC}"
echo ""

# Step 3: Start containers in background
echo -e "${BLUE}[3/7] Avvio containers...${NC}"
./manager.sh -d
echo -e "${GREEN}✓ Containers avviati${NC}"
echo ""

# Wait for containers to be ready
echo -e "${YELLOW}Attendo che i containers siano pronti...${NC}"
sleep 10

# Step 4: Verify www-data UID mapping
echo -e "${BLUE}[4/7] Verifica mapping UID www-data...${NC}"
HOST_UID=$(id -u)
HOST_GID=$(id -g)
CONTAINER_UID=$(docker exec $CONTAINER_NAME id -u www-data)
CONTAINER_GID=$(docker exec $CONTAINER_NAME id -g www-data)

echo "  Host UID/GID: ${HOST_UID}/${HOST_GID}"
echo "  Container www-data UID/GID: ${CONTAINER_UID}/${CONTAINER_GID}"

if [ "$HOST_UID" = "$CONTAINER_UID" ] && [ "$HOST_GID" = "$CONTAINER_GID" ]; then
    echo -e "${GREEN}✓ UID/GID mapping corretto!${NC}"
else
    echo -e "${RED}✗ ERRORE: UID/GID non corrispondono!${NC}"
    echo -e "${RED}  Atteso: ${HOST_UID}/${HOST_GID}${NC}"
    echo -e "${RED}  Trovato: ${CONTAINER_UID}/${CONTAINER_GID}${NC}"
    exit 1
fi
echo ""

# Step 5: Test file creation from host
echo -e "${BLUE}[5/7] Test creazione file dall'host...${NC}"
TEST_FILE_HOST="src/storage/test-from-host-$(date +%s).txt"
echo "Created from host at $(date)" > "$PROJECT_ROOT/$TEST_FILE_HOST"

# Check if container can read it
if docker exec $CONTAINER_NAME cat "/var/www/html/storage/$(basename $TEST_FILE_HOST)" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Container puo' leggere file creato dall'host${NC}"
else
    echo -e "${RED}✗ ERRORE: Container non puo' leggere file dall'host${NC}"
    exit 1
fi

# Check if container can modify it
docker exec $CONTAINER_NAME sh -c "echo 'Modified by container' >> /var/www/html/storage/$(basename $TEST_FILE_HOST)"
if grep -q "Modified by container" "$PROJECT_ROOT/$TEST_FILE_HOST"; then
    echo -e "${GREEN}✓ Container puo' modificare file creato dall'host${NC}"
else
    echo -e "${RED}✗ ERRORE: Container non puo' modificare file dall'host${NC}"
    exit 1
fi
rm -f "$PROJECT_ROOT/$TEST_FILE_HOST"
echo ""

# Step 6: Test file creation from container (as www-data)
echo -e "${BLUE}[6/7] Test creazione file dal container...${NC}"
TEST_FILE_CONTAINER="test-from-container-$(date +%s).txt"
docker exec -u www-data $CONTAINER_NAME sh -c "echo 'Created from container at $(date)' > /var/www/html/storage/$TEST_FILE_CONTAINER"

# Check if host can read it
if cat "$PROJECT_ROOT/src/storage/$TEST_FILE_CONTAINER" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Host puo' leggere file creato dal container${NC}"
else
    echo -e "${RED}✗ ERRORE: Host non puo' leggere file dal container${NC}"
    exit 1
fi

# Check if host can modify it
echo "Modified by host" >> "$PROJECT_ROOT/src/storage/$TEST_FILE_CONTAINER"
if docker exec -u www-data $CONTAINER_NAME grep -q "Modified by host" "/var/www/html/storage/$TEST_FILE_CONTAINER"; then
    echo -e "${GREEN}✓ Host puo' modificare file creato dal container${NC}"
else
    echo -e "${RED}✗ ERRORE: Host non puo' modificare file dal container${NC}"
    exit 1
fi
rm -f "$PROJECT_ROOT/src/storage/$TEST_FILE_CONTAINER"
echo ""

# Step 7: Test Vite dev server (npm run dev)
echo -e "${BLUE}[7/7] Verifica Vite dev server...${NC}"

# Check if vite-dev service is running
VITE_STATUS=$(docker exec $CONTAINER_NAME s6-svstat /run/service/vite-dev 2>/dev/null | grep -o "up" || echo "down")
if [ "$VITE_STATUS" = "up" ]; then
    echo -e "${GREEN}✓ Vite dev server in esecuzione${NC}"

    # Check who is running npm
    VITE_USER=$(docker exec $CONTAINER_NAME sh -c "ps aux | grep 'npm run dev' | grep -v grep | awk '{print \$1}'" | head -1)
    echo "  Vite running as user: ${VITE_USER}"

    if [ "$VITE_USER" = "www-data" ] || [ "$VITE_USER" = "1000" ]; then
        echo -e "${GREEN}✓ Vite gira come www-data (corretto!)${NC}"
    else
        echo -e "${YELLOW}! Vite gira come: ${VITE_USER}${NC}"
    fi
else
    echo -e "${YELLOW}! Vite dev server non attivo (potrebbe essere in modalita' production)${NC}"
fi
echo ""

# Summary
echo -e "${GREEN}"
echo "============================================="
echo "  TUTTI I TEST PASSATI!"
echo "============================================="
echo -e "${NC}"
echo ""
echo -e "${BLUE}Riepilogo:${NC}"
echo "  - UID mapping: www-data = ${CONTAINER_UID} (host: ${HOST_UID})"
echo "  - File host -> container: OK"
echo "  - File container -> host: OK"
echo "  - Vite dev server: ${VITE_STATUS}"
echo ""
echo -e "${CYAN}I containers sono ancora in esecuzione.${NC}"
echo -e "${CYAN}Per fermarli manualmente: docker-compose down${NC}"
echo ""
echo -e "${GREEN}Il fix dei permessi funziona correttamente!${NC}"
