# Laravel Docker + FilamentPHP v5

Docker environment for Laravel 12 with PHP 8.4, Nginx HTTPS, MySQL, and FilamentPHP v5.

## Quick Start

### 1. Configure defaults (optional)

Edit `.env.install` to set your preferences:

```env
APP_NAME="MyApp"
APP_ENV="local"
DB_DATABASE="laravel"
DB_USERNAME="laravel"
DB_PASSWORD="laravel"
```

### 2. Install

```bash
# Interactive installation
./install-laravel.sh -i

# Or with defaults from .env.install (no prompts)
./install-laravel.sh -if
```

### 3. Start

```bash
# Build and run in background
./docker-up.sh -bd

# Run migrations
docker exec -it laravel-app php artisan migrate --force

# Create admin user
docker exec -it laravel-app php artisan make:filament-user
```

### 4. Access

- **App**: `https://localhost` or `https://{YOUR_LAN_IP}`
- **Admin**: `https://{HOST}/admin`
- **Vite HMR**: `https://{HOST}:5173` (dev only)

> Accept the self-signed certificate warning in your browser.

## Commands

### install-laravel.sh

```bash
./install-laravel.sh -i       # New installation (interactive)
./install-laravel.sh -if      # New installation (use defaults)
./install-laravel.sh -c       # Clean install (removes src/ and database/)
./install-laravel.sh -cf      # Clean install (use defaults)
```

### docker-up.sh

```bash
./docker-up.sh -b       # Build only
./docker-up.sh -d       # Start detached
./docker-up.sh -f       # Start foreground (see logs)
./docker-up.sh -bd      # Build and start detached
./docker-up.sh -bf      # Build and start foreground
```

### Common Docker commands

```bash
# Artisan
docker exec -it laravel-app php artisan migrate
docker exec -it laravel-app php artisan make:model Post

# Composer
docker exec -it laravel-app composer require package/name

# NPM (dev only)
docker exec -it laravel-app npm install

# Logs
docker-compose logs -f

# Stop
docker-compose down
```

## Project Structure

```
ClaudeLaravel/
├── src/                  # Laravel app (created by install)
├── docker/               # Docker configs
├── database/data/        # MySQL data (gitignored)
├── .env.install          # Install defaults
├── install-laravel.sh    # Installer
└── docker-up.sh          # Start script
```

## Features

- **PHP 8.4** FPM Alpine
- **Nginx** with auto HTTPS (self-signed)
- **MySQL 8.0**
- **FilamentPHP v5**
- **Vite** with HMR over HTTPS
- **s6-overlay** process supervision
- Auto-detect dev/prod from `src/.env`

## Troubleshooting

### Permission issues
```bash
sudo chmod -R 777 src/storage src/bootstrap/cache
```

### Database connection error
Check `src/.env` has `DB_HOST=mysql`

### Vite HMR not working
1. Accept certificate at `https://{HOST}:5173`
2. Check `VITE_HMR_HOST` in `src/.env`

### Reset everything
```bash
./install-laravel.sh -cf
./docker-up.sh -bd
docker exec -it laravel-app php artisan migrate --force
```

## License

MIT
