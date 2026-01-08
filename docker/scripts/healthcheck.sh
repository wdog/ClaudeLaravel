#!/bin/bash
# ============================================================================
# Docker Container Health Check Script
# Verifies that essential services are running correctly
# ============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Check PHP-FPM is responding
echo "Checking PHP-FPM..."
if ! cgi-fcgi -bind -connect /var/run/php/php-fpm.sock 2>/dev/null | grep -q "Status:"; then
    # Fallback: check if socket exists and PHP-FPM process is running
    if [ ! -S /var/run/php/php-fpm.sock ]; then
        echo -e "${RED}PHP-FPM socket not found${NC}"
        exit 1
    fi

    if ! pgrep -f "php-fpm: master process" > /dev/null; then
        echo -e "${RED}PHP-FPM process not running${NC}"
        exit 1
    fi
fi

# Check Nginx is responding
echo "Checking Nginx..."
if ! pgrep -f "nginx: master process" > /dev/null; then
    echo -e "${RED}Nginx not running${NC}"
    exit 1
fi

# Check if Nginx is listening on port 443
if ! netstat -tuln 2>/dev/null | grep -q ":443 "; then
    echo -e "${RED}Nginx not listening on port 443${NC}"
    exit 1
fi

# HTTPS health check
if command -v curl &> /dev/null; then
    if ! curl -f -s -k https://localhost/health > /dev/null; then
        echo -e "${RED}HTTPS health check failed${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}All health checks passed${NC}"
exit 0
