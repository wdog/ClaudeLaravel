# Laravel Docker Project with FilamentPHP

Docker-based Laravel development environment with PHP 8.4 Alpine FPM, Nginx HTTPS, MySQL, and FilamentPHP v4 support.

**Key Feature**: Automatically detects development/production mode from `src/.env` file!

## 🚀 Quick Start

### Option 1: New Laravel Project (Automated)

```bash
# Run the installation script
./install-laravel.sh

# Or clean install (removes existing src/ and database/data/)
./install-laravel.sh --clean

# Start containers (auto-detects mode from src/.env)
./docker-up.sh --build
```

**Clean Install Option**:
- `./install-laravel.sh --clean` removes all existing Laravel code and database data
- Asks for confirmation before deleting
- Useful for starting completely fresh
- **WARNING**: Irreversible action!

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

# Start containers
./docker-up.sh --build
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

**All Modes** (Development & Production use same ports):
- HTTPS: `https://localhost` ✅ Recommended (port 443)
- HTTP: `http://localhost` → Redirects to HTTPS (port 80)
- Vite HMR: `http://localhost:5173` (Development only)
- Filament Admin: `https://localhost/admin`

### Browser Security Warning

Your browser will show a **security warning** because the SSL certificate is self-signed:

```
⚠️ Your connection is not private
   NET::ERR_CERT_AUTHORITY_INVALID
```

**This is normal for development!** To proceed:
1. Click **"Advanced"**
2. Click **"Proceed to localhost (unsafe)"**

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
# First time (build required)
./docker-up.sh --build

# Subsequent starts
./docker-up.sh

# Detached mode (background)
./docker-up.sh --detach

# With build and detached
./docker-up.sh --build --detach
```

### Common Commands

```bash
# Artisan commands
docker exec -it laravel-app php artisan migrate
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

# View logs
docker-compose logs -f app
docker-compose logs -f mysql

# Stop containers
docker-compose down

# Stop and remove volumes
docker-compose down -v
```

## ⚙️ Configuration

### src/.env (Laravel Configuration)

This is the ONLY file you need to configure:

```env
APP_ENV=local              # local/production (determines build target)
APP_DEBUG=true             # true for dev, false for prod
APP_URL=https://localhost:8443

DB_CONNECTION=mysql
DB_HOST=mysql              # Container name (DO NOT change)
DB_PORT=3306
DB_DATABASE=laravel        # Your database name
DB_USERNAME=laravel        # Your database user
DB_PASSWORD=laravel        # Your database password
```

### Development vs Production

**Development** (`APP_ENV=local`):
- Vite HMR enabled (port 5173)
- Laravel Debugbar included
- Node.js and Composer available
- OPcache revalidation enabled
- Display errors enabled

**Production** (`APP_ENV=production`):
- Assets precompiled
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
Normal for self-signed certificates. Click "Advanced" → "Proceed to localhost".

### Permission Issues
```bash
docker exec -it laravel-app chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache
docker exec -it laravel-app chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache
```

### Database Connection Error
1. Check `src/.env` has `DB_HOST=mysql` (not localhost)
2. Ensure MySQL container is healthy: `docker-compose ps`
3. Check logs: `docker-compose logs mysql`

### Wrong Build Target
The script reads `APP_ENV` from `src/.env`:
- Check: `grep APP_ENV src/.env`
- Should be `local` for development or `production` for prod
- Rebuild: `./docker-up.sh --build`

### Port Already in Use
```bash
# Check what's using port 8443
lsof -i :8443

# Or change port in docker-compose.yml
ports:
  - "9443:443"  # Use port 9443 instead
```

## 📚 Documentation

See `DOCKER_PROJECT_PLAN.md` for complete documentation and architecture details.

## 🎯 Workflow Examples

### New Feature Development
```bash
# 1. Ensure development mode
echo "APP_ENV=local" >> src/.env

# 2. Start containers
./docker-up.sh --build

# 3. Install dependencies
docker exec -it laravel-app composer require some/package

# 4. Run migrations
docker exec -it laravel-app php artisan migrate

# 5. Access app
open https://localhost:8443
```

### Deploy to Production
```bash
# 1. Update environment
sed -i 's/APP_ENV=local/APP_ENV=production/' src/.env
sed -i 's/APP_DEBUG=true/APP_DEBUG=false/' src/.env

# 2. Build production image
./docker-up.sh --build

# 3. Application is optimized automatically
```

### Clone Existing Project
```bash
# 1. Clone repository
git clone https://your-repo.git src/

# 2. Copy and configure .env
cp src/.env.example src/.env
# Edit src/.env:
#   - Set APP_ENV=local
#   - Configure DB_* variables
#   - Set DB_HOST=mysql

# 3. Start containers
./docker-up.sh --build

# 4. Install dependencies and migrate
docker exec -it laravel-app composer install
docker exec -it laravel-app php artisan key:generate
docker exec -it laravel-app php artisan migrate
```

## 📄 License

This Docker setup is open-source. Your Laravel application follows its own license.

## 🤝 Contributing

Issues and enhancement requests are welcome!
