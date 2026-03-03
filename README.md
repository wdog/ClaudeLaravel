# Laravel Docker + FilamentPHP v5

A smart Docker environment that automatically adapts to your needs.

Set `APP_ENV=local` in your `.env` and get a full development setup with Vite HMR, debugging tools, and hot reload. Switch to `APP_ENV=production` and the same Docker setup builds an optimized, secure production image.

**One configuration, two environments.** No separate docker-compose files, no manual switching. Just change your `.env` and rebuild.

---

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
./manager.sh -bd

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

### manager.sh

```bash
./manager.sh -b       # Build only
./manager.sh -d       # Start detached
./manager.sh -f       # Start foreground (see logs)
./manager.sh -bd      # Build and start detached
./manager.sh -bf      # Build and start foreground
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

# Restart (from project root)
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d

# Restart from src/ folder (Bash)
(cd .. && docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d)

# Restart from src/ folder (Fish shell)
cd ..; and docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d; and cd src
```

### Shell aliases

Add these aliases to run Docker commands from the `src/` folder.

**Bash** (`~/.bashrc`):
```bash
alias dcup='(cd .. && docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d)'
alias dcdown='(cd .. && docker-compose down)'
alias dclogs='(cd .. && docker-compose logs -f)'
```

**Fish** (`~/.config/fish/config.fish`):
```fish
alias dcup 'cd ..; and docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d; and cd src'
alias dcdown 'cd ..; and docker-compose down; and cd src'
alias dclogs 'cd ..; and docker-compose logs -f'
```

## Project Structure

```
ClaudeLaravel/
├── src/                  # Laravel app (created by install)
├── docker/               # Docker configs
│   ├── s6-overlay/       # s6-rc service definitions
│   │   ├── s6-rc.d/      # Service configs (init-usermod, php-fpm, nginx, vite-dev, etc.)
│   │   └── scripts/      # Init scripts
│   ├── nginx/            # Nginx configs
│   └── php/              # PHP configs
├── database/data/        # MySQL data (gitignored)
├── test/                 # Test scripts
├── .env.install          # Install defaults
├── install-laravel.sh    # Installer
└── manager.sh          # Start script
```

## Features

- **PHP 8.4** FPM Alpine
- **Nginx** with auto HTTPS (self-signed)
- **MySQL 8.0**
- **FilamentPHP v5**
- **Vite** with HMR over HTTPS
- **s6-overlay v3** process supervision with proper service dependencies
- **Automatic UID/GID mapping** - www-data matches host user for seamless file permissions
- Auto-detect dev/prod from `src/.env`

---

## Development Mode (`APP_ENV=local`)

### Setup

1. Set in `src/.env`:
   ```env
   APP_ENV=local
   APP_DEBUG=true
   ```

2. Build and start:
   ```bash
   ./manager.sh -bd
   ```

### What runs

| Service | Status | Description |
|---------|--------|-------------|
| init-usermod | runs | Maps www-data UID to host user |
| init-assets | skips build | Vite HMR handles assets |
| php-fpm | runs | PHP FastCGI |
| nginx | runs | Web server |
| vite-dev | runs | `npm run dev` with HMR |
| scheduler | runs | `php artisan schedule:work` |
| queue-worker | runs | `php artisan queue:work` |

### Workflow

- Edit files in `src/` - changes reflect immediately
- CSS/JS changes hot-reload via Vite HMR
- Access app at `https://{HOST}`
- Vite HMR at `https://{HOST}:5173`

---

## Production Mode (`APP_ENV=production`)

### Setup

1. Set in `src/.env`:
   ```env
   APP_ENV=production
   APP_DEBUG=false
   DEBUGBAR_ENABLED=false
   ```

2. Build and start:
   ```bash
   ./manager.sh -bd
   ```

### What runs

| Service | Status | Description |
|---------|--------|-------------|
| init-usermod | runs | Maps www-data UID to host user |
| init-assets | runs | `npm run build`, removes `hot` file |
| php-fpm | runs | PHP FastCGI |
| nginx | runs | Web server |
| vite-dev | disabled | Not needed, assets pre-built |
| scheduler | runs | `php artisan schedule:work` |
| queue-worker | runs | `php artisan queue:work` |

### Workflow

- Assets compiled automatically at container start
- To rebuild assets manually:
  ```bash
  docker exec -u www-data -it laravel-app npm run build
  ```
- Scheduler runs cron jobs automatically
- Queue worker processes jobs automatically

### Post-deploy commands

```bash
# Run migrations
docker exec -it laravel-app php artisan migrate --force

# Clear and rebuild caches
docker exec -it laravel-app php artisan optimize

# Create admin user (if needed)
docker exec -it laravel-app php artisan make:filament-user
```

---

## How It Works

### Container Build Flow

```
docker-compose up --build
        │
        ▼
┌──────────────────────────────────┐
│  1. Build Docker Image           │
│     ├─ PHP 8.4 FPM Alpine        │
│     ├─ s6-overlay v3 installed   │
│     ├─ Nginx configured          │
│     ├─ Node.js + npm installed   │
│     └─ SSL certificates generated│
└──────────────────────────────────┘
        │
        ▼
┌──────────────────────────────────┐
│  2. Start Container (as root)    │
│     └─ s6-overlay takes control  │
└──────────────────────────────────┘
        │
        ▼
    s6 Startup
```

### s6 Startup Flow

```
Container Start
      │
      ▼
┌─────────────────────────────────────────┐
│  init-usermod (oneshot, as root)        │
│  ├─ Map www-data UID/GID to host user   │
│  ├─ Create PHP-FPM socket directory     │
│  └─ Fix Laravel storage permissions     │
└─────────────────────────────────────────┘
      │
      ▼
┌─────────────────────────────────────────┐
│  init-assets (oneshot)                  │
│  ├─ PRODUCTION: npm run build           │
│  └─ DEVELOPMENT: skip (Vite HMR active) │
└─────────────────────────────────────────┘
      │
      ▼
┌─────────────────────────────────────────┐
│  Longrun Services (as www-data)         │
│                                         │
│  BOTH MODES:                            │
│  ├─ php-fpm     (PHP FastCGI)           │
│  ├─ nginx       (web server)            │
│  ├─ scheduler   (artisan schedule:work) │
│  └─ queue-worker (artisan queue:work)   │
│                                         │
│  DEVELOPMENT ONLY:                      │
│  └─ vite-dev    (npm run dev, HMR)      │
└─────────────────────────────────────────┘
```

### Development vs Production

| Aspect | Development | Production |
|--------|-------------|------------|
| `APP_ENV` | local | production |
| Assets | Vite HMR (live) | Pre-built at startup |
| vite-dev | ✅ Running | ❌ Disabled |
| scheduler | ✅ Running | ✅ Running |
| queue-worker | ✅ Running | ✅ Running |
| Hot file | Created by Vite | Removed at startup |
| Debug | Enabled | Disabled |

---

## Troubleshooting

### Permission issues

Permissions should work automatically thanks to UID/GID mapping. If you still have issues:

```bash
# Verify UID mapping (should match your host user)
docker exec laravel-app id www-data

# Run the test script to verify everything works
./test/test-permissions.sh
```

### Database connection error
Check `src/.env` has `DB_HOST=mysql`

### Vite HMR not working
1. Accept certificate at `https://{HOST}:5173`
2. Check `VITE_HMR_HOST` in `src/.env`

### Reset everything
```bash
./install-laravel.sh -cf
./manager.sh -bd
docker exec -it laravel-app php artisan migrate --force
```

## License

MIT
