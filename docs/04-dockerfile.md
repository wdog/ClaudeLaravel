# Dockerfile Multi-Stage

Questo documento descrive l'architettura multi-stage del Dockerfile.

---

## Overview

Il Dockerfile usa un approccio **multi-stage build** con 5 stage:

```
┌─────────────────┐
│  Stage 1: base  │  PHP 8.4 FPM Alpine + s6-overlay + Nginx
└────────┬────────┘
         │
┌────────┴────────┐     ┌──────────────────┐
│ Stage 4: prod   │ ◄── │ Stage 2: composer │ (vendor)
└────────┬────────┘     └──────────────────┘
         │              ┌──────────────────┐
         │          ◄── │ Stage 3: node    │ (assets)
         │              └──────────────────┘
┌────────┴────────┐
│ Stage 5: dev    │  + Composer CLI + Vite dev server
└─────────────────┘
```

---

## Stage 1: Base

**Immagine**: `php:8.4-fpm-alpine`

Questo stage costruisce la base comune per production e development.

### Pacchetti Sistema

```dockerfile
RUN apk add --no-cache \
    bash            # Shell per scripts
    shadow          # usermod/groupmod per UID mapping
    curl            # HTTP client
    git             # Version control
    nginx           # Web server
    supervisor      # (legacy, non usato)
    tzdata          # Timezone data
    openssl         # SSL utilities
    mysql-client    # MySQL CLI
```

### Estensioni PHP

```dockerfile
RUN docker-php-ext-install -j$(nproc) \
    pdo             # Database abstraction
    pdo_mysql       # MySQL driver
    mbstring        # Multibyte strings
    xml             # XML parsing
    bcmath          # Arbitrary precision math
    curl            # cURL
    gd              # Image processing
    zip             # ZIP archives
    intl            # Internationalization
    opcache         # Bytecode cache
```

### s6-overlay

```dockerfile
ARG S6_OVERLAY_VERSION=3.1.6.2
RUN curl -fsSL ".../s6-overlay-noarch.tar.xz" | tar -C / -Jxpf - \
    && curl -fsSL ".../s6-overlay-x86_64.tar.xz" | tar -C / -Jxpf -
```

s6-overlay v3 è il process supervisor che gestisce:
- Avvio ordinato dei servizi
- Restart automatico in caso di crash
- Signal handling corretto
- Init scripts (oneshot)

### Configurazioni Copiate

```dockerfile
# PHP
COPY docker/php/php.ini /usr/local/etc/php/php.ini
COPY docker/php/php-fpm.conf /usr/local/etc/php-fpm.d/zz-custom.conf
COPY docker/php/opcache.ini /usr/local/etc/php/conf.d/opcache.ini

# Nginx
COPY docker/nginx/nginx.conf /etc/nginx/nginx.conf
COPY docker/nginx/laravel.conf /etc/nginx/http.d/default.conf

# s6-overlay services
COPY docker/s6-overlay/ /etc/s6-overlay/

# Scripts
COPY docker/scripts/ /docker/scripts/
```

### SSL Certificate

```dockerfile
RUN /docker/scripts/generate-ssl-cert.sh
```

Genera un certificato self-signed con:
- Validità 10 anni
- SAN: localhost, *.localhost, IP LAN
- RSA 2048 bit

### Directory Create

```dockerfile
RUN mkdir -p \
    /var/run/php \              # PHP-FPM socket
    /etc/nginx/ssl \            # SSL certificates
    /var/lib/nginx/tmp/...      # Nginx temp directories
```

### Entrypoint

```dockerfile
ENTRYPOINT ["/init"]
```

`/init` è l'entrypoint di s6-overlay che:
1. Esegue gli oneshot services (init-usermod, init-assets)
2. Avvia i longrun services (php-fpm, nginx, etc.)
3. Gestisce i segnali di shutdown

---

## Stage 2: Composer

