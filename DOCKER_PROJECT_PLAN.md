# Docker Laravel Production-Ready Project Plan
## Con s6-overlay, FilamentPHP e Vite Support

---

## 🚀 CURRENT IMPLEMENTATION STATUS (2026-01-11)

**Project Status**: ✅ Implementation Complete (Ready for Testing)

### Key Features Implemented

1. **Network Configuration**
   - Single HOST configuration (IP or domain) during installation
   - Auto-detects LAN IP as default
   - `APP_URL` built as `https://${HOST}` (HTTPS by default)
   - `VITE_HMR_HOST` set to `${HOST}` for LAN access
   - No port specification needed (uses standard 443)

2. **Vite with HTTPS**
   - Vite uses HTTPS with self-signed certificates
   - HMR accessible at `https://{HOST}:5173`
   - Vite config auto-generated during installation (no stub files)
   - Reads `VITE_HMR_HOST` from `.env`
   - Full LAN support for testing on mobile devices

3. **Installation & Workflow**
   - Interactive installation with `./install-laravel.sh`
   - `docker-up.sh` runs detached by default
   - Use `--foreground` flag to see logs
   - Migrations NOT run automatically (manual execution required)
   - Auto-detects development/production mode from `src/.env`

4. **Permission Handling**
   - Uses `sudo chmod 777` for storage/bootstrap/cache/public/src
   - Docker-based cleanup for vendor/node_modules
   - Handles MySQL data permissions correctly
   - Clean install option with `--clean` flag

5. **Documentation**
   - Complete README.md with current workflow
   - Updated docs/ directory
   - Comprehensive troubleshooting section
   - LAN access configuration documented

### Quick Start

```bash
# 1. Installation (interactive)
./install-laravel.sh

# 2. Start containers (detached)
./docker-up.sh --build

# 3. Run migrations (manual)
docker exec -it laravel-app php artisan migrate --force

# 4. Access app
# https://{HOST} (e.g., https://192.168.88.40)
```

---

## 📋 PREREQUISITI E REQUISITI

### Software Necessario
- **Docker Engine**: 24.0+
- **Docker Compose**: 2.20+
- **s6-overlay**: v3.x (per process supervision)
- **PHP**: 8.4 (Alpine FPM)
- **Nginx**: Alpine latest
- **Node.js**: 20 LTS (Alpine)
- **Database**: MySQL 8.0+

### Software Opzionale
- **Redis**: 7.x (Alpine) - per cache/queue/session (opzionale, si può usare file/database)

### Estensioni PHP Richieste
```
Core: opcache, pdo, pdo_mysql
Laravel: mbstring, xml, bcmath, curl, gd, zip, intl
```

### Estensioni PHP Opzionali
```
Cache: redis (se si usa Redis), apcu
```

### Dipendenze Alpine per PHP Extensions
```bash
# Pacchetti Alpine necessari per compilare estensioni PHP
apk add --no-cache \
    libzip-dev \
    libpng-dev \
    libjpeg-turbo-dev \
    freetype-dev \
    icu-dev \
    oniguruma-dev \
    libxml2-dev \
    curl-dev
```

---

## 🏗️ STRUTTURA DIRECTORY DEL PROGETTO

