#!/command/with-contenv sh
# ============================================================================
# init-usermod: Map www-data UID/GID to host user
# Runs as root (oneshot, before all other services)
# ============================================================================

PUID=${PUID:-1000}
PGID=${PGID:-1000}

echo "init-usermod: requested PUID=${PUID} PGID=${PGID}"

# --------------------------------------------------------------------------
# UID/GID remapping
# --------------------------------------------------------------------------
CURRENT_UID=$(id -u www-data)
CURRENT_GID=$(id -g www-data)

if [ "$PUID" = "0" ]; then
    # Running as root (e.g. Synology DSM) — skip remapping
    echo "init-usermod: PUID=0 detected (root/Synology), skipping UID/GID remap"
    echo "init-usermod: www-data stays at UID:${CURRENT_UID} GID:${CURRENT_GID}"
else
    # Remap only if different from current
    if [ "$CURRENT_GID" != "$PGID" ]; then
        echo "init-usermod: remapping www-data GID ${CURRENT_GID} -> ${PGID}"
        groupmod -o -g "$PGID" www-data
    fi

    if [ "$CURRENT_UID" != "$PUID" ]; then
        echo "init-usermod: remapping www-data UID ${CURRENT_UID} -> ${PUID}"
        usermod -o -u "$PUID" -g "$PGID" www-data
    fi

    if [ "$CURRENT_UID" = "$PUID" ] && [ "$CURRENT_GID" = "$PGID" ]; then
        echo "init-usermod: www-data already at UID:${PUID} GID:${PGID}, no remap needed"
    fi
fi

# --------------------------------------------------------------------------
# PHP-FPM socket directory
# --------------------------------------------------------------------------
mkdir -p /var/run/php
chown www-data:www-data /var/run/php
chmod 755 /var/run/php

# --------------------------------------------------------------------------
# Nginx temp directories — owned by www-data (nginx workers run as www-data)
# --------------------------------------------------------------------------
if [ -d /var/lib/nginx ]; then
    chown -R www-data:www-data /var/lib/nginx
    chmod -R 755 /var/lib/nginx
    echo "init-usermod: /var/lib/nginx -> www-data:www-data (755)"
fi

# --------------------------------------------------------------------------
# Laravel permissions
# --------------------------------------------------------------------------
if [ -d /var/www/html/storage ]; then
    echo "init-usermod: fixing Laravel directory permissions..."

    chown -R www-data:www-data \
        /var/www/html/storage \
        /var/www/html/bootstrap/cache \
        2>/dev/null || true

    chmod -R 775 \
        /var/www/html/storage \
        /var/www/html/bootstrap/cache \
        2>/dev/null || true

    if [ -d /var/www/html/public ]; then
        chown www-data:www-data /var/www/html/public
        chmod 775 /var/www/html/public
    fi

    # node_modules needs to be writable for npm/vite
    if [ -d /var/www/html/node_modules ]; then
        chown -R www-data:www-data /var/www/html/node_modules
        echo "init-usermod: /var/www/html/node_modules -> www-data:www-data"
    fi

    chmod 775 /var/www/html 2>/dev/null || true

    echo "init-usermod: Laravel permissions fixed"
fi

# --------------------------------------------------------------------------
# Summary
# --------------------------------------------------------------------------
echo "init-usermod: done — www-data UID:$(id -u www-data) GID:$(id -g www-data)"
echo "init-usermod: APP_ENV=${APP_ENV:-not set}"
