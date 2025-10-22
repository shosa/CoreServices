# CoreServices

Servizi infrastrutturali condivisi per tutta la suite Core* (CoreMachine, CoreDocument, ecc.).

## Architettura

CoreServices fornisce un'infrastruttura centralizzata e condivisa per tutte le applicazioni della suite:

```
CoreServices/
├── docker-compose.yml              # Configurazione servizi
├── nginx-proxy-manager/            # Dati NPM e certificati SSL
├── scripts/
│   ├── setup-npm-database.bat      # Setup database NPM (Windows)
│   ├── setup-npm-database.sh       # Setup database NPM (Linux/Mac)
│   ├── configure-npm-proxies.bat   # Configura proxy hosts (Windows)
│   └── configure-npm-proxies.sh    # Configura proxy hosts (Linux/Mac)
├── start.bat                       # Avvio rapido
├── stop.bat                        # Stop rapido
└── logs.bat                        # Visualizza logs
```

## Servizi Inclusi

| Servizio | Descrizione | URL/Porta |
|----------|-------------|-----------|
| **MySQL** | Database relazionale condiviso | `localhost:3306` |
| **PHPMyAdmin** | Interfaccia web per MySQL | http://localhost:8080 |
| **MinIO** | Object Storage (S3-compatible) | API: `localhost:9000`<br>Console: http://localhost:9001 |
| **Meilisearch** | Full-text search engine | http://localhost:7700 |
| **Nginx Proxy Manager** | Reverse proxy con GUI | Admin: http://localhost:8181<br>HTTP: porta 80, 81<br>HTTPS: porta 443 |

## Avvio Rapido

### Avvia tutti i servizi
```bash
start.bat
```

### Ferma tutti i servizi
```bash
stop.bat
```

### Visualizza i log
```bash
logs.bat

# Oppure logs di un servizio specifico:
docker logs core-mysql -f
docker logs core-nginx-proxy-manager -f
```

## Prima Configurazione

### 1. Avvia CoreServices

```bash
start.bat
```

Attendere che tutti i servizi siano attivi (circa 30 secondi).

### 2. Setup Nginx Proxy Manager

#### a. Crea il database NPM

**Windows:**
```bash
scripts\setup-npm-database.bat
```

**Linux/Mac:**
```bash
chmod +x scripts/setup-npm-database.sh
./scripts/setup-npm-database.sh
```

Oppure manualmente:
```bash
docker exec core-mysql mysql -uroot -prootpassword -e "
CREATE DATABASE IF NOT EXISTS corenpm;
CREATE USER IF NOT EXISTS 'corenpm'@'%' IDENTIFIED BY 'corenpm';
GRANT ALL PRIVILEGES ON corenpm.* TO 'corenpm'@'%';
FLUSH PRIVILEGES;
"
```

#### b. Riavvia Nginx Proxy Manager

```bash
docker restart core-nginx-proxy-manager
```

Attendere circa 1 minuto per la prima inizializzazione (NPM crea le tabelle nel database).

#### c. Accedi alla GUI

Vai su: **http://localhost:8181**

**Credenziali di default**:
- Email: `admin@example.com`
- Password: `changeme`

**IMPORTANTE**: Cambia subito la password al primo login!

### 3. Configura i Proxy Hosts

Hai due opzioni per configurare i proxy hosts:

#### Opzione A: Script Automatico (CONSIGLIATO)

**Windows:**
```bash
scripts\configure-npm-proxies.bat
```

**Linux/Mac:**
```bash
chmod +x scripts/configure-npm-proxies.sh
./scripts/configure-npm-proxies.sh
```

Lo script ti chiederà email e password admin di NPM, poi configurerà automaticamente:
- CoreMachine su porta 80
- CoreDocument su porta 81

#### Opzione B: Configurazione Manuale

Dopo il login su NPM, configura manualmente i proxy per le applicazioni Core*.

##### CoreMachine (porta 80)

1. Click su **"Hosts" → "Proxy Hosts" → "Add Proxy Host"**