```
ClaudeLaravel/
├── docker/
│   ├── Dockerfile                          # Multi-stage build principale
│   ├── .dockerignore                       # Esclusioni build
│   │
│   ├── php/                                # Configurazioni PHP
│   │   ├── php.ini                        # Settings generali
│   │   ├── php-fpm.conf                   # FPM pool configuration
│   │   └── opcache.ini                    # OPcache production
│   │
│   ├── nginx/                              # Configurazioni Nginx
│   │   ├── nginx.conf                     # Main config
│   │   ├── laravel.conf                   # Virtual host Laravel
│   │   ├── vite-proxy.conf                # Proxy per Vite dev server
│   │   └── security-headers.conf          # Security headers
│   │
│   ├── s6-overlay/                         # s6 service definitions
│   │   └── s6-rc.d/
│   │       ├── user/
│   │       │   └── contents.d/            # Bundle servizi user-level
│   │       │       ├── php-fpm
│   │       │       ├── nginx
│   │       │       ├── scheduler
│   │       │       ├── queue-worker
│   │       │       └── vite-dev
│   │       │
│   │       ├── php-fpm/                   # Servizio PHP-FPM
│   │       │   ├── type                   # "longrun"
│   │       │   ├── run                    # Start script
│   │       │   └── finish                 # Cleanup script
│   │       │
│   │       ├── nginx/                     # Servizio Nginx
│   │       │   ├── type
│   │       │   ├── run
│   │       │   ├── finish
│   │       │   └── dependencies.d/
│   │       │       └── php-fpm            # Dipende da PHP-FPM
│   │       │
│   │       ├── scheduler/                 # Laravel Scheduler
│   │       │   ├── type
│   │       │   ├── run
│   │       │   └── dependencies.d/
│   │       │       └── php-fpm
│   │       │
│   │       ├── queue-worker/              # Laravel Queue Worker
│   │       │   ├── type
│   │       │   ├── run
│   │       │   └── dependencies.d/
│   │       │       └── php-fpm
│   │       │
│   │       └── vite-dev/                  # Vite Dev Server (dev only)
│   │           ├── type
│   │           └── run
│   │
│   └── scripts/                            # Utility scripts
│       ├── entrypoint.sh                  # Main entrypoint
│       ├── healthcheck.sh                 # Container health check
│       ├── init-laravel.sh                # Laravel initialization
│       └── wait-for-db.sh                 # Database wait script
│
├── src/                                    # Laravel application files
│   ├── app/
│   ├── bootstrap/
│   ├── config/
│   ├── database/
│   ├── public/
│   ├── resources/
│   ├── routes/
│   ├── storage/
│   ├── tests/
│   ├── artisan
│   ├── composer.json
│   ├── package.json
│   └── vite.config.js
│
├── database/                               # MySQL database files
│   ├── data/                              # MySQL data directory (montato in /var/lib/mysql)
│   └── config/                            # MySQL configuration files
│       └── my.cnf                         # Custom MySQL configuration
│
├── docker-compose.yml                      # Production configuration
├── docker-compose.dev.yml                  # Development overrides
├── docker-compose.override.yml.example     # Local overrides template
├── .env.example                            # Environment variables template
├── .dockerignore                           # Docker build exclusions
└── README.md                               # Documentation
```

---

## 🐳 IMMAGINI DOCKER BASE

### Immagini Alpine Utilizzate
```
Production & Development Base:
- php:8.4-fpm-alpine           # PHP-FPM 8.4 su Alpine Linux
- nginx:alpine                 # Nginx latest su Alpine
- composer:latest              # Composer su Alpine (per build)
- node:20-alpine              # Node.js 20 LTS su Alpine (per build e dev)

Services (separati):
- mysql:8.0                   # MySQL standalone (non Alpine per stability e performance)
- redis:7-alpine              # Redis 7 su Alpine (OPZIONALE)
```

### Vantaggi Alpine
- **Dimensioni ridotte**: Immagini più leggere (~50MB vs ~400MB Debian)
- **Sicurezza**: Superficie di attacco minimale
- **Performance**: Boot time più rapido
- **Compatibilità**: Supporto completo PHP 8.4 FPM

---

## 🐳 DOCKERFILE - Multi-Stage Build

### Stage 1: Base Image
```dockerfile
# Base: php:8.4-fpm-alpine
# Immagine base con PHP 8.4 FPM Alpine e estensioni necessarie
# Include s6-overlay per process supervision
# Installazione dipendenze Alpine (apk): nginx, bash, curl, etc.
```

### Stage 2: Composer Dependencies
```dockerfile
# Base: composer:latest (Alpine-based)
# Installazione dipendenze PHP con Composer
# Ottimizzazione autoloader per production
```

### Stage 3: Node/NPM Build
```dockerfile
# Base: node:20-alpine
# Build assets con Vite
# Solo per production (build statico)
```

### Stage 4: Production
```dockerfile
# Base: php:8.4-fpm-alpine
# Immagine finale minimale Alpine
# NOTA FASE 1: codice montato da ./src (non copiato)
# TODO FASE 2: Copiare assets buildati da stage 3
# TODO FASE 2: Copiare vendor da stage 2
# TODO FASE 2: Copiare codice sorgente ./src
# Setup s6-overlay
# Setup Nginx
# Utente non-root (www-data)
```