**Immagine**: `composer:latest`

Stage temporaneo per installare le dipendenze PHP.

```dockerfile
FROM composer:latest AS composer

WORKDIR /app
COPY src/composer.json src/composer.lock* ./

RUN composer install \
    --no-dev \
    --no-scripts \
    --no-autoloader \
    --prefer-dist \
    --optimize-autoloader

COPY src/ ./
RUN composer dump-autoload --optimize --classmap-authoritative
```

**Note**:
- `--no-dev` esclude le dipendenze di sviluppo
- `--optimize-autoloader` genera un autoloader ottimizzato per production

---

## Stage 3: Node

**Immagine**: `node:current-alpine`

Stage temporaneo per compilare gli asset frontend.

```dockerfile
FROM node:current-alpine AS node

WORKDIR /app
COPY src/package*.json ./
RUN npm ci
COPY src/ ./
RUN npm run build
```

Produce la directory `public/build/` con gli asset compilati.

---

## Stage 4: Production

**Base**: `base`

L'immagine production-ready.

```dockerfile
FROM base AS production

# Node.js per npm run build (volume mount)
RUN apk add --no-cache nodejs npm

# Environment
ENV APP_ENV=production \
    APP_DEBUG=false

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD ["/docker/scripts/healthcheck.sh"]
```

### Fase 1 vs Fase 2: Due Strategie di Deploy

Il Dockerfile supporta due modalità di deploy diverse:

#### Fase 1: Volume Mount (Attuale)

```
┌─────────────────────────────────────────────────────────┐
│  Host Machine                                           │
│  ./src/ ──────────────────┐                             │
│    ├── app/               │                             │
│    ├── vendor/            │  volume mount               │
│    ├── node_modules/      │  (-v ./src:/var/www/html)   │
│    └── ...                │                             │
└───────────────────────────┼─────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│  Container                                              │
│  /var/www/html/ ◄─────────┘                             │
│    (tutto il codice viene dall'host)                    │
└─────────────────────────────────────────────────────────┘
```

**Come funziona:**
- Il codice Laravel (`./src`) è montato come volume nel container
- `vendor/` e `node_modules/` sono sul filesystem host
- Gli asset vengono compilati all'avvio del container (`init-assets.sh`)
- Node.js deve essere nell'immagine per eseguire `npm run build`

**Vantaggi:**
- Sviluppo rapido: modifichi i file e vedi subito i cambiamenti
- Debug facile: accesso diretto ai file
- Nessun rebuild immagine per modifiche al codice

**Svantaggi:**
- L'immagine non è autocontenuta
- Serve il codice sorgente sul server di deploy
- Performance I/O leggermente inferiori (specialmente su macOS)

**Uso tipico:** Development, staging, piccoli deploy

---

#### Fase 2: Immagine Immutabile (Futuro)

```
┌─────────────────────────────────────────────────────────┐
│  Build Time (docker build)                              │
│                                                         │
│  Stage: composer ──► vendor/                            │
│  Stage: node     ──► public/build/                      │
│                         │                               │
│                         ▼                               │
│  Stage: production                                      │
│    COPY --from=composer vendor/ ──┐                     │
│    COPY --from=node public/build/ ├──► Immagine finale  │
│    COPY src/ ─────────────────────┘                     │
└─────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│  Container (runtime)                                    │
│  /var/www/html/                                         │
│    ├── app/           (copiato nell'immagine)           │
│    ├── vendor/        (copiato nell'immagine)           │
│    └── public/build/  (copiato nell'immagine)           │
│                                                         │
│  NESSUN volume mount necessario                         │
└─────────────────────────────────────────────────────────┘
```

**Come funziona:**
- Tutto il codice viene copiato DENTRO l'immagine Docker durante la build
- `vendor/` viene dallo stage composer
- `public/build/` viene dallo stage node
- L'immagine è completa e autonoma

