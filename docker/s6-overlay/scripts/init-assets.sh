#!/command/with-contenv bash
# Build frontend assets in production mode
# Runs as oneshot before services start (executed as www-data)

set -e

cd /var/www/html

# Check if we're in production
if [ "$APP_ENV" = "production" ]; then
    echo "init-assets: Production mode - building assets..."

    # Remove hot file (created by Vite dev server)
    rm -f /var/www/html/public/hot

    # Check if node_modules exists, if not install
    if [ ! -d "node_modules" ]; then
        echo "init-assets: Installing npm dependencies..."
        npm ci --prefer-offline --no-audit
    fi

    # Build assets
    echo "init-assets: Running npm run build..."
    npm run build

    echo "init-assets: Assets built successfully"
else
    echo "init-assets: Development mode - skipping asset build (Vite HMR active)"
fi
