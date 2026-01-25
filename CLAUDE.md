# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Docker-based Laravel 12 + FilamentPHP v5 development environment with automatic dev/prod mode switching. Single Docker configuration adapts based on `APP_ENV` in `src/.env`.

**Tech Stack:**
- PHP 8.4 FPM Alpine, Laravel 12, FilamentPHP v5, Livewire 4
- Vite 7, Tailwind CSS 4, Alpine.js (via Filament)
- Nginx with auto-generated HTTPS, MySQL 8.0
- s6-overlay v3 for process supervision

## Commands

### Docker Operations (from project root)
```bash
./install-laravel.sh -i      # Interactive fresh install
./install-laravel.sh -if     # Non-interactive install (uses .env.install defaults)
./install-laravel.sh -cf     # Clean install (removes src/ and database/)
./docker-up.sh -bd           # Build and start detached
./docker-up.sh -bf           # Build and start foreground (see logs)
docker-compose down          # Stop containers
```

### Inside Container
```bash
docker exec -it laravel-app php artisan migrate              # Run migrations
docker exec -it laravel-app php artisan make:filament-user   # Create admin
docker exec -it laravel-app php artisan test --compact       # Run all tests
docker exec -it laravel-app php artisan test --filter=testName  # Run single test
docker exec -it laravel-app vendor/bin/pint --dirty          # Format changed PHP files
docker exec -it laravel-app npm run build                    # Build assets (production)
```

### From src/ Directory
```bash
php artisan test --compact                    # Run all tests
php artisan test tests/Feature/ExampleTest.php  # Run test file
php artisan test --filter=testName            # Run specific test
vendor/bin/pint --dirty                       # Format changed files with Laravel Pint
composer run dev                              # Start dev mode (Vite + queue + scheduler)
npm run dev                                   # Vite dev server only
npm run build                                 # Build production assets
```

## Architecture

### Container Services (s6-overlay)
```
Container Start (root)
    │
    ├─► init-usermod (oneshot) - Maps www-data UID/GID to host user
    ├─► init-assets (oneshot) - Builds assets in production, skips in dev
    │
    └─► Longrun services (as www-data):
        ├─ php-fpm (:9000)
        ├─ nginx (:80, :443)
        ├─ scheduler (artisan schedule:work)
        ├─ queue-worker (artisan queue:work)
        └─ vite-dev (:5173, dev only)
```

### Environment Detection
`docker-up.sh` reads `APP_ENV` from `src/.env`:
- `APP_ENV=local` → Development mode (Vite HMR enabled)
- `APP_ENV=production` → Production mode (assets pre-built, vite-dev disabled)

### Key Directories
- `src/` - Laravel application (all PHP code lives here)
- `docker/` - Docker configs, s6-overlay services, nginx/php configs
- `database/data/` - MySQL persistent data (gitignored)

## Laravel Development Guidelines

See `src/CLAUDE.md` for comprehensive Laravel Boost guidelines covering:
- Laravel 12 conventions (middleware in bootstrap/app.php, casts as methods)
- FilamentPHP v5 patterns (SDUI, Actions, testing with Livewire::test)
- Livewire 4 (server-side state, wire:key in loops, lifecycle hooks)
- Tailwind CSS v4 (CSS-first @theme config, no tailwind.config.js)
- PHPUnit testing (use `php artisan make:test`, run minimal tests with --filter)
- Laravel Pint (always run `vendor/bin/pint --dirty` before finalizing)

## Key Conventions

- Use `php artisan make:*` commands with `--no-interaction` flag
- Prefer Eloquent over raw DB queries; use eager loading to prevent N+1
- Create Form Request classes for validation (not inline in controllers)
- Run `vendor/bin/pint --dirty` before committing PHP changes
- Most tests should be Feature tests, not Unit tests
- Use factories when creating models in tests

## Access URLs

- App: `https://localhost` or `https://{LAN_IP}`
- Admin panel: `https://{HOST}/admin`
- Vite HMR (dev): `https://{HOST}:5173` (accept self-signed cert)