### Stage 5: Development (target alternativo)
```dockerfile
# Base: stage production
# Estende production con:
# - Node.js 20 Alpine per Vite dev server
# - Composer dev dependencies
# - Tools di sviluppo Alpine
```

---

## ⚙️ SERVIZI s6-OVERLAY

### 1. PHP-FPM (Priorità: Alta, Sempre Attivo)
**Scopo**: Esegue applicazione PHP Laravel
**Configurazione**:
- Pool dinamico con PM = ondemand
- Health check via ping/pong
- Graceful reload su SIGUSR2

### 2. Nginx (Priorità: Alta, Sempre Attivo)
**Scopo**: Web server e reverse proxy
**Dipendenze**: php-fpm
**Configurazione**:
- Serve file statici
- Proxy a PHP-FPM via Unix socket
- In dev: proxy Vite su porta 5173
- Security headers

### 3. Scheduler (Priorità: Media, Solo Production)
**Scopo**: Esegue Laravel scheduled tasks
**Dipendenze**: php-fpm
**Comando**: `php artisan schedule:work`
**Note**: Disabilitato in dev mode

### 4. Queue Worker (Priorità: Media, Configurabile)
**Scopo**: Processa queue jobs
**Dipendenze**: php-fpm
**Comando**: `php artisan queue:work --tries=3 --timeout=90`
**Note**: Configurabile via ENV (QUEUE_WORKER_ENABLED)

### 5. Vite Dev Server (Priorità: Bassa, Solo Development)
**Scopo**: Hot Module Replacement per frontend
**Porta**: 5173
**Note**: Attivo solo con APP_ENV=local

---

## 🔧 CONFIGURAZIONI

### PHP Configuration (php.ini)

#### Production Settings
```ini
; Performance
opcache.enable=1
opcache.memory_consumption=256
opcache.interned_strings_buffer=16
opcache.max_accelerated_files=20000
opcache.validate_timestamps=0
opcache.preload=/var/www/html/preload.php

; Memory
memory_limit=512M
upload_max_filesize=50M
post_max_size=50M

; Security
expose_php=Off
display_errors=Off
log_errors=On
error_log=/dev/stderr
```

#### Development Overrides
```ini
opcache.validate_timestamps=1
display_errors=On
```

### PHP-FPM Configuration (php-fpm.conf)
```ini
[www]
user = www-data
group = www-data
listen = /var/run/php-fpm.sock
listen.owner = www-data
listen.group = nginx
listen.mode = 0660

pm = dynamic
pm.max_children = 50
pm.start_servers = 5
pm.min_spare_servers = 5
pm.max_spare_servers = 35

; Health check
pm.status_path = /fpm-status
ping.path = /fpm-ping

; Catch workers output
catch_workers_output = yes
decorate_workers_output = no
```

### Nginx Configuration

#### Main nginx.conf
```nginx
user nginx;
worker_processes auto;
error_log /dev/stderr warn;
pid /var/run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /dev/stdout main;

    sendfile on;
    tcp_nopush on;
    keepalive_timeout 65;
    gzip on;

    include /etc/nginx/conf.d/*.conf;
}
```

#### Laravel Virtual Host (laravel.conf)
```nginx
server {
    listen 80;
    server_name _;
    root /var/www/html/public;

    index index.php index.html;
    charset utf-8;

    # Laravel front controller
    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    # PHP-FPM
    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
        include fastcgi_params;
    }

    # Deny access to hidden files
    location ~ /\. {
        deny all;
    }

    # Health check
    location /health {
        access_log off;
        return 200 "OK\n";
        add_header Content-Type text/plain;
    }
}
```

#### Vite Proxy (vite-proxy.conf) - Development Only
```nginx
# Include this in laravel.conf for dev mode
location ~ ^/(resources|node_modules|@vite|@id|@fs) {
    proxy_pass http://localhost:5173;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host $host;
}
```

### MySQL Configuration (database/config/my.cnf)
```ini
[mysqld]
# Performance
max_connections = 200
innodb_buffer_pool_size = 256M
innodb_log_file_size = 64M
innodb_flush_log_at_trx_commit = 2
innodb_flush_method = O_DIRECT

# Character Set
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci

# Security
bind-address = 0.0.0.0

# Logging
general_log = 0
slow_query_log = 1
slow_query_log_file = /var/lib/mysql/slow-query.log
long_query_time = 2

[client]
default-character-set = utf8mb4
```

