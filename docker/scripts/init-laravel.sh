#!/bin/bash
# ============================================================================
# Laravel Application Initialization Script
# Runs Laravel-specific setup tasks
# ============================================================================

set -e

echo "========================================="
echo "Initializing Laravel Application..."
echo "========================================="

# Check if Laravel is installed
if [ ! -f /var/www/html/artisan ]; then
    echo "Laravel not found. Skipping initialization."
    exit 0
fi

cd /var/www/html

dev# Create storage link if it doesn't exist
if [ ! -L /var/www/html/public/storage ]; then
    echo "Creating storage symlink..."
    php artisan storage:link || true
fi

# Run migrations if enabled
if [ "${AUTO_MIGRATE:-false}" = "true" ]; then
    echo "Running database migrations..."
    php artisan migrate --force
fi

# Clear and cache configurations in production
if [ "$APP_ENV" = "production" ]; then
    echo "Caching Laravel configurations..."
    php artisan config:cache
    php artisan route:cache
    php artisan view:cache
    php artisan event:cache
fi

# Set proper permissions
echo "Setting permissions..."
chmod -R 775 storage bootstrap/cache
chown -R www-data:www-data storage bootstrap/cache

echo "========================================="
echo "Laravel initialization complete!"
echo "========================================="
