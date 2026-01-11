#!/command/with-contenv bash
# ============================================================================
# s6-overlay permissions fix script
# Sets permissions to allow both www-data (container) and host user to write
# ============================================================================

set -e

echo "========================================="
echo "Setting up shared permissions"
echo "=========================================

"

# Get UID/GID from environment (passed from host)
PUID=${PUID:-1000}
PGID=${PGID:-1000}

echo "Host UID: ${PUID}"
echo "Host GID: ${PGID}"
echo "Container www-data UID: $(id -u www-data)"
echo "Container www-data GID: $(id -g www-data)"

# Strategy: Use 777 permissions for directories that need to be writable
# by both www-data (container) and host user
# This is acceptable for development environments

if [ -d /var/www/html/storage ]; then
    echo "Setting Laravel writable directories to 777..."
    chmod -R 777 /var/www/html/storage 2>/dev/null || true
    chmod -R 777 /var/www/html/bootstrap/cache 2>/dev/null || true
    chmod 777 /var/www/html/public 2>/dev/null || true
    chmod 777 /var/www/html 2>/dev/null || true
fi

# Ensure PHP-FPM socket directory exists and is writable
mkdir -p /var/run/php
chmod 777 /var/run/php

echo "========================================="
echo "✓ Permissions configured for shared access"
echo "========================================="