2. **Tab "Details"**:
   - Domain Names: `localhost` (o il tuo dominio)
   - Scheme: `http`
   - Forward Hostname / IP: `coremachine-frontend`
   - Forward Port: `3000`
   - ✅ Cache Assets
   - ✅ Block Common Exploits
   - ✅ Websockets Support

3. **Tab "Custom locations"** → Add location:
   - Location: `/api`
   - Scheme: `http`
   - Forward Hostname / IP: `coremachine-backend`
   - Forward Port: `3001`
   - ✅ Websockets Support

4. **Tab "Advanced"** (opzionale):
   ```nginx
   client_max_body_size 100M;
   ```

5. Click **"Save"**

#### CoreDocument (porta 81)

1. Click su **"Add Proxy Host"**

2. **Tab "Details"**:
   - Domain Names: `localhost:81` (o il tuo dominio)
   - Scheme: `http`
   - Forward Hostname / IP: `coredocument-frontend`
   - Forward Port: `3000`
   - ✅ Cache Assets
   - ✅ Block Common Exploits
   - ✅ Websockets Support

3. **Tab "Custom locations"** → Add location:
   - Location: `/api`
   - Scheme: `http`
   - Forward Hostname / IP: `coredocument-backend`
   - Forward Port: `3003`
   - ✅ Websockets Support

4. **Tab "Advanced"**:
   ```nginx
   client_max_body_size 100M;
   ```

5. Click **"Save"**

### 4. Test

- **CoreMachine**: http://localhost
- **CoreDocument**: http://localhost:81
- **NPM Admin**: http://localhost:8181

## Comandi Docker Manuali

```bash
# Start
docker-compose -p coreservices up -d

# Stop
docker-compose -p coreservices down

# Logs di tutti i servizi
docker-compose -p coreservices logs -f

# Logs di un servizio specifico
docker-compose -p coreservices logs -f [service-name]

# Status
docker-compose -p coreservices ps

# Restart singolo servizio
docker restart core-mysql
docker restart core-nginx-proxy-manager
```

## Network Condivisa

Tutti i servizi CoreServices e le applicazioni Core* (CoreMachine, CoreDocument, ecc.) condividono la network Docker **`core-network`**.

Le applicazioni possono comunicare tra loro e con i servizi usando i nomi dei container:
- `core-mysql`
- `core-minio`
- `core-meilisearch`
- `coremachine-backend`
- `coredocument-backend`
- ecc.

## Volumi Persistenti

I dati sono salvati in volumi Docker persistenti:

| Volume | Contenuto |
|--------|-----------|
| `core-mysql-data` | Database MySQL (coremachine, coredocument, corenpm) |
| `core-minio-data` | File object storage |
| `core-meilisearch-data` | Indici di ricerca |
| `nginx-proxy-manager/data` | Configurazione NPM |
| `nginx-proxy-manager/letsencrypt` | Certificati SSL |

## Credenziali di Default

### MySQL
- Host: `localhost:3306` (o `core-mysql` da Docker)
- Root user: `root`
- Root password: `rootpassword`

Database specifici per applicazione:
- `coremachine` - user: `coremachine`, password: `password`
- `coredocument` - user: `coredocument`, password: `password`
- `corenpm` - user: `corenpm`, password: `corenpm`

### PHPMyAdmin
- URL: http://localhost:8080
- User: `root`
- Password: `rootpassword`

### MinIO
- API: `localhost:9000`
- Console: http://localhost:9001
- User: `minioadmin`
- Password: `minioadmin123`

### Meilisearch
- Host: http://localhost:7700
- Master Key: `masterKeyChangeThis`

### Nginx Proxy Manager
- GUI: http://localhost:8181
- Email: `admin@example.com`
- Password: `changeme` (cambiare al primo login!)

## Nginx Proxy Manager - Funzionalità GUI

### Dashboard
- Stato proxy hosts
- Certificati SSL
- Statistiche accessi in tempo reale

