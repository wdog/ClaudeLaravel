# Struttura del Progetto

Organizzazione delle directory e dei file del progetto.

---

## Directory Tree

```
ClaudeLaravel/
├── src/                          # Laravel application (creata da install)
│   ├── app/
│   ├── bootstrap/
│   ├── config/
│   ├── database/
│   ├── public/
│   ├── resources/
│   ├── routes/
│   ├── storage/
│   ├── tests/
│   ├── vendor/                   # Composer dependencies (gitignored)
│   ├── node_modules/             # NPM dependencies (gitignored)
│   ├── .env                      # Environment config
│   ├── composer.json
│   ├── package.json
│   └── vite.config.js
│
├── docker/                       # Docker configurations
│   ├── Dockerfile                # Multi-stage Dockerfile
│   │
│   ├── nginx/                    # Nginx configs
│   │   ├── nginx.conf            # Main config
│   │   ├── laravel.conf          # Virtual host
│   │   └── vite-proxy.conf       # Vite HMR proxy (dev)
│   │
│   ├── php/                      # PHP configs
│   │   ├── php.ini               # PHP settings
│   │   ├── php-fpm.conf          # FPM pool config
│   │   └── opcache.ini           # OPcache settings
│   │
│   ├── s6-overlay/               # s6-rc service definitions
│   │   ├── s6-rc.d/              # Services directory
│   │   │   ├── user/             # User bundle (main)
│   │   │   │   ├── type          # "bundle"
│   │   │   │   └── contents.d/   # Services to start
│   │   │   │       ├── init-usermod
│   │   │   │       ├── init-assets
│   │   │   │       ├── php-fpm
│   │   │   │       ├── nginx
│   │   │   │       ├── scheduler
│   │   │   │       ├── queue-worker
│   │   │   │       └── vite-dev
│   │   │   │
│   │   │   ├── init-usermod/     # UID/GID mapping (oneshot)
│   │   │   │   ├── type          # "oneshot"
│   │   │   │   ├── up            # Runs init-usermod.sh
│   │   │   │   └── dependencies.d/
│   │   │   │
│   │   │   ├── init-assets/      # Asset build (oneshot)
│   │   │   │   ├── type          # "oneshot"
│   │   │   │   ├── up            # Runs init-assets.sh
│   │   │   │   └── dependencies.d/
│   │   │   │       └── init-usermod
│   │   │   │
│   │   │   ├── php-fpm/          # PHP FastCGI (longrun)
│   │   │   │   ├── type          # "longrun"
│   │   │   │   ├── run           # Start script
│   │   │   │   └── dependencies.d/
│   │   │   │       └── init-usermod
│   │   │   │
│   │   │   ├── nginx/            # Web server (longrun)
│   │   │   │   ├── type          # "longrun"
│   │   │   │   ├── run           # Start script
│   │   │   │   └── dependencies.d/
│   │   │   │       ├── init-assets
│   │   │   │       └── php-fpm
│   │   │   │
│   │   │   ├── scheduler/        # Laravel cron (longrun)
│   │   │   │   ├── type          # "longrun"
│   │   │   │   ├── run           # Start script
│   │   │   │   └── dependencies.d/
│   │   │   │       └── init-usermod
│   │   │   │
│   │   │   ├── queue-worker/     # Laravel queue (longrun)
│   │   │   │   ├── type          # "longrun"
│   │   │   │   ├── run           # Start script
│   │   │   │   └── dependencies.d/
│   │   │   │       └── init-usermod
│   │   │   │
│   │   │   └── vite-dev/         # Vite HMR (longrun, dev only)
│   │   │       ├── type          # "longrun"
│   │   │       ├── run           # Start script (checks APP_ENV)
│   │   │       └── dependencies.d/
│   │   │           └── init-usermod
│   │   │
│   │   └── scripts/              # Init scripts
│   │       ├── init-usermod.sh   # UID/GID mapping
│   │       └── init-assets.sh    # Asset compilation
│   │
│   └── scripts/                  # Utility scripts
│       ├── entrypoint.sh         # Container entrypoint (legacy)
│       ├── generate-ssl-cert.sh  # SSL certificate generator
│       ├── healthcheck.sh        # Container health check
│       ├── init-laravel.sh       # Laravel initialization
│       └── wait-for-db.sh        # Database readiness check
│
├── database/                     # MySQL data and config
│   ├── config/
│   │   └── my.cnf                # MySQL configuration
│   └── data/                     # MySQL data (gitignored)
│
├── test/                         # Test scripts
│   └── test-permissions.sh       # Permission verification
│
├── docs/                         # Documentation
│   ├── README.md                 # Index
│   ├── 01-overview.md
│   ├── 02-prerequisites.md
│   └── ...
│
├── docker-compose.yml            # Production compose
├── docker-compose.dev.yml        # Development overrides
├── install-laravel.sh            # Installation script
├── docker-up.sh                  # Start script
├── .env.example                  # Environment template
├── .env.install                  # Install defaults
├── .dockerignore                 # Docker build exclusions
├── .gitignore                    # Git exclusions
└── README.md                     # Main documentation
```

