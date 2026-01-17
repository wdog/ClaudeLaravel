# 📚 Docker Laravel Project - Documentazione

> Setup Production-Ready di Laravel 12 con FilamentPHP, s6-overlay e Vite HMR

---

## 📖 Indice Documentazione

### 🎯 Panoramica e Setup
1. **[Panoramica del Progetto](01-overview.md)**
   - Descrizione generale
   - Architettura del sistema
   - Tecnologie utilizzate
   - Vantaggi del setup

2. **[Prerequisiti e Requisiti](02-prerequisites.md)**
   - Software necessario
   - Estensioni PHP richieste
   - Dipendenze Alpine
   - Configurazione ambiente

3. **[Struttura del Progetto](03-structure.md)**
   - Organizzazione directory
   - File di configurazione
   - Script e utility
   - Volumi e persistenza dati

---

### 🐳 Docker Configuration

4. **[Dockerfile Multi-Stage](04-dockerfile.md)**
   - Architettura multi-stage
   - Stage base
   - Stage composer
   - Stage node/npm
   - Stage production
   - Stage development

5. **[Docker Compose](05-docker-compose.md)**
   - Configurazione production
   - Configurazione development
   - Servizi (app, mysql, redis)
   - Networks e volumes
   - Environment variables

6. **[Immagini Docker Base](06-docker-images.md)**
   - Alpine Linux
   - PHP 8.4 FPM
   - Nginx
   - MySQL 8.0
   - Redis (opzionale)
   - Node.js 20

---

### ⚙️ Servizi e Process Management

7. **[s6-overlay Architecture](07-s6-overlay.md)**
   - Cos'è s6-overlay
   - Vantaggi rispetto a supervisor
   - Struttura s6-rc.d
   - Service dependencies
   - Lifecycle management

8. **[Servizio PHP-FPM](08-service-php-fpm.md)**
   - Configurazione pool
   - Process manager
   - Health checks
   - Performance tuning

9. **[Servizio Nginx](09-service-nginx.md)**
   - Configurazione principale
   - Virtual host Laravel
   - Proxy PHP-FPM
   - Static files serving
   - Security headers

10. **[Servizio Scheduler](10-service-scheduler.md)**
    - Laravel cron scheduler
    - Configurazione s6
    - Production vs development

11. **[Servizio Queue Worker](11-service-queue.md)**
    - Laravel queue processing
    - Worker configuration
    - Scaling e performance
    - Error handling

12. **[Servizio Vite Dev Server](12-service-vite.md)**
    - Hot Module Replacement
    - Development only
    - Proxy configuration
    - HMR troubleshooting

---

### 🔧 Configurazioni Dettagliate

13. **[Configurazione PHP](13-config-php.md)**
    - php.ini production
    - php.ini development
    - OPcache settings
    - Memory e upload limits
    - Error handling

14. **[Configurazione Nginx](14-config-nginx.md)**
    - nginx.conf principale
    - Laravel virtual host
    - Vite proxy (dev)
    - Gzip e caching
    - Security headers

15. **[Configurazione MySQL](15-config-mysql.md)**
    - my.cnf custom
    - Performance tuning
    - Character set utf8mb4
    - Logging e monitoring

16. **[Configurazione Vite](16-config-vite.md)**
    - vite.config.js
    - Laravel plugin
    - HMR settings
    - Production build

---

### 🔐 SSL e Sicurezza

17. **[SSL/HTTPS Configuration](17-ssl-https.md)**
    - Certificato self-signed
    - Generazione automatica
    - Subject Alternative Names
    - Supporto IP LAN
    - Production certificates

18. **[Security Best Practices](18-security.md)**
    - Non-root user
    - Network isolation
    - Secrets management
    - File permissions
    - Security headers
    - Production hardening

---

### 📝 Scripts e Automation

19. **[Script: install-laravel.sh](19-script-install-laravel.md)**
    - Installazione Laravel 12
    - Setup FilamentPHP
    - Configurazione interattiva
    - Generazione APP_KEY
    - Setup database config

20. **[Script: entrypoint.sh](20-script-entrypoint.md)**
    - Container initialization
    - Environment detection
    - s6 service configuration
    - Startup sequence

21. **[Script: init-laravel.sh](21-script-init-laravel.md)**
    - Laravel setup
    - Database migrations
    - Cache warming
    - Permissions setup
    - Storage linking

22. **[Script: healthcheck.sh](22-script-healthcheck.md)**
    - Health verification
    - PHP-FPM ping
    - Nginx status
    - Database connectivity

