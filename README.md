# Laravel Docker Project with FilamentPHP

Docker-based Laravel development environment with PHP 8.4 Alpine FPM, Nginx, MySQL, and FilamentPHP v4 support.

## 🚀 Quick Start

### Option 1: New Laravel Project (Automated)

```bash
# Run the installation script
./install-laravel.sh

# Build and start containers
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up --build
```

Access your application:
- **App**: `https://localhost:8443`
- **Filament Admin**: `https://localhost:8443/admin`

Create Filament admin user:
```bash
docker exec -it laravel-app php artisan make:filament-user
```

### Option 2: Existing Laravel Project

```bash
# Clone your Laravel project
git clone https://github.com/your/project.git src/

# Copy and configure .env
cp src/.env.example src/.env
# Edit src/.env with your settings

# Build and start containers
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up --build
```

## 📋 Features

- **PHP 8.4** FPM Alpine
- **Nginx** with HTTPS (self-signed certificate, 10 years validity)
- **MySQL 8.0** with persistent data
- **Redis** (optional)
- **FilamentPHP v4** ready
- **Vite** HMR support in development
- **s6-overlay** for process supervision
- **Auto-detection** of environment from `src/.env`

## 🔐 HTTPS Access

The container generates a self-signed SSL certificate automatically.

**Access from**:
- Localhost: `https://localhost:8443`
- LAN IP: `https://192.168.x.x:8443` (use your local IP)

**Certificate includes**:
- localhost, *.localhost
- 127.0.0.1
- Your LAN IP (auto-detected)
- Private network ranges (192.168.x.x, 172.16.x.x, 10.x.x.x)

## 📁 Project Structure

```
ClaudeLaravel/
├── src/                    # Laravel application (git clone here)
│   ├── .env               # Configure APP_ENV=local or production
│   └── ...
├── docker/                 # Docker configurations
│   ├── Dockerfile
│   ├── php/
│   ├── nginx/
│   └── scripts/
├── database/
│   ├── data/              # MySQL data (auto-created, gitignored)
│   └── config/
│       └── my.cnf         # MySQL configuration
├── docker-compose.yml      # Production config
├── docker-compose.dev.yml  # Development overrides
└── install-laravel.sh      # Installation script
```

## 🎯 Environment Detection

The container automatically detects the environment from `src/.env`:
- `APP_ENV=local` → Development Mode
- `APP_ENV=production` → Production Mode

**Development Mode**:
- Vite HMR enabled
- Debug enabled
- OPcache revalidation on

**Production Mode**:
- Assets precompiled
- Debug disabled
- OPcache optimized

## 🛠️ Common Commands

### Start Development
```bash
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up
```

### Start Production
```bash
docker-compose up -d
```

### Run Artisan Commands
```bash
docker exec -it laravel-app php artisan migrate
docker exec -it laravel-app php artisan make:model Post
```

### Run Composer
```bash
docker exec -it laravel-app composer require package/name
```

### Run NPM (in development)
```bash
docker exec -it laravel-app npm install
docker exec -it laravel-app npm run dev
```

### View Logs
```bash
docker-compose logs -f app
```

### Access Container Shell
```bash
docker exec -it laravel-app bash
```

## 🗄️ Database

**Connection from Laravel** (`src/.env`):
```env
DB_CONNECTION=mysql
DB_HOST=mysql
DB_PORT=3306
DB_DATABASE=laravel
DB_USERNAME=laravel
DB_PASSWORD=secret
```

**Data Location**: `database/data/` (gitignored)

**MySQL Configuration**: `database/config/my.cnf`

### Reset Database
```bash
# Stop containers
docker-compose down

# Remove data
rm -rf database/data/*

# Restart
docker-compose up
```

## 📦 What's Included

### PHP Extensions
- opcache, pdo, pdo_mysql
- mbstring, xml, bcmath, curl
- gd, zip, intl
- apcu
- redis (optional)

### Tools
- Composer
- Node.js 20 (development)
- npm
- Git

## 🔧 Customization

### Change PHP Settings
Edit `docker/php/php.ini`

### Change Nginx Settings
Edit `docker/nginx/laravel.conf`

### Change MySQL Settings
Edit `database/config/my.cnf`

## 📚 Documentation

See `DOCKER_PROJECT_PLAN.md` for complete documentation.

## 🆘 Troubleshooting

### Permission Issues
```bash
docker exec -it laravel-app chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache
docker exec -it laravel-app chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache
```

### Certificate Warning in Browser
This is normal for self-signed certificates. Click "Advanced" → "Proceed to localhost" (or your IP).

### Database Connection Error
Make sure MySQL container is running and healthy:
```bash
docker-compose ps
docker-compose logs mysql
```

## 📄 License

This Docker setup is open-source. Your Laravel application follows its own license.

## 🤝 Contributing

Feel free to submit issues and enhancement requests!
