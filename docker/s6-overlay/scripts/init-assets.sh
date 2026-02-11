#!/command/with-contenv sh
# init-assets: Build frontend assets
# Runs as root (oneshot, after init-usermod)
#
# PRODUCTION: removes hot file, runs npm run build
# DEVELOPMENT: skips (Vite HMR handles assets)

cd /var/www/html

if [ "$APP_ENV" = "production" ]; then
    echo "init-assets: Production mode"

    # Remove hot file (may have wrong permissions from dev)
    rm -f /var/www/html/public/hot

    # Clean install dependencies (ensures correct platform binaries)
    echo "init-assets: Installing npm dependencies..."
    HOME=/tmp s6-setuidgid www-data npm ci --no-audit

    # Build assets
    echo "init-assets: Running npm run build..."
    HOME=/tmp s6-setuidgid www-data npm run build

    echo "init-assets: Assets built successfully"
else
    echo "init-assets: Development mode - skipping (Vite HMR active)"
fi
