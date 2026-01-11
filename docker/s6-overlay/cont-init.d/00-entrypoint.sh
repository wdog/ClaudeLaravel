#!/command/with-contenv bash
# ============================================================================
# s6-overlay initialization script
# Runs the Laravel entrypoint before starting services
# ============================================================================

set -e

echo "========================================="
echo "Laravel Docker Container Starting..."
echo "========================================="

# Environment detection from src/.env file
if [ -f /var/www/html/.env ]; then
    echo "Reading environment from /var/www/html/.env"
    APP_ENV=$(grep -E "^APP_ENV=" /var/www/html/.env | cut -d '=' -f2 | tr -d ' "' || echo "production")
else
    echo "Warning: .env file not found, defaulting to production"
    APP_ENV=${APP_ENV:-production}
fi

echo "Environment detected: ${APP_ENV}"

# Laravel directories are created by Laravel itself during installation
# We only ensure proper permissions if Laravel is already installed
if [ -d /var/www/html/storage ]; then
    echo "Laravel detected, fixing permissions..."

    # Fix ownership for Laravel writable directories
    chown -R www-data:www-data \
        /var/www/html/storage \
        /var/www/html/bootstrap/cache 2>/dev/null || true

    chmod -R 775 \
        /var/www/html/storage \
        /var/www/html/bootstrap/cache 2>/dev/null || true

    # Fix public/ directory permissions for Vite hot file
    # Vite needs to write public/hot during dev mode
    if [ -d /var/www/html/public ]; then
        chown www-data:www-data /var/www/html/public 2>/dev/null || true
        chmod 775 /var/www/html/public 2>/dev/null || true
    fi

    # Allow www-data to write temporary files in project root (for Vite)
    # This allows Vite to create .timestamp files during dev mode
    chmod 775 /var/www/html 2>/dev/null || true

    echo "✓ Permissions fixed"
else
    echo "Warning: Laravel not found in /var/www/html"
fi

# Environment-specific configurations
if [ "$APP_ENV" = "production" ]; then
    echo "Applying production configurations..."
    # Production settings already in opcache.ini
else
    echo "Applying development configurations..."
    # Development mode - opcache will revalidate
fi

echo "========================================="
echo "Container initialization complete!"
echo "========================================="
