#!/command/with-contenv sh
# init-usermod: Map www-data UID/GID to host user
# Runs as root (oneshot, before all other services)

PUID=${PUID:-1000}
PGID=${PGID:-1000}

if [ "$PUID" = "0" ]; then
    echo "init-usermod: PUID=0 (Synology/root mode) - skipping usermod"

    # Create PHP-FPM socket directory (owned root, traversable by all)
    mkdir -p /var/run/php
    chmod 755 /var/run/php

    # Fix nginx temp directories
    if [ -d /var/lib/nginx/tmp ]; then
        chmod -R 777 /var/lib/nginx/tmp
    fi

    # Ensure all app files are readable by nginx worker (runs as 'nginx' user)
    chmod -R a+rX /var/www/html 2>/dev/null || true

    # Make Laravel writable directories accessible to all processes
    if [ -d /var/www/html/storage ]; then
        chmod -R 777 /var/www/html/storage 2>/dev/null || true
        chmod -R 777 /var/www/html/bootstrap/cache 2>/dev/null || true
    fi

    # SQLite: make database directory and file writable
    if [ -d /var/www/html/database ]; then
        chmod 777 /var/www/html/database 2>/dev/null || true
        [ -f /var/www/html/database/database.sqlite ] && chmod 666 /var/www/html/database/database.sqlite 2>/dev/null || true
    fi

else
    # Map www-data to host user UID/GID
    groupmod -o -g "$PGID" www-data
    usermod -o -u "$PUID" -g "$PGID" www-data

    # Create PHP-FPM socket directory
    mkdir -p /var/run/php
    chown www-data:www-data /var/run/php
    chmod 755 /var/run/php

    # Fix nginx temp directories for file uploads
    if [ -d /var/lib/nginx/tmp ]; then
        chown -R nginx:nginx /var/lib/nginx/tmp
        chmod -R 700 /var/lib/nginx/tmp
    fi

    # Fix Laravel permissions if exists
    if [ -d /var/www/html/storage ]; then
        chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache 2>/dev/null || true
        chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache 2>/dev/null || true
        [ -d /var/www/html/public ] && chown www-data:www-data /var/www/html/public && chmod 775 /var/www/html/public
        chmod 775 /var/www/html 2>/dev/null || true
    fi

    # SQLite: ensure database directory is writable by www-data
    if [ -d /var/www/html/database ]; then
        chown www-data:www-data /var/www/html/database 2>/dev/null || true
        chmod 775 /var/www/html/database 2>/dev/null || true
        [ -f /var/www/html/database/database.sqlite ] && chown www-data:www-data /var/www/html/database/database.sqlite && chmod 664 /var/www/html/database/database.sqlite 2>/dev/null || true
    fi
fi

echo "init-usermod: done (PUID=${PUID} PGID=${PGID})"
echo "init-usermod: APP_ENV=${APP_ENV:-not set}"
