# ============================================================================
# Laravel Docker Image - Multi-Stage Build
# Base: PHP 8.4 FPM Alpine with s6-overlay
# ============================================================================

# ============================================================================
# Stage 1: Base Image - PHP 8.4 FPM Alpine
# ============================================================================
FROM php:8.4-fpm-alpine AS base

# Set working directory
WORKDIR /var/www/html

# Install system dependencies and PHP extensions
RUN apk add --no-cache \
    # System utilities
    bash \
    curl \
    git \
    nginx \
    supervisor \
    tzdata \
    openssl \
    # PHP extension dependencies
    libzip-dev \
    libpng-dev \
    libjpeg-turbo-dev \
    freetype-dev \
    icu-dev \
    oniguruma-dev \
    libxml2-dev \
    curl-dev \
    mysql-client \
    # Build dependencies for PECL (will be removed later)
    && apk add --no-cache --virtual .build-deps \
        autoconf \
        g++ \
        make \
    && docker-php-ext-configure gd \
        --with-freetype \
        --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
        pdo \
        pdo_mysql \
        mbstring \
        xml \
        bcmath \
        curl \
        gd \
        zip \
        intl \
        opcache \
    && pecl install apcu \
    && docker-php-ext-enable apcu \
    && apk del .build-deps \
    && rm -rf /tmp/pear

# Install s6-overlay for process supervision
ARG S6_OVERLAY_VERSION=3.1.6.2
RUN curl -fsSL "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz" | tar -C / -Jxpf - \
    && curl -fsSL "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-x86_64.tar.xz" | tar -C / -Jxpf -

# Note: www-data user/group already exist in php:8.4-fpm-alpine (uid/gid 82)

# Copy PHP configurations
COPY docker/php/php.ini /usr/local/etc/php/php.ini
COPY docker/php/php-fpm.conf /usr/local/etc/php-fpm.d/zz-custom.conf
COPY docker/php/opcache.ini /usr/local/etc/php/conf.d/opcache.ini

# Copy Nginx configuration
COPY docker/nginx/nginx.conf /etc/nginx/nginx.conf
COPY docker/nginx/laravel.conf /etc/nginx/http.d/default.conf

# Copy s6-overlay service definitions
COPY docker/s6-overlay/ /etc/s6-overlay/

# Copy scripts
COPY docker/scripts/ /docker/scripts/
RUN chmod +x /docker/scripts/*.sh \
    && chmod +x /etc/s6-overlay/s6-rc.d/*/run \
    && chmod +x /etc/s6-overlay/cont-init.d/*.sh

# Generate self-signed SSL certificate (10 years validity)
RUN /docker/scripts/generate-ssl-cert.sh

# Create necessary directories (NOT Laravel directories - those are created by Laravel)
RUN mkdir -p \
    /var/run/php \
    /etc/nginx/ssl \
    /var/lib/nginx/tmp/client_body \
    /var/lib/nginx/tmp/proxy \
    /var/lib/nginx/tmp/fastcgi \
    /var/lib/nginx/tmp/uwsgi \
    /var/lib/nginx/tmp/scgi \
    /var/lib/nginx/logs \
    && chown -R www-data:www-data \
        /var/run/php \
        /etc/nginx/ssl \
        /var/lib/nginx

# Expose HTTP and HTTPS ports
EXPOSE 80 443

# s6-overlay entrypoint
ENTRYPOINT ["/init"]

# ============================================================================
# Stage 2: Composer Dependencies
# ============================================================================
FROM composer:latest AS composer

WORKDIR /app

# Copy composer files
COPY src/composer.json src/composer.lock* ./

# Install dependencies (production only for now)
RUN composer install \
    --no-dev \
    --no-scripts \
    --no-autoloader \
    --prefer-dist \
    --optimize-autoloader

# Copy application code
COPY src/ ./

# Generate optimized autoloader
RUN composer dump-autoload --optimize --classmap-authoritative

# ============================================================================
# Stage 3: Node/NPM Build
# ============================================================================
FROM node:20-alpine AS node

WORKDIR /app

# Copy package files
COPY src/package*.json ./

# Install npm dependencies
RUN npm ci

# Copy application code
COPY src/ ./

# Build assets with Vite
RUN npm run build

# ============================================================================
# Stage 4: Production Image
# ============================================================================
FROM base AS production

# Copy vendor from composer stage
# COPY --from=composer --chown=www-data:www-data /app/vendor /var/www/html/vendor

# Copy built assets from node stage
# COPY --from=node --chown=www-data:www-data /app/public/build /var/www/html/public/build

# NOTE: Fase 1 - Il codice viene montato da ./src (non copiato)
# TODO: Fase 2 - Decommentare le righe sopra per copiare vendor e assets nell'immagine

# Set production PHP configurations
ENV APP_ENV=production \
    APP_DEBUG=false

# Switch to www-data user
USER www-data

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD ["/docker/scripts/healthcheck.sh"]

# ============================================================================
# Stage 5: Development Image
# ============================================================================
FROM production AS development

# Switch back to root for installations
USER root

# Install Node.js for Vite dev server
RUN apk add --no-cache nodejs npm

# Install composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Set development PHP configurations
ENV APP_ENV=local \
    APP_DEBUG=true \
    VITE_DEV_SERVER_ENABLED=true

# Switch back to www-data
USER www-data

# Expose Vite port
EXPOSE 5173
