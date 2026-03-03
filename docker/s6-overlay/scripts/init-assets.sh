#!/command/with-contenv sh
# init-assets: Build frontend assets and prepare app
# Runs as root (oneshot, after init-usermod)
#
# PRODUCTION: removes hot file, runs npm run build, creates sqlite db, runs migrations
# DEVELOPMENT: skips (Vite HMR handles assets)

cd /var/www/html

# Create SQLite database file if missing (both dev and prod)
if [ ! -f database/database.sqlite ]; then
    echo "init-assets: creating database/database.sqlite"
    touch database/database.sqlite
    chmod 666 database/database.sqlite
fi

if [ "$APP_ENV" = "production" ]; then
    echo "init-assets: Production mode"

    # Remove hot file (may have wrong permissions from dev)
    rm -f /var/www/html/public/hot

    # Install dependencies if missing
    if [ ! -d "node_modules" ]; then
        echo "init-assets: Installing npm dependencies..."
        s6-setuidgid www-data npm ci --prefer-offline --no-audit
    fi

    # Build assets (skip if already built - manager.sh pre-builds them)
    if [ -f "public/build/manifest.json" ]; then
        echo "init-assets: Assets already built, skipping npm run build"
    else
        echo "init-assets: Running npm run build..."
        s6-setuidgid www-data npm run build
    fi

    # Run migrations (--force needed in production)
    echo "init-assets: Running migrations..."
    s6-setuidgid www-data php artisan migrate --force

    echo "init-assets: done"
else
    # Run migrations in development too (convenience)
    echo "init-assets: Development mode - running migrations..."
    s6-setuidgid www-data php artisan migrate --force 2>/dev/null || echo "init-assets: migration skipped (app not ready yet)"
    echo "init-assets: Vite HMR will handle assets"
fi