---

## Descrizione Directory

### `src/`

Directory Laravel application. Creata da `install-laravel.sh`.

- **Montata** come volume in Docker
- Contiene il codice PHP, views, routes, etc.
- `vendor/` e `node_modules/` sono gitignored

### `docker/`

Configurazioni Docker e servizi.

| Subdirectory | Contenuto |
|--------------|-----------|
| `nginx/` | Configurazioni web server |
| `php/` | Configurazioni PHP e FPM |
| `s6-overlay/` | Definizioni servizi s6-rc |
| `scripts/` | Script di utility |

### `database/`

Dati e configurazione MySQL.

- `config/my.cnf` - Configurazione MySQL customizzata
- `data/` - Dati MySQL persistenti (gitignored)

### `docs/`

Documentazione completa del progetto.

### `test/`

Script di test e verifica.

---

## File Principali

### Root Level

| File | Descrizione |
|------|-------------|
| `docker-compose.yml` | Configurazione production |
| `docker-compose.dev.yml` | Override development |
| `install-laravel.sh` | Script installazione Laravel |
| `docker-up.sh` | Script avvio container |
| `.env.install` | Valori default installazione |

### Docker Scripts

| File | Descrizione |
|------|-------------|
| `generate-ssl-cert.sh` | Genera certificato SSL self-signed |
| `healthcheck.sh` | Verifica salute container |
| `wait-for-db.sh` | Attende MySQL ready |

### s6 Scripts

| File | Descrizione |
|------|-------------|
| `init-usermod.sh` | Mappa UID/GID www-data |
| `init-assets.sh` | Compila asset (production) |

---

## Volumi Docker

### Named Volumes (Cache)

```yaml
volumes:
  laravel-cache:      # storage/framework/cache
  laravel-views:      # storage/framework/views
  laravel-sessions:   # storage/framework/sessions
```

Migliorano le performance per i file temporanei.

### Bind Mounts

| Host | Container | Note |
|------|-----------|------|
| `./src` | `/var/www/html` | Laravel app |
| `./database/data` | `/var/lib/mysql` | MySQL data |
| `./database/config` | `/etc/mysql/conf.d` | MySQL config |

---

## Persistenza Dati

### Persistiti (sopravvivono a `docker-compose down`)

- `database/data/` - Dati MySQL
- `src/` - Codice Laravel
- `src/storage/logs/` - Log Laravel

### Non Persistiti (ricreati ad ogni avvio)

- Named volumes cache (opzionale, migliora performance)
- Container filesystem

### Gitignored

```
database/data/
src/vendor/
src/node_modules/
src/.env
src/storage/logs/*
```

---

## Permessi File

Il sistema usa UID/GID mapping automatico:

1. `init-usermod.sh` mappa `www-data` al tuo UID host
2. Tutti i file hanno gli stessi permessi dentro e fuori il container
3. Nessun problema di ownership

### Permessi Standard

| Directory | Permessi |
|-----------|----------|
| `src/` | 775 |
| `storage/` | 775 |
| `bootstrap/cache/` | 775 |
| Files | 664 |

---

**[⬅️ Prerequisiti](02-prerequisites.md)** | **[Dockerfile ➡️](04-dockerfile.md)**
