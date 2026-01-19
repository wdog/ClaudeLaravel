#!/command/with-contenv sh
# init-usermod: Map www-data UID/GID to host user
# Runs as root (oneshot, before all other services)

PUID=${PUID:-1000}
PGID=${PGID:-1000}

# Map www-data to host user UID/GID
groupmod -o -g "$PGID" www-data
usermod -o -u "$PUID" -g "$PGID" www-data

# Create PHP-FPM socket directory
mkdir -p /var/run/php
chown www-data:www-data /var/run/php
chmod 755 /var/run/php

# Fix Laravel permissions if exists
if [ -d /var/www/html/storage ]; then
    chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache 2>/dev/null || true
    chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache 2>/dev/null || true
    [ -d /var/www/html/public ] && chown www-data:www-data /var/www/html/public && chmod 775 /var/www/html/public
    chmod 775 /var/www/html 2>/dev/null || true
fi

echo "init-usermod: www-data mapped to UID:${PUID} GID:${PGID}"
echo "init-usermod: APP_ENV=${APP_ENV:-not set}"
