# Prerequisiti e Requisiti

Questa guida elenca tutto il necessario per eseguire il progetto Docker Laravel.

---

## Software Richiesto

### Host Machine

| Software | Versione Minima | Note |
|----------|-----------------|------|
| Docker | 20.10+ | Engine con supporto BuildKit |
| Docker Compose | 2.0+ | Versione plugin (non standalone) |
| Git | 2.0+ | Per clonare il repository |
| Bash | 4.0+ | Per gli script di installazione |

### Verifica Installazione

```bash
# Docker
docker --version
# Docker version 24.0.0, build ...

# Docker Compose
docker compose version
# Docker Compose version v2.20.0

# Git
git --version
# git version 2.40.0

# Bash
bash --version
# GNU bash, version 5.2.15
```

---

## Porte Richieste

Il progetto utilizza le seguenti porte:

| Porta | Servizio | Modalità |
|-------|----------|----------|
| 443 | HTTPS (Nginx) | Entrambe |
| 80 | HTTP redirect | Entrambe |
| 5173 | Vite HMR | Solo Development |
| 3306 | MySQL | Solo Development (esposta) |

### Verifica Porte Disponibili

```bash
# Linux/macOS
sudo lsof -i :443
sudo lsof -i :5173
sudo lsof -i :3306

# Se occupate, fermare i servizi in conflitto o modificare docker-compose.yml
```

---

## Requisiti Sistema

### Risorse Minime

| Risorsa | Minimo | Raccomandato |
|---------|--------|--------------|
| CPU | 2 core | 4 core |
| RAM | 4 GB | 8 GB |
| Disco | 10 GB | 20 GB |

### Spazio Disco Dettaglio

- Immagine Docker: ~1.5 GB
- MySQL data: variabile (parte da ~200 MB)
- node_modules: ~300 MB
- vendor: ~100 MB
- Laravel storage/logs: variabile

---

## Estensioni PHP Incluse

L'immagine Docker include già tutte le estensioni PHP necessarie:

### Core Extensions

| Estensione | Uso |
|------------|-----|
| pdo_mysql | Connessione MySQL |
| opcache | Cache bytecode PHP |
| pcntl | Process control (queue worker) |
| zip | Gestione archivi |
| gd | Manipolazione immagini |
| intl | Internazionalizzazione |
| bcmath | Calcoli precisione arbitraria |
| exif | Metadati immagini |

### Additional Extensions

| Estensione | Uso |
|------------|-----|
| redis | Cache/Session con Redis (opzionale) |
| curl | HTTP client |
| mbstring | Stringhe multibyte |
| xml | Parsing XML |
| tokenizer | PHP tokenizer |
| ctype | Character type checking |
| fileinfo | File type detection |

---

## Pacchetti Alpine Inclusi

L'immagine Alpine include:

### Runtime

```
nginx           # Web server
nodejs          # Node.js runtime
npm             # Package manager
```

### Build Tools (solo in dev)

```
git             # Version control
```

### Utilities

```
shadow          # usermod/groupmod per UID mapping
curl            # HTTP client
```

---

## Configurazione Ambiente Host

### Linux

Nessuna configurazione aggiuntiva richiesta. Docker funziona nativamente.

```bash
# Aggiungi utente al gruppo docker (evita sudo)
sudo usermod -aG docker $USER
# Logout e login per applicare
```

### macOS

Docker Desktop richiesto. Le performance sono leggermente inferiori a Linux per i volume mount.

```bash
# Installa Docker Desktop
brew install --cask docker
```

### Windows (WSL2)

Richiede WSL2 con Docker Desktop.

```powershell
# Abilita WSL2
wsl --install

# Installa Docker Desktop con backend WSL2
# Clona il progetto DENTRO WSL2, non su /mnt/c
```

---

## Permessi File

Il progetto usa un sistema automatico di mapping UID/GID:

1. **init-usermod** mappa `www-data` al tuo UID host
2. Tutti i file creati nel container sono di proprietà del tuo utente
3. Nessun `chmod 777` necessario

### Verifica UID

```bash
# Il tuo UID (solitamente 1000)
id -u

# Dopo l'avvio del container, www-data avrà lo stesso UID
docker exec laravel-app id www-data
# uid=1000(www-data) gid=1000(www-data)
```

---

## Checklist Pre-Installazione

Prima di procedere con l'installazione, verifica:

- [ ] Docker installato e funzionante (`docker run hello-world`)
- [ ] Docker Compose v2 disponibile (`docker compose version`)
- [ ] Porte 443, 5173, 3306 libere
- [ ] Almeno 4 GB RAM disponibile
- [ ] Almeno 10 GB spazio disco
- [ ] Utente nel gruppo docker (Linux)

---

**[⬅️ Panoramica](01-overview.md)** | **[Struttura Progetto ➡️](03-structure.md)**