### Vite Configuration (vite.config.js)
```javascript
import { defineConfig } from 'vite';
import laravel from 'laravel-vite-plugin';

export default defineConfig({
    plugins: [
        laravel({
            input: ['resources/css/app.css', 'resources/js/app.js'],
            refresh: true,
        }),
    ],
    server: {
        host: '0.0.0.0',
        port: 5173,
        strictPort: true,
        hmr: {
            host: 'localhost',
        },
    },
});
```

---

## 🚀 DOCKER COMPOSE CONFIGURATIONS

### docker-compose.yml (Production)
```yaml
services:
  app:
    build:
      context: .
      dockerfile: docker/Dockerfile
      target: production
    image: laravel-app:production
    container_name: laravel-app
    restart: unless-stopped
    environment:
      APP_ENV: production
      APP_DEBUG: false
      QUEUE_WORKER_ENABLED: true
      SCHEDULER_ENABLED: true
    volumes:
      - ./src:/var/www/html                      # Mount completo codice sorgente
    networks:
      - laravel-network
    depends_on:
      - mysql
      # - redis  # Decommenta se usi Redis
    healthcheck:
      test: ["CMD", "/docker/scripts/healthcheck.sh"]
      interval: 30s
      timeout: 10s
      retries: 3

  mysql:
    image: mysql:8.0
    container_name: laravel-mysql
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: secret
      MYSQL_DATABASE: laravel
      MYSQL_USER: laravel
      MYSQL_PASSWORD: secret
    volumes:
      - ./database/data:/var/lib/mysql          # Dati MySQL persistenti
      - ./database/config/my.cnf:/etc/mysql/conf.d/custom.cnf:ro  # Configurazione custom
    networks:
      - laravel-network

  # Redis (OPZIONALE - decommenta se necessario)
  # redis:
  #   image: redis:7-alpine
  #   container_name: laravel-redis
  #   restart: unless-stopped
  #   volumes:
  #     - redis-data:/data
  #   networks:
  #     - laravel-network

networks:
  laravel-network:
    driver: bridge

volumes:
  redis-data:  # Necessario solo se Redis è abilitato
```

### docker-compose.dev.yml (Development Overrides)
```yaml
services:
  app:
    build:
      target: development
    image: laravel-app:development
    environment:
      APP_ENV: local
      APP_DEBUG: true
      VITE_DEV_SERVER_ENABLED: true
    volumes:
      - ./src:/var/www/html
    ports:
      - "8443:443"   # HTTPS
      - "5173:5173"  # Vite HMR
```

---

## 🔐 SSL/HTTPS CONFIGURATION

### Self-Signed Certificate
L'immagine Docker genera automaticamente un **certificato SSL self-signed** durante il build:

**Caratteristiche**:
- **Validità**: 10 anni (3650 giorni)
- **Algoritmo**: RSA 2048 bit
- **Posizione**: `/etc/nginx/ssl/`
- **Files**:
  - Certificate: `/etc/nginx/ssl/nginx.crt`
  - Private Key: `/etc/nginx/ssl/nginx.key`

**Dettagli Certificato**:
```
Country (C): IT
State (ST): Italy
Locality (L): Rome
Organization (O): Laravel Docker
Organizational Unit (OU): Development
Common Name (CN): localhost
Subject Alternative Names:
  - DNS: localhost
  - DNS: *.localhost
  - IP: 127.0.0.1
  - IP: <LAN_IP> (rilevato automaticamente)
  - IP: 192.168.0.0/16 (private network)
  - IP: 172.16.0.0/12 (private network)
  - IP: 10.0.0.0/8 (private network)
```

