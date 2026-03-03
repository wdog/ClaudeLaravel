# 📋 Panoramica del Progetto

## 🎯 Obiettivo

Creare un ambiente Docker **production-ready** e **developer-friendly** per applicazioni Laravel 12 con:
- ✅ **FilamentPHP v5** - Admin panel moderno
- ✅ **Vite HMR** - Hot Module Replacement in development
- ✅ **s6-overlay** - Process supervision robusto
- ✅ **Alpine Linux** - Immagini leggere e sicure
- ✅ **Multi-stage build** - Ottimizzazione dimensioni immagine
- ✅ **Dual-mode** - Production e Development nella stessa configurazione

---

## 🏗️ Architettura Sistema

```
┌─────────────────────────────────────────────────────────────┐
│                    Docker Container (app)                    │
│  ┌───────────────────────────────────────────────────────┐  │
│  │                    s6-overlay v3                       │  │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐            │  │
│  │  │ PHP-FPM  │  │  Nginx   │  │Scheduler │ (prod)     │  │
│  │  │  :9000   │←─│   :80    │  │  (cron)  │            │  │
│  │  └──────────┘  │   :443   │  └──────────┘            │  │
│  │                └──────────┘                           │  │
│  │  ┌──────────┐  ┌──────────┐                          │  │
│  │  │  Queue   │  │   Vite   │ (dev only)               │  │
│  │  │ Worker   │  │  :5173   │                          │  │
│  │  └──────────┘  └──────────┘                          │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                          ↓
              ┌─────────────────────┐
              │   MySQL Container   │
              │     mysql:8.0       │
              │       :3306         │
              └─────────────────────┘
                          ↓
              ┌─────────────────────┐
              │  Redis Container    │ (opzionale)
              │   redis:7-alpine    │
              │       :6379         │
              └─────────────────────┘
```

---

## 🔑 Caratteristiche Principali

### 1. **Multi-Environment Support**
- **Production Mode**: Asset compilati, OPcache ottimizzato, tutti i servizi attivi
- **Development Mode**: Vite HMR, live reload, debug tools

### 2. **Process Management con s6-overlay**
- Supervisione robusta di più processi in un container
- Dependency management tra servizi
- Graceful shutdown e restart
- Health monitoring integrato

### 3. **Performance Optimization**
- PHP OPcache con preload Laravel
- Nginx con gzip e static file caching
- MySQL tuned per container
- Alpine Linux per immagini leggere (~200MB vs ~1GB)

### 4. **Developer Experience**
- Hot Module Replacement con Vite
- Volume mount per modifiche in tempo reale
- Script di setup automatico (`install-laravel.sh`)
- Stesso ambiente dev/prod (elimina "works on my machine")

### 5. **Production Ready**
- Multi-stage build ottimizzato
- **Automatic UID/GID mapping** - www-data matches host user for seamless permissions
- Security headers
- SSL/HTTPS con certificati self-signed
- Health checks integrati
- Laravel scheduler e queue workers
- s6-overlay v3 with proper service dependencies

---

## 🛠️ Stack Tecnologico

| Componente | Tecnologia | Versione | Scopo |
|------------|------------|----------|-------|
| **Framework** | Laravel | 12.x | Backend PHP framework |
| **Admin Panel** | FilamentPHP | 5.x | Admin interface |
| **Frontend Build** | Vite | 5.x | Asset bundling e HMR |
| **Web Server** | Nginx | Alpine latest | Reverse proxy e static files |
| **PHP Runtime** | PHP-FPM | 8.4 Alpine | FastCGI Process Manager |
| **Database** | MySQL | 8.0 | Relational database |
| **Cache/Queue** | Redis | 7 Alpine | Cache, sessions, queues (opzionale) |
| **Process Manager** | s6-overlay | v3.x | Multi-process supervision |
| **Container** | Docker | 24.0+ | Containerization |
| **Orchestration** | Docker Compose | 2.20+ | Multi-container setup |

---

## 🎨 Vantaggi di Questo Setup

### vs Setup Tradizionale (LAMP/LEMP)
✅ **Portabilità**: Stesso ambiente ovunque (dev, staging, prod)
✅ **Isolamento**: Nessun conflitto con altri progetti
✅ **Riproducibilità**: Setup identico per tutto il team
✅ **Versionabilità**: Infrastruttura as code

### vs Docker "Semplice" (senza s6)
✅ **Multi-Process**: Più servizi in un container (best practice per Laravel)
✅ **Dependency Management**: Nginx parte solo dopo PHP-FPM
✅ **Graceful Shutdown**: Tutti i processi terminano correttamente
✅ **Health Monitoring**: Supervisione integrata

### vs Kubernetes/Orchestratori Complessi
✅ **Semplicità**: Setup con Docker Compose
✅ **Costi**: Nessun overhead di orchestrazione
✅ **Learning Curve**: Più accessibile per team piccoli
✅ **Scalabilità**: Sufficiente per la maggior parte dei progetti

---

## 📦 Cosa Include

### Pronto all'Uso
- ✅ Laravel 12 pre-configurato
- ✅ FilamentPHP v4 installato
- ✅ Database MySQL con configurazione ottimizzata
- ✅ SSL self-signed per HTTPS
- ✅ Script di installazione automatica
- ✅ Vite configurato per HMR
- ✅ s6-overlay con 5 servizi pre-configurati
- ✅ Health checks
- ✅ Logging strutturato

### Opzionale
- 🔲 Redis per cache/queue/session
- 🔲 Certificati SSL custom
- 🔲 Multi-stage deploy pipeline
- 🔲 Laravel Octane integration

---

## 🚀 Casi d'Uso Ideali

