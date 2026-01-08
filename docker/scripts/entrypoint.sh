#!/bin/bash
# ============================================================================
# Docker Container Entrypoint Script
# Handles initialization and environment-specific setup
# ============================================================================

set -e

echo "========================================="
echo "Laravel Docker Container Starting..."
echo "========================================="

# Environment detection from src/.env file
if [ -f /var/www/html/.env ]; then
    echo "Reading environment from /var/www/html/.env"
    # Extract APP_ENV from .env file
    APP_ENV=$(grep -E "^APP_ENV=" /var/www/html/.env | cut -d '=' -f2 | tr -d ' "' || echo "production")
else
    echo "Warning: .env file not found, defaulting to production"
    APP_ENV=${APP_ENV:-production}
fi

echo "Environment detected: ${APP_ENV}"

# Laravel directories are created by Laravel itself during installation
# We only ensure proper permissions if Laravel is already installed
if [ -d /var/www/html/storage ]; then
    echo "Laravel detected, checking permissions..."
    # Set proper permissions (only if running as root)
    if [ "$(id -u)" = "0" ]; then
        echo "Setting permissions on Laravel directories..."
        chown -R www-data:www-data \
            /var/www/html/storage \
            /var/www/html/bootstrap/cache 2>/dev/null || true

        chmod -R 775 \
            /var/www/html/storage \
            /var/www/html/bootstrap/cache 2>/dev/null || true
    fi
else
    echo "Warning: Laravel not found in /var/www/html"
fi

# Environment-specific configurations
if [ "$APP_ENV" = "production" ]; then
    echo "Applying production configurations..."

    # Disable OPcache timestamp validation in production
    echo "opcache.validate_timestamps = 0" >> /usr/local/etc/php/conf.d/opcache.ini

    # TODO: Cache Laravel configurations (when code is copied in image)
    # if [ -f /var/www/html/artisan ]; then
    #     php artisan config:cache
    #     php artisan route:cache
    #     php artisan view:cache
    # fi
else
    echo "Applying development configurations..."

    # Enable OPcache timestamp validation in development
    echo "opcache.validate_timestamps = 1" >> /usr/local/etc/php/conf.d/opcache.ini
    echo "opcache.revalidate_freq = 0" >> /usr/local/etc/php/conf.d/opcache.ini

    # Enable error display in development
    sed -i 's/display_errors = Off/display_errors = On/g' /usr/local/etc/php/php.ini
fi

echo "========================================="
echo "Container initialization complete!"
echo "========================================="

# Start PHP-FPM in foreground
exec "$@"
