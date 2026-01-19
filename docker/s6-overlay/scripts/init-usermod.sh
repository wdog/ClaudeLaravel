#!/command/with-contenv sh
# Map www-data UID/GID to host user
PUID=${PUID:-1000}
PGID=${PGID:-1000}

groupmod -o -g "$PGID" www-data
usermod -o -u "$PUID" -g "$PGID" www-data

# Fix PHP-FPM socket directory
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

echo "www-data mapped to UID:${PUID} GID:${PGID}"

# ============================================================================
# Configure services based on APP_ENV
# ============================================================================
CONTENTS_DIR="/etc/s6-overlay/s6-rc.d/user/contents.d"

# scheduler and queue-worker always enabled
touch "$CONTENTS_DIR/scheduler" "$CONTENTS_DIR/queue-worker"

if [ "$APP_ENV" = "production" ]; then
    echo "init-usermod: Configuring services for PRODUCTION"
    rm -f "$CONTENTS_DIR/vite-dev"
else
    echo "init-usermod: Configuring services for DEVELOPMENT"
    touch "$CONTENTS_DIR/vite-dev"
fi