Questo setup è perfetto per:

✅ **Startup e PMI** - Quick start con best practices incluse
✅ **Agenzie Web** - Template riutilizzabile per progetti Laravel
✅ **Team di Sviluppo** - Ambiente consistente per tutti
✅ **Progetti SaaS** - Base solida per scaling futuro
✅ **Prototipazione Rapida** - Da zero a production in minuti
✅ **Learning** - Impara Docker e Laravel insieme

---

## 🎯 Filosofia del Progetto

### Principi Guida

1. **Semplicità prima di tutto**
   - Configurazione sensata by default
   - Override facili dove necessario
   - Documentazione completa e chiara

2. **Production-ready ma developer-friendly**
   - Stesso setup per dev e prod
   - Hot reload in development
   - Performance in production

3. **Alpine everywhere**
   - Immagini leggere
   - Attack surface minimale
   - Boot time veloce

4. **Best practices by default**
   - Non-root user
   - Health checks
   - Security headers
   - Proper logging

5. **Estensibilità**
   - Facile aggiungere servizi s6
   - Configurazioni override friendly
   - Modular architecture

---

## 📊 Confronto Dimensioni

```
Traditional Setup (Debian-based):
┌─────────────────────────────────┐
│ PHP-FPM Debian:    ~400 MB      │
│ Nginx:             ~150 MB      │
│ Node.js:           ~300 MB      │
│ Dependencies:      ~200 MB      │
│ TOTALE:           ~1050 MB      │
└─────────────────────────────────┘

Questo Setup (Alpine-based):
┌─────────────────────────────────┐
│ PHP-FPM Alpine:     ~50 MB      │
│ Nginx Alpine:       ~25 MB      │
│ Node.js Alpine:     ~50 MB      │
│ s6-overlay:         ~10 MB      │
│ Dependencies:       ~65 MB      │
│ TOTALE:            ~200 MB      │
└─────────────────────────────────┘

Risparmio: ~80% di spazio! 🎉
```

---

## 🔄 Flusso di Lavoro Tipico

### Development
```bash
# 1. Setup iniziale (una volta - interattivo)
./install-laravel.sh
# - Chiede HOST (IP o domain) - auto-rileva IP LAN
# - Configura automaticamente APP_URL=https://${HOST}
# - Configura VITE_HMR_HOST=${HOST}
# - Genera vite.config.js con HTTPS
# - Imposta permessi con sudo chmod 777

# 2. Avvia ambiente development (detached by default)
./manager.sh --build
# Auto-rileva mode da src/.env

# 3. Esegui migrazioni (MANUALMENTE - richiesto!)
docker exec -it laravel-app php artisan migrate --force

# 4. Sviluppa con HMR su HTTPS
# - Accedi a https://{HOST}
# - Accedi a https://{HOST}:5173 (Vite HMR)
# - Accetta i certificati self-signed
# - Modifica file in src/resources/
# - Vite ricarica automaticamente il browser

# 5. Test da dispositivi LAN
# - Usa IP LAN come HOST (es: 192.168.88.40)
# - Accedi da phone/tablet sulla stessa rete

# 6. View logs (in detached mode)
docker-compose logs -f
# Oppure usa --foreground
./manager.sh --foreground
```

### Production
```bash
# 1. Build immagine production
./manager.sh --build
# Auto-rileva mode da APP_ENV in src/.env

# 2. Esegui migrazioni
docker exec -it laravel-app php artisan migrate --force

# 3. Monitor
docker-compose logs -f app
```

---

## 🎓 Prerequisiti Conoscenze

Per utilizzare questo setup è utile conoscere:

**Essenziale**:
- ✅ Docker basics (immagini, container, volumi)
- ✅ Laravel fundamentals
- ✅ Linea di comando Linux/Bash

**Utile ma non necessario**:
- 🔲 Docker Compose
- 🔲 Nginx configuration
- 🔲 PHP-FPM tuning
- 🔲 s6-overlay (spiegato nella documentazione)

---

## 📈 Roadmap Progetto

### ✅ Fase 1 - Foundation (In Progress)
- Setup base struttura
- Dockerfile multi-stage
- Configurazioni base

### 🔄 Fase 2 - Services
- Configurazione completa s6-overlay
- Tutti i servizi funzionanti
- Health checks

### 📋 Fase 3 - Automation
- Script completi e testati
- Installazione one-click
- Documentation

### 🚀 Fase 4 - Production Optimization
- Immagini immutabili
- CI/CD pipeline
- Performance tuning finale

---

## 🤝 Chi Dovrebbe Usare Questo Setup

### ✅ Perfetto Per:
- Developer Laravel che vogliono modernizzare il workflow
- Team che cercano consistenza dev/prod
- Progetti che puntano a scalare
- Chi vuole imparare Docker con un caso reale

### ❌ Forse Non Adatto Per:
- Progetti Laravel legacy con requisiti PHP < 8.4
- Setup con requisiti infrastrutturali molto specifici
- Chi preferisce soluzioni managed (Laravel Forge, Vapor)
- Microservices complessi (meglio Kubernetes)

---

## 📚 Prossimi Passi

1. Leggi i **[Prerequisiti](02-prerequisites.md)** per verificare di avere tutto
2. Studia la **[Struttura del Progetto](03-structure.md)** per capire l'organizzazione
3. Segui il **[Workflow di Utilizzo](25-usage-workflow.md)** per il setup
4. Consulta la **[Checklist](35-implementation-checklist.md)** per lo stato attuale

---

**[⬅️ Indice](README.md)** | **[Prossimo: Prerequisiti ➡️](02-prerequisites.md)**
