# Laravel Docker Project with FilamentPHP

Docker-based Laravel development environment with PHP 8.4 Alpine FPM, Nginx HTTPS, MySQL, and FilamentPHP v4 support.

**Key Feature**: Automatically detects development/production mode from `src/.env` file!

## 🚀 Quick Start

### Option 1: New Laravel Project (Automated)

```bash
# Run the installation script (interactive)
./install-laravel.sh

# Or clean install (removes existing src/ and database/data/)
./install-laravel.sh --clean

# Start containers (auto-detects mode from src/.env, runs detached)
./docker-up.sh --build

# Run migrations manually (required)
docker exec -it laravel-app php artisan migrate --force
```

**Installation Workflow**:
1. Script asks for single HOST (IP or domain) - auto-detects your LAN IP
2. Automatically builds:
   - `APP_URL=https://${HOST}` (HTTPS by default)
   - `VITE_HMR_HOST=${HOST}` (for LAN access)
3. Generates Vite config with HTTPS and self-signed certificates
4. Sets permissions using `sudo chmod 777` for storage/bootstrap/cache/public/src
5. **Does NOT run migrations** - you must run them manually

**Clean Install Option**:
- `./install-laravel.sh --clean` removes all existing Laravel code and database data
- **Handles permissions correctly**: Uses Docker to remove `vendor/` and `node_modules/`
- Removes MySQL data files with proper permissions handling
- Asks for confirmation before deleting
- Useful for starting completely fresh
- **WARNING**: Irreversible action!

**Why use --clean instead of manual `rm -rf src/`?**
- Docker creates `vendor/` and `node_modules/` with container user permissions
- MySQL creates database files with mysql user permissions (UID 999)
- Manual `rm` may fail with "Permission denied"
- `--clean` uses Docker to remove files with correct permissions

### Option 2: Existing Laravel Project

```bash
# Clone your Laravel project
git clone https://github.com/your/project.git src/

# Ensure src/.env is configured:
# - DB_HOST=mysql
# - DB_DATABASE=your_db
# - DB_USERNAME=your_user
# - DB_PASSWORD=your_password
# - APP_ENV=local (for development) or production
# - APP_URL=https://your-host
# - VITE_HMR_HOST=your-host

# Start containers
./docker-up.sh --build

# Run migrations
docker exec -it laravel-app php artisan migrate --force
```

## 📋 How It Works