**Per attivare**, decommentare nel Dockerfile:

```dockerfile
# Stage 4: Production
FROM base AS production

# Copia vendor compilato dallo stage composer
COPY --from=composer --chown=www-data:www-data /app/vendor /var/www/html/vendor

# Copia asset compilati dallo stage node
COPY --from=node --chown=www-data:www-data /app/public/build /var/www/html/public/build

# Copia il codice sorgente
COPY --chown=www-data:www-data src/ /var/www/html/
```

E rimuovere Node.js dall'immagine production (non serve più):

```dockerfile
# Rimuovere questa riga:
# RUN apk add --no-cache nodejs npm
```

**Vantaggi:**
- Immagine immutabile e versionata (tag: `v1.0.0`, `abc123`)
- Deploy consistente: stessa immagine ovunque
- Rollback istantaneo: basta usare il tag precedente
- Nessuna dipendenza dal codice sorgente in produzione
- Migliori performance (no volume mount overhead)

**Svantaggi:**
- Rebuild immagine per ogni modifica al codice
- Build più lenta
- Registry Docker necessario per distribuire le immagini

**Uso tipico:** Production, CI/CD, Kubernetes

---

#### Confronto

| Aspetto | Fase 1 (Volume) | Fase 2 (Immutabile) |
|---------|-----------------|---------------------|
| Codice | Montato dall'host | Copiato nell'immagine |
| Build | Veloce | Più lenta |
| Deploy | Serve sorgente | Solo immagine |
| Rollback | Git checkout | Docker tag |
| Performance | Buona | Ottima |
| Immutabilità | No | Sì |
| CI/CD | Opzionale | Consigliato |

---

#### Migration Path

Per passare da Fase 1 a Fase 2:

1. Decommenta le righe `COPY --from=...` nel Dockerfile
2. Aggiungi `COPY --chown=www-data:www-data src/ /var/www/html/`
3. Rimuovi `nodejs npm` dallo stage production
4. Rimuovi il volume mount `./src:/var/www/html` da docker-compose.yml
5. Setup CI/CD per build automatica
6. Push immagini a un registry (Docker Hub, GitHub CR, etc.)

### Perché NON c'è `USER www-data`

```dockerfile
# NOTE: Do NOT set USER www-data here!
# s6-overlay needs to start as root to run init scripts
```

s6-overlay deve partire come root per:
1. Eseguire `usermod` (mapping UID)
2. Modificare permessi
3. I singoli servizi poi droppano i privilegi con `s6-setuidgid www-data`

---

## Stage 5: Development

**Base**: `production`

Estende production con strumenti di sviluppo.

```dockerfile
FROM production AS development

USER root

# Node.js già presente da production
RUN apk add --no-cache nodejs npm

# Composer CLI
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Environment
ENV APP_ENV=local \
    APP_DEBUG=true \
    VITE_DEV_SERVER_ENABLED=true

EXPOSE 5173
```

---

## Build Commands

### Production

```bash
docker build \
    -f docker/Dockerfile \
    --target production \
    -t laravel-app:prod \
    .
```

### Development

```bash
docker build \
    -f docker/Dockerfile \
    --target development \
    -t laravel-app:dev \
    .
```

### Con docker-compose

```bash
# Il target viene scelto automaticamente da docker-up.sh
./docker-up.sh -bd
```

---

## Build Context

Il `.dockerignore` esclude:

```
src/node_modules/
src/vendor/
src/storage/
database/data/
.git/
*.log
```

Questo riduce la dimensione del build context e velocizza la build.

---

## Dimensioni Immagine

| Stage | Dimensione Circa |
|-------|------------------|
| base | ~400 MB |
| production | ~450 MB |
| development | ~500 MB |

Le dimensioni possono variare in base alle dipendenze installate.

---

**[⬅️ Struttura Progetto](03-structure.md)** | **[Docker Compose ➡️](05-docker-compose.md)**