### Proxy Hosts
- Aggiungi/modifica/elimina hosts con pochi click
- Gestione SSL per dominio (Let's Encrypt automatico)
- Custom locations per /api routes
- Access lists (protezione IP/password)
- Configurazione nginx avanzata per host

### SSL Certificates
- Genera certificati Let's Encrypt automaticamente
- Upload certificati custom
- Rinnovo automatico dei certificati

### Users
- Gestione utenti admin multipli
- Permessi granulari per host

### Settings
- Default site
- Configurazione nginx globale
- Log retention

## Vantaggi di Nginx Proxy Manager

| Feature | Nginx Manuale | Nginx Proxy Manager |
|---------|---------------|---------------------|
| Configurazione | File nginx.conf | GUI web intuitiva |
| Reload | Riavvio container | Click "Save" (instant) |
| SSL | Configurazione manuale | Automatico con Let's Encrypt |
| Logs | `docker logs` | GUI real-time con filtri |
| Multi-user | ❌ | ✅ Multiple admin |
| Access lists | ❌ | ✅ IP/password protection |
| Test configurazione | Rebuild container | Test immediato |

## Troubleshooting

### NPM non si avvia

```bash
# Verifica logs
docker logs core-nginx-proxy-manager -f

# Verifica database
docker exec core-mysql mysql -uroot -prootpassword -e "SHOW DATABASES LIKE 'corenpm';"

# Se database mancante, ricrea (Windows)
scripts\setup-npm-database.bat

# Oppure Linux/Mac
./scripts/setup-npm-database.sh

docker restart core-nginx-proxy-manager
```

### Porta 8181 non raggiungibile

```bash
# Verifica container attivo
docker ps --filter "name=nginx-proxy-manager"

# Verifica conflitti di porta
netstat -ano | findstr :8181

# Restart NPM
docker restart core-nginx-proxy-manager
```

### Errore connessione database NPM

```bash
# Ricrea database
docker exec core-mysql mysql -uroot -prootpassword -e "DROP DATABASE corenpm;"

# Windows
scripts\setup-npm-database.bat

# Linux/Mac
./scripts/setup-npm-database.sh

# Restart NPM
docker restart core-nginx-proxy-manager
```

### MySQL non si avvia

```bash
# Verifica logs
docker logs core-mysql -f

# Verifica healthcheck
docker inspect core-mysql | grep -A 10 Health

# Se corrupted, rimuovi volumi (ATTENZIONE: perde tutti i dati!)
docker-compose -p coreservices down -v
docker volume rm core-mysql-data
start.bat
```

### CoreMachine/CoreDocument non raggiungibili

1. Verifica che i container siano avviati:
   ```bash
   docker ps --filter "name=coremachine"
   docker ps --filter "name=coredocument"
   ```

2. Verifica che siano sulla `core-network`:
   ```bash
   docker network inspect core-network
   ```

3. Controlla i proxy hosts nella GUI NPM (http://localhost:8181)

4. Verifica che i forward hostname siano corretti:
   - `coremachine-frontend` (porta 3000)
   - `coremachine-backend` (porta 3001)
   - `coredocument-frontend` (porta 3000)
   - `coredocument-backend` (porta 3003)

5. Controlla logs NPM per errori:
   ```bash
   docker logs core-nginx-proxy-manager -f
   ```

### MinIO file non accessibili

```bash
# Verifica MinIO attivo
docker logs core-minio -f

# Test API
curl http://localhost:9000/minio/health/live

# Verifica bucket esistenti
docker exec core-minio mc ls local/
```

### Meilisearch non indicizza

```bash
# Verifica stato
curl http://localhost:7700/health

# Verifica API key
curl -H "Authorization: Bearer masterKeyChangeThis" http://localhost:7700/indexes

# Restart
docker restart core-meilisearch
```

## Backup e Restore

### Backup MySQL

```bash
# Backup database singolo
docker exec core-mysql mysqldump -uroot -prootpassword coremachine > backup-coremachine.sql
docker exec core-mysql mysqldump -uroot -prootpassword coredocument > backup-coredocument.sql
docker exec core-mysql mysqldump -uroot -prootpassword corenpm > backup-corenpm.sql

# Backup completo
docker exec core-mysql mysqldump -uroot -prootpassword --all-databases > backup-all.sql

# Restore
docker exec -i core-mysql mysql -uroot -prootpassword coremachine < backup-coremachine.sql
```

### Backup MinIO

```bash
# I file sono nel volume core-minio-data
# Per backup completo, copia la cartella:
docker run --rm -v core-minio-data:/data -v $(pwd):/backup alpine tar czf /backup/minio-backup.tar.gz /data
```

### Backup Configurazione NPM

```bash
# Backup database NPM
docker exec core-mysql mysqldump -uroot -prootpassword corenpm > backup-npm.sql

# Backup certificati SSL
# I certificati sono già in CoreServices/nginx-proxy-manager/letsencrypt/

# Restore database NPM
docker exec -i core-mysql mysql -uroot -prootpassword corenpm < backup-npm.sql
```

## Migrazione da vecchio nginx

Se stai migrando da una configurazione nginx manuale:

### Backup vecchia configurazione

```bash
# Fai backup del vecchio nginx.conf
copy nginx\nginx.conf nginx\nginx.conf.backup
```

La vecchia configurazione è comunque conservata in `nginx/nginx.conf` per riferimento.

### Rollback a vecchio nginx

Se necessario tornare al vecchio nginx:

1. Modifica [docker-compose.yml](docker-compose.yml) rimettendo il servizio `nginx` originale
2. Rimuovi il servizio `nginx-proxy-manager` dal docker-compose
3. Restart: `stop.bat && start.bat`

## Porte Utilizzate

| Porta | Servizio | Descrizione |
|-------|----------|-------------|
| 80 | Nginx Proxy Manager | CoreMachine (configurabile in GUI) |
| 81 | Nginx Proxy Manager | CoreDocument (configurabile in GUI) |
| 443 | Nginx Proxy Manager | HTTPS (configurabile in GUI) |
| 3306 | MySQL | Database server |
| 7700 | Meilisearch | Search API |
| 8080 | PHPMyAdmin | Interfaccia web MySQL |
| 8181 | Nginx Proxy Manager | Admin GUI |
| 9000 | MinIO | S3 API |
| 9001 | MinIO | Web Console |

## Aggiungere una nuova applicazione Core*

Per connettere una nuova applicazione (es. CoreInventory) ai servizi condivisi:

1. Nel `docker-compose.yml` dell'applicazione, configura la network esterna:
   ```yaml
   networks:
     core-network:
       external: true
       name: core-network
   ```

2. Usa i container names per connetterti ai servizi:
   - Database: `core-mysql:3306`
   - MinIO: `core-minio:9000`
   - Meilisearch: `core-meilisearch:7700`

3. Crea database dedicato:
   ```bash
   docker exec core-mysql mysql -uroot -prootpassword -e "
   CREATE DATABASE IF NOT EXISTS coreinventory;
   CREATE USER IF NOT EXISTS 'coreinventory'@'%' IDENTIFIED BY 'password';
   GRANT ALL PRIVILEGES ON coreinventory.* TO 'coreinventory'@'%';
   FLUSH PRIVILEGES;
   "
   ```

4. Configura proxy host in NPM per esporre l'applicazione su una porta (es. 82)

## Link Utili

- **Nginx Proxy Manager GUI**: http://localhost:8181
- **CoreMachine**: http://localhost
- **CoreDocument**: http://localhost:81
- **PHPMyAdmin**: http://localhost:8080
- **MinIO Console**: http://localhost:9001
- **NPM Docs ufficiali**: https://nginxproxymanager.com/guide/

## Note Tecniche

- NPM usa il database `corenpm` su MySQL condiviso
- I certificati SSL sono salvati in [nginx-proxy-manager/letsencrypt/](nginx-proxy-manager/letsencrypt/)
- Le configurazioni NPM sono salvate nel database (non in file nginx.conf)
- Il vecchio `nginx.conf` è conservato per riferimento in [nginx/nginx.conf](nginx/nginx.conf)
- Tutti i container usano `restart: unless-stopped` per auto-recovery
- MySQL ha healthcheck per garantire che sia pronto prima di avviare dipendenze
- La network `core-network` usa driver `bridge` per performance ottimali