The system reads ALL configuration from `src/.env` (Laravel's .env file):

1. **Environment Detection**:
   - `APP_ENV=local` → Builds **development** image (with Node.js, Composer, Vite HMR)
   - `APP_ENV=production` → Builds **production** image (optimized, OPcache, no dev tools)

2. **Database Configuration**:
   - Reads `DB_DATABASE`, `DB_USERNAME`, `DB_PASSWORD` from `src/.env`
   - Automatically configures MySQL container with those credentials

3. **No Duplicate Configuration**:
   - Single source of truth: `src/.env`
   - No need for separate Docker `.env` file

## 🔐 HTTPS Configuration

The application is **HTTPS-only** with automatic HTTP→HTTPS redirection.

### SSL Certificate

A **self-signed SSL certificate** is automatically generated during build (valid 10 years).

**Certificate includes**:
- `localhost`, `*.localhost`
- `127.0.0.1`
- Your LAN IP (auto-detected during build)
- Private network ranges (192.168.0.0/16, 172.16.0.0/12, 10.0.0.0/8)

### Access URLs

**Access your application** (based on HOST configured during installation):
- HTTPS: `https://{HOST}` ✅ Recommended (port 443)
  - Example: `https://192.168.88.40` (using LAN IP)
  - Example: `https://localhost` (local only)
- Vite HMR: `https://{HOST}:5173` (Development only, uses HTTPS!)
- Filament Admin: `https://{HOST}/admin`

**Note**: Vite now uses HTTPS with self-signed certificates for secure HMR over LAN!

### Network Configuration

The HOST you configure during installation is used for:
- `APP_URL=https://${HOST}` - Laravel app URL
- `VITE_HMR_HOST=${HOST}` - Vite Hot Module Replacement host

**LAN Access**: If you use your LAN IP (e.g., 192.168.88.40), you can access the app from:
- Your development machine
- Other devices on the same network (phones, tablets, etc.)

### Browser Security Warning

Your browser will show a **security warning** because the SSL certificate is self-signed:

```
⚠️ Your connection is not private
   NET::ERR_CERT_AUTHORITY_INVALID
```

**This is normal for development!** To proceed:
1. Click **"Advanced"**
2. Click **"Proceed to {HOST} (unsafe)"**

For production, replace with a valid certificate (Let's Encrypt, commercial CA, etc.)

## 📁 Project Structure

```
ClaudeLaravel/
├── src/                    # Laravel application
│   └── .env               # ⭐ SINGLE SOURCE OF TRUTH
├── docker/                 # Docker configurations
├── database/
│   ├── data/              # MySQL data (gitignored)
│   └── config/my.cnf      # MySQL configuration
├── docker-compose.yml      # Reads from src/.env
├── docker-up.sh           # Smart wrapper script
└── install-laravel.sh      # Installation script
```

## 🛠️ Usage

### Starting Containers

```bash
# First time (build required) - runs detached by default
./docker-up.sh --build

# Subsequent starts (detached by default)
./docker-up.sh

# Run in foreground to see logs (useful for debugging)
./docker-up.sh --foreground

# With build in foreground
./docker-up.sh --build --foreground
```

**Important Notes**:
- `docker-up.sh` runs containers **detached by default** (background)
- Use `--foreground` flag to see logs in your terminal
- Script auto-detects development/production mode from `src/.env`
- Script displays access URLs after startup
- **Migrations are NOT run automatically** - you must run them manually

### Common Commands

```bash
# Run migrations (REQUIRED after first install)
docker exec -it laravel-app php artisan migrate --force

# Artisan commands
docker exec -it laravel-app php artisan make:model Post

# Composer
docker exec -it laravel-app composer require package/name

# NPM (development mode only)
docker exec -it laravel-app npm install
docker exec -it laravel-app npm run dev

# Create Filament admin user
docker exec -it laravel-app php artisan make:filament-user

# Access container shell
docker exec -it laravel-app bash

# View logs (detached mode)
docker-compose logs -f
docker logs -f laravel-app

# Stop containers
docker-compose down

# Stop and remove volumes
docker-compose down -v
```

## ⚙️ Configuration

### src/.env (Laravel Configuration)

This is the ONLY file you need to configure (automatically set by `install-laravel.sh`):

```env
APP_ENV=local              # local/production (determines build target)
APP_DEBUG=true             # true for dev, false for prod
APP_URL=https://192.168.88.40  # Built from HOST (https://${HOST})

# Vite configuration for HMR over LAN
VITE_HMR_HOST=192.168.88.40    # Set to HOST (auto-configured)

DB_CONNECTION=mysql
DB_HOST=mysql              # Container name (DO NOT change)
DB_PORT=3306
DB_DATABASE=laravel        # Your database name
DB_USERNAME=laravel        # Your database user
DB_PASSWORD=laravel        # Your database password
```

**Key Configuration Details**:
- `HOST` is asked once during installation (auto-detects your LAN IP)
- `APP_URL` is automatically built as `https://${HOST}`
- `VITE_HMR_HOST` is set to `${HOST}` for LAN access
- Vite config is generated automatically (no stub files needed)

### Development vs Production

**Development** (`APP_ENV=local`):
- Vite HMR enabled with HTTPS (port 5173)
- Laravel Debugbar included
- Node.js and Composer available
- OPcache revalidation enabled
- Display errors enabled
- Vite config auto-generated with:
  - HTTPS using self-signed certificates
  - HMR host set to your configured HOST
  - Hot Module Replacement over LAN

**Production** (`APP_ENV=production`):
- Assets precompiled during build
- OPcache optimized
- No debug tools
- Smaller image size
- Display errors disabled

## 📦 What's Included

### PHP Extensions
- opcache, pdo, pdo_mysql
- mbstring, xml, bcmath, curl
- gd, zip, intl, apcu

### Development Tools (local mode only)
- Laravel 12
- FilamentPHP v4
- Laravel Debugbar
- Node.js 20 + npm
- Composer
- Vite with HMR

### Production Features
- PHP 8.4 FPM Alpine (lightweight)
- Nginx with HTTPS
- OPcache with JIT
- s6-overlay process supervision
- Non-root user (www-data)

## 🗄️ Database

**Connection from Laravel** (`src/.env`):
```env
DB_CONNECTION=mysql
DB_HOST=mysql
DB_PORT=3306
DB_DATABASE=laravel
DB_USERNAME=laravel
DB_PASSWORD=laravel
```

**Data Location**: `database/data/` (gitignored, persistent)

**MySQL Configuration**: `database/config/my.cnf`

### Access Database from Host

```bash
# MySQL is exposed on port 3306
mysql -h 127.0.0.1 -P 3306 -u laravel -p
# Password: laravel (or your configured password)
```

### Reset Database

```bash
docker-compose down
rm -rf database/data/*
./docker-up.sh --build
```

## 🔧 Customization

### Change PHP Settings
Edit `docker/php/php.ini`

### Change Nginx Settings
Edit `docker/nginx/laravel.conf`

### Change MySQL Settings
Edit `database/config/my.cnf`

### Add Redis (Optional)
Uncomment Redis service in `docker-compose.yml` and configure in `src/.env`:
```env
REDIS_HOST=redis
REDIS_PORT=6379
CACHE_DRIVER=redis
QUEUE_CONNECTION=redis
SESSION_DRIVER=redis
```

## 🆘 Troubleshooting

### Certificate Warning in Browser
Normal for self-signed certificates. Click "Advanced" → "Proceed to {HOST} (unsafe)".

This warning appears for both the main app (https://{HOST}) and Vite HMR (https://{HOST}:5173).

### Permission Issues
The installation script uses `sudo chmod 777` for critical directories. If you still have issues:
```bash
# Inside container
docker exec -it laravel-app chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache
docker exec -it laravel-app chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

# On host (if installation script failed)
sudo chmod -R 777 src/storage src/bootstrap/cache src/public src
```

### Database Connection Error
1. Check `src/.env` has `DB_HOST=mysql` (not localhost)
2. Ensure MySQL container is healthy: `docker-compose ps`
3. Check logs: `docker-compose logs mysql`
4. Wait for MySQL to be ready (check logs for "ready for connections")

### Vite HMR Not Working
1. Ensure you're using HTTPS: `https://{HOST}:5173`
2. Accept the self-signed certificate warning for port 5173
3. Check `VITE_HMR_HOST` is set in `src/.env`
4. Verify Vite is running: `docker logs laravel-app | grep vite`
5. Check firewall allows port 5173

### LAN Access Not Working
1. Verify HOST is set to your LAN IP (not localhost)
2. Check firewall on host machine allows ports 443 and 5173
3. Ensure devices are on the same network
4. Try accessing: `https://{YOUR_LAN_IP}`

### Wrong Build Target
The script reads `APP_ENV` from `src/.env`:
- Check: `grep APP_ENV src/.env`
- Should be `local` for development or `production` for prod
- Rebuild: `./docker-up.sh --build`

### Port Already in Use
```bash
# Check what's using port 443
sudo lsof -i :443

# Check what's using port 5173
sudo lsof -i :5173

# Or change port in docker-compose.yml
ports:
  - "8443:443"  # Use port 8443 instead
```

### Migrations Not Running
**This is by design!** Migrations are NOT run automatically. You must run them manually:
```bash
docker exec -it laravel-app php artisan migrate --force
```

### Container Logs (Detached Mode)
Since containers run detached by default:
```bash
# View all logs
docker-compose logs -f

# View specific service
docker logs -f laravel-app

# Or use foreground mode
./docker-up.sh --foreground
```

## 📚 Documentation

See `DOCKER_PROJECT_PLAN.md` for complete documentation and architecture details.

## 🎯 Workflow Examples

### New Feature Development
```bash
# 1. Run installation (interactive, auto-configures HOST)
./install-laravel.sh

# 2. Start containers (detached by default)
./docker-up.sh --build

# 3. Run migrations (required!)
docker exec -it laravel-app php artisan migrate --force

# 4. Install additional dependencies
docker exec -it laravel-app composer require some/package

# 5. Access app (using your configured HOST)
# Example: https://192.168.88.40
```

### Development with HMR
```bash
# 1. Start containers in foreground to see Vite logs
./docker-up.sh --foreground

# 2. Access app and accept SSL certificates for:
#    - https://{HOST} (main app)
#    - https://{HOST}:5173 (Vite HMR)

# 3. Edit files in src/resources/
#    - Changes auto-refresh in browser via HMR

# 4. Test on mobile device (same network)
#    - Access: https://{YOUR_LAN_IP}
```

### Deploy to Production
```bash
# 1. Update environment in src/.env
sed -i 's/APP_ENV=local/APP_ENV=production/' src/.env
sed -i 's/APP_DEBUG=true/APP_DEBUG=false/' src/.env

# 2. Build production image
./docker-up.sh --build

# 3. Run migrations
docker exec -it laravel-app php artisan migrate --force

# 4. Application is optimized automatically
#    - Assets precompiled
#    - OPcache optimized
#    - Vite dev server disabled
```

### Clone Existing Project
```bash
# 1. Clone repository
git clone https://your-repo.git src/

# 2. Copy and configure .env
cp src/.env.example src/.env
# Edit src/.env:
#   - Set APP_ENV=local
#   - Set APP_URL=https://{YOUR_HOST}
#   - Set VITE_HMR_HOST={YOUR_HOST}
#   - Configure DB_HOST=mysql
#   - Configure DB_* variables

# 3. Start containers
./docker-up.sh --build

# 4. Install dependencies and migrate
docker exec -it laravel-app composer install
docker exec -it laravel-app php artisan key:generate
docker exec -it laravel-app php artisan migrate --force
docker exec -it laravel-app npm install
```

## 📄 License

This Docker setup is open-source. Your Laravel application follows its own license.

## 🤝 Contributing

Issues and enhancement requests are welcome!