**Supporto IP LAN**:
Il certificato include automaticamente l'IP LAN del container e i range delle reti private, permettendo l'accesso sicuro da:
- `https://{HOST}`
- `https://127.0.0.1:8443`
- `https://<tuo-ip-lan>:8443` (es: https://192.168.1.100:8443)

**Porta Esposta**: 443 (HTTPS only)

**Note Importanti**:
- Il certificato è self-signed quindi i browser mostreranno un warning di sicurezza
- Per production reale, sostituire con certificato valido (Let's Encrypt, certificato aziendale, etc.)
- Per sostituire il certificato, montare i file in `/etc/nginx/ssl/`

**Accesso all'applicazione**:
- Development: `https://{HOST}` (porta mappata da docker-compose)
- Il browser chiederà di accettare il certificato self-signed

---

## 📝 SCRIPTS

### install-laravel.sh (Root Level)
**Scopo**: Installazione automatica Laravel 12 + FilamentPHP v4
**Posizione**: Root del progetto (non in docker/)
**Funzioni**:
- Installa Laravel 12 in `src/` usando Composer via Docker
- Genera APP_KEY automaticamente
- Installa FilamentPHP v4 con panel
- Configura `.env` con parametri interattivi:
  - APP_NAME
  - APP_ENV (local/production)
  - Database credentials (host, name, user, password)
  - APP_URL (HTTPS)
- Crea configurazione MySQL in `database/config/my.cnf`
- Crea `.gitignore` con esclusioni corrette
- Imposta permessi su storage e bootstrap/cache
- Verifica esistenza progetto (non sovrascrive se esiste)

**Utilizzo**:
```bash
./install-laravel.sh
```

**Note**:
- Non richiede PHP installato localmente (usa container Docker)
- Configurazione interattiva con valori di default
- Adatto per quick start su nuovi progetti
- Include già tutte le best practices

---

### entrypoint.sh
**Scopo**: Inizializzazione container e avvio s6
**Funzioni**:
- Detect APP_ENV (production/local)
- Configurare servizi s6 basati su ENV
- Eseguire init-laravel.sh
- Avviare s6-overlay

### init-laravel.sh
**Scopo**: Setup Laravel application
**Funzioni**:
- Wait for database
- Run migrations (se AUTO_MIGRATE=true)
- Cache config/routes/views (production)
- Set permissions su storage/bootstrap
- Link storage (se necessario)

### healthcheck.sh
**Scopo**: Container health verification
**Check**:
- PHP-FPM ping
- Nginx status
- Database connection
- Return 0 (healthy) o 1 (unhealthy)

### wait-for-db.sh
**Scopo**: Attendere disponibilità database
**Implementazione**: Loop con timeout su database connection

---

## 🎯 MODALITÀ OPERATIVE

### 📋 Workflow di Utilizzo

**Opzione A: Setup Nuovo Progetto Laravel (con script automatico)**:
1. Esegui lo script di installazione:
   ```bash
   ./install-laravel.sh
   ```
2. Lo script installerà:
   - Laravel 12
   - FilamentPHP v4
   - Genererà APP_KEY
   - Configurerà database
   - Creerà file `.env` configurato
   - Creerà configurazione MySQL in `database/config/my.cnf`
3. Avvia i container:
   ```bash
   docker-compose -f docker-compose.yml -f docker-compose.dev.yml up --build
   ```

**Opzione B: Setup Progetto Esistente (clone da git)**:
1. Clona il tuo progetto Laravel dentro `src/`:
   ```bash
   git clone https://github.com/tuo-repo/progetto.git src/
   ```
2. Configura `src/.env` con `APP_ENV=local` per development o `APP_ENV=production`
3. Assicurati che `src/.env` abbia le configurazioni database corrette
4. Il container rileverà automaticamente l'environment da `src/.env`
5. Le directory Laravel (`storage/`, `bootstrap/cache/`) devono esistere nel progetto

**Detection Automatica Environment**:
- Il container legge `APP_ENV` dal file `src/.env`
- Se `APP_ENV=local` → Development Mode
- Se `APP_ENV=production` → Production Mode
- Default: Production Mode (se `.env` non esiste)

**IMPORTANTE**:
- NON creare manualmente le directory Laravel
- Il Dockerfile NON crea più le directory `storage/` e `bootstrap/cache/`
- Queste directory devono esistere nel tuo progetto Laravel in `src/`
- Se installi Laravel ex-novo, Laravel le creerà automaticamente

---

### Production Mode
**Attivazione**: `APP_ENV=production`
**Caratteristiche**:
- Asset precompilati (npm run build)
- OPcache con validate_timestamps=0
- Tutti servizi s6 attivi (nginx, php-fpm, scheduler, queue)
- Vite dev server: DISATTIVATO
- Utente: www-data (non-root)
- **Volumi**: Mount completo di `./src` (TEMPORANEO - vedi note finali)

**Start**:
```bash
docker-compose up -d
```

### Development Mode
**Attivazione**: `APP_ENV=local`
**Caratteristiche**:
- Vite dev server ATTIVO (HMR)
- OPcache con validate_timestamps=1
- Codice montato come volume
- Composer/NPM disponibili
- Scheduler: DISATTIVATO (usare `artisan schedule:run`)
- Queue: CONFIGURABILE

**Start**:
```bash
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up
```

---

## 🔐 SECURITY CONSIDERATIONS

### Production Hardening
1. **Non-root user**: Esecuzione come www-data
2. **Read-only filesystem**: Dove possibile
3. **Minimal image**: Multi-stage build pulito
4. **Security headers**: Via Nginx
5. **Secrets management**: Via Docker secrets o ENV criptate
6. **Network isolation**: Bridge network dedicata

### Development Safety
1. **Exposed ports**: Solo su localhost
2. **Volume mounts**: Limitati al necessario

---

## 📊 PERFORMANCE OPTIMIZATION

### PHP OPcache
- Preload Laravel framework
- Disabilitare timestamp validation in production
- Memory consumption: 256MB

### Nginx
- Gzip compression attivo
- Static file caching
- Sendfile abilitato

### Laravel Optimizations
```bash
php artisan config:cache
php artisan route:cache
php artisan view:cache
php artisan event:cache
```

---

## 🧪 TESTING STRATEGY

### Health Checks
- HTTP endpoint: `/health`
- PHP-FPM: `/fpm-ping`
- Database connectivity
- Redis connectivity

### Monitoring Points
- s6-overlay service status
- PHP-FPM pool status
- Nginx access/error logs
- Laravel logs (storage/logs)

---

## 📦 DEPLOYMENT WORKFLOW

### Build Production Image
```bash
docker build -f docker/Dockerfile --target production -t laravel-app:latest .
```

### Build Development Image
```bash
docker build -f docker/Dockerfile --target development -t laravel-app:dev .
```

### Push to Registry
```bash
docker tag laravel-app:latest registry.example.com/laravel-app:latest
docker push registry.example.com/laravel-app:latest
```

---

## 📄 .GITIGNORE ADDITIONS

### File e Directory da Escludere
```gitignore
# MySQL Data (NON versionare i dati del database)
database/data/*
!database/data/.gitkeep

# Docker volumes
docker/volumes/*

# Environment files
.env
.env.local
.env.*.local

# IDE
.vscode/
.idea/
*.swp
*.swo
```

---

## 🔄 NEXT STEPS

### Fase 1: Setup Base ✅
- [x] Definire prerequisiti
- [x] Progettare struttura
- [ ] Creare Dockerfile base

### Fase 2: s6-overlay Configuration
- [ ] Configurare servizio PHP-FPM
- [ ] Configurare servizio Nginx
- [ ] Configurare servizio Scheduler
- [ ] Configurare servizio Queue Worker
- [ ] Configurare servizio Vite (dev)

### Fase 3: Configurations
- [ ] PHP/PHP-FPM configs
- [ ] Nginx configs
- [ ] Vite config

### Fase 4: Scripts & Automation
- [ ] Entrypoint script
- [ ] Init Laravel script
- [ ] Healthcheck script
- [ ] Wait-for-db script

### Fase 5: Docker Compose
- [ ] Production compose file
- [ ] Development compose file
- [ ] Environment templates

### Fase 6: Testing & Documentation
- [ ] Test production build
- [ ] Test development mode
- [ ] Test Vite HMR
- [ ] Documentazione README

### Fase 7: Production Optimization (Futuro)
- [ ] Modificare Dockerfile per COPY codice in production stage
- [ ] Rimuovere mount ./src da docker-compose.yml production
- [ ] Implementare build pipeline con versioning immagini
- [ ] Setup image registry e deployment workflow
- [ ] Test deployment con immagini immutabili

---

## 💡 NOTE E CONSIDERAZIONI

### 🎯 Strategia Deploy - IMPORTANTE

#### Setup Attuale (Fase 1)
**Sia Production che Development montano `./src` come volume**
```yaml
volumes:
  - ./src:/var/www/html
```
**Nota**: `vendor` e `node_modules` sono gestiti dal `.gitignore` di Laravel (dentro `src/`)

**Vantaggi**:
- ✅ Facilità di sviluppo e debug
- ✅ Modifiche immediate senza rebuild
- ✅ Stesso comportamento dev/prod (inizialmente)
- ✅ Setup più semplice per iniziare

**Svantaggi**:
- ❌ Dipendenza da filesystem host in production
- ❌ Non è una vera immagine immutabile
- ❌ Deployment richiede sync di file

#### Obiettivo Futuro (Fase 2 - TODO)
**Production userà codice COPIATO nell'immagine Docker**
```dockerfile
# Nel Dockerfile, stage production:
COPY --from=composer /app/vendor /var/www/html/vendor
COPY --from=node /app/public/build /var/www/html/public/build
COPY ./src /var/www/html
```

**Vantaggi**:
- ✅ Immagine completamente standalone e immutabile
- ✅ Deployment semplice: pull & run
- ✅ Rollback facile (tag immagini)
- ✅ No dipendenze da filesystem host
- ✅ Best practice Docker production

**Timeline**: Questo cambio sarà implementato dopo il completamento della configurazione base e test iniziali.

---

### Redis - Configurazione Opzionale
**Redis è OPZIONALE** nel setup. Puoi usare alternative:

**Opzioni Cache Laravel**:
- `file` - Cache su filesystem (default, nessuna dipendenza)
- `database` - Cache su MySQL (già disponibile)
- `redis` - Cache su Redis (richiede abilitare il servizio Redis)

**Opzioni Queue Laravel**:
- `sync` - Esecuzione sincrona (dev, nessuna dipendenza)
- `database` - Queue su MySQL (già disponibile)
- `redis` - Queue su Redis (richiede abilitare il servizio Redis)

**Opzioni Session Laravel**:
- `file` - Session su filesystem (default)
- `database` - Session su MySQL
- `redis` - Session su Redis (richiede abilitare il servizio Redis)

**Per abilitare Redis**:
1. Decommenta il servizio `redis` in `docker-compose.yml`
2. Decommenta `- redis` in `depends_on` del servizio `app`
3. Configura Laravel per usare Redis (`.env`: `CACHE_DRIVER=redis`, `QUEUE_CONNECTION=redis`, ecc.)
4. Assicurati che l'estensione PHP `redis` sia installata nel Dockerfile

---

### MySQL Data Management
**IMPORTANTE**: I dati MySQL sono persistiti localmente nella directory `database/data/`
- **Backup**: Eseguire backup regolari di `database/data/`
- **Permissions**: La directory deve essere scrivibile dal container MySQL (UID/GID 999)
- **Gitignore**: Aggiungere `database/data/*` al `.gitignore`
- **Configurazione**: File `database/config/my.cnf` è versionato e condiviso
- **Prima esecuzione**: La directory `database/data/` verrà inizializzata automaticamente da MySQL
- **Reset database**: Eliminare `database/data/` per ripartire da zero (ATTENZIONE: dati persi!)

### FilamentPHP Specific
- Vite è **RICHIESTO** per FilamentPHP v3+
- In production: assets buildati staticamente
- In development: Vite dev server per HMR
- Configurare `ASSET_URL` se serve CDN

### Laravel Octane (Opzionale Futuro)
- Possibile integrazione con RoadRunner o Swoole
- Richiederebbe modifica architettura (sostituire PHP-FPM)
- Da considerare per performance estreme

### Horizontal Scaling
- Container app può essere scalato orizzontalmente
- Scheduler: solo 1 istanza (usare leader election o job lock)
- Queue: multiple istanze OK
- Session storage: usare Redis/database (non file)

---

## 📚 REFERENCES

- [s6-overlay Documentation](https://github.com/just-containers/s6-overlay)
- [Laravel Deployment](https://laravel.com/docs/deployment)
- [FilamentPHP Installation](https://filamentphp.com/docs/installation)
- [Vite with Laravel](https://laravel.com/docs/vite)
- [Docker Multi-stage Builds](https://docs.docker.com/build/building/multi-stage/)

---

**Versione Piano**: 1.0
**Ultimo Aggiornamento**: 2026-01-08
**Status**: 🚧 In Development