23. **[Script: wait-for-db.sh](23-script-wait-for-db.md)**
    - Database readiness check
    - Timeout handling
    - Retry logic

---

### 🚀 Workflow e Deployment

24. **[Modalità Operative](24-operating-modes.md)**
    - Production mode
    - Development mode
    - Environment detection
    - Service activation

25. **[Workflow di Utilizzo](25-usage-workflow.md)**
    - Setup nuovo progetto
    - Setup progetto esistente
    - Comandi comuni
    - Troubleshooting

26. **[Build e Deploy](26-build-deploy.md)**
    - Build production image
    - Build development image
    - Push to registry
    - Deployment workflow
    - Rollback strategy

27. **[Performance Optimization](27-performance.md)**
    - PHP OPcache
    - Nginx tuning
    - Laravel optimizations
    - Database indexing
    - Monitoring

---

### 🧪 Testing e Monitoring

28. **[Testing Strategy](28-testing.md)**
    - Health checks
    - Integration tests
    - Performance tests
    - Load testing

29. **[Monitoring e Logging](29-monitoring.md)**
    - s6 service status
    - PHP-FPM metrics
    - Nginx logs
    - Laravel logs
    - Database monitoring

---

### 💡 Note Avanzate

30. **[Redis Configuration (Opzionale)](30-redis.md)**
    - Quando usare Redis
    - Alternative (file, database)
    - Setup e configurazione
    - Cache/Queue/Session

31. **[MySQL Data Management](31-mysql-data.md)**
    - Persistenza dati
    - Backup strategy
    - Restore procedure
    - Permissions e ownership

32. **[Deploy Strategy](32-deploy-strategy.md)**
    - Fase 1: Volume mount (attuale)
    - Fase 2: Immutable images (futuro)
    - Vantaggi e svantaggi
    - Migration path

33. **[Scaling e High Availability](33-scaling.md)**
    - Horizontal scaling
    - Load balancing
    - Session management
    - Scheduler coordination
    - Queue workers scaling

34. **[Advanced Topics](34-advanced.md)**
    - Laravel Octane integration
    - Custom s6 services
    - Multi-environment setup
    - CI/CD integration

---

### 📋 Appendici

35. **[Checklist Implementazione](35-implementation-checklist.md)**
    - Fase 1: Setup Base
    - Fase 2: s6-overlay Configuration
    - Fase 3: Configurations
    - Fase 4: Scripts & Automation
    - Fase 5: Docker Compose
    - Fase 6: Testing & Documentation
    - Fase 7: Production Optimization

36. **[Troubleshooting Guide](36-troubleshooting.md)**
    - Problemi comuni
    - Soluzioni
    - Debug tips
    - FAQ

37. **[References e Links](37-references.md)**
    - Documentazione ufficiale
    - Guide esterne
    - Tools utili
    - Community resources

---

## 🚀 Quick Start

Per iniziare subito:

1. Leggi la **[Panoramica del Progetto](01-overview.md)**
2. Verifica i **[Prerequisiti](02-prerequisites.md)**
3. Segui il **[Workflow di Utilizzo](25-usage-workflow.md)**
4. Consulta la **[Checklist Implementazione](35-implementation-checklist.md)** per lo stato attuale

---

## 📊 Stato del Progetto

**Versione**: 1.1
**Ultimo Aggiornamento**: 2026-01-17
**Status**: ✅ Implementation Complete (Tested)

**Key Features Implemented**:
- ✅ Single HOST configuration (auto-detects LAN IP)
- ✅ HTTPS by default (APP_URL=https://${HOST})
- ✅ Vite HMR over HTTPS with LAN access
- ✅ Auto-generated Vite config (no stub files)
- ✅ **Automatic UID/GID mapping** - www-data matches host user (no more permission issues!)
- ✅ **s6-overlay v3 with proper oneshot init** - services start in correct order
- ✅ **s6-setuidgid** for all services (vite-dev, scheduler, queue-worker)
- ✅ docker-up.sh shows executed commands
- ✅ Test script for permission verification (`test/test-permissions.sh`)
- ✅ Manual migrations (not automatic)
- ✅ Complete documentation

Vedi la **[Checklist Implementazione](35-implementation-checklist.md)** per i dettagli completi sullo stato di avanzamento.

---

## 🤝 Contribuire

Questa documentazione è in continuo sviluppo. Per suggerimenti o correzioni, consulta il team di sviluppo.
