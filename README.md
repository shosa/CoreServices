# CoreServices

Servizi infrastrutturali condivisi per la suite Core*. Fornisce i servizi di base (DB, cache, object storage, search, reverse proxy) usati dalle applicazioni Core (CoreMachine, CoreDocument, CoreGREJS, ecc.).

## Contenuto della cartella

- `docker-compose.yml` — definizione dei servizi principali
- `nginx/` — configurazioni e certificati usati dal proxy Nginx
- `.env.production` — variabili d'ambiente di esempio

## Obiettivo

Fornire un ambiente locale/di sviluppo centralizzato con servizi condivisi per velocizzare lo sviluppo e l'integrazione fra le app della suite.

## Prerequisiti

- Docker e Docker Compose installati sulla macchina.
- Porte libere: 80, 81..86, 443, 3306, 6379, 7700, 9000, 9001, 8080.

## Avvio rapido

Da questa cartella esegui:

```bash
docker-compose up -d
```

Per fermare e rimuovere i servizi:

```bash
docker-compose down
```

Visualizzare i log:

```bash
docker-compose logs -f
```

O log di un singolo servizio:

```bash
docker logs <container-name> -f
```

## Servizi e porte principali

- MySQL: `3306` (container: `core-mysql`)
- PHPMyAdmin: `8080` (container: `core-phpmyadmin`)
- MinIO (S3): API `9000`, Console `9001` (container: `core-minio`)
- Meilisearch: `7700` (container: `core-meilisearch`)
- Redis: `6379` (container: `core-redis`)
- Nginx (reverse proxy per le app Core*): HTTP `80`, HTTPS `443`, porte specifiche aggiuntive 81..86 mappate come proxy locali (container: `core-nginx`)

I nomi dei container sono esposti nella network Docker `core-network` e le applicazioni possono risolverli internamente (es. `core-mysql`, `core-minio`).

## Variabili d'ambiente utili (override tramite .env)

- `MYSQL_ROOT_PASSWORD` (default: `rootpassword`)
- `MINIO_ROOT_USER` / `MINIO_ROOT_PASSWORD` (default: `minioadmin` / `minioadmin123`)
- `MEILI_MASTER_KEY` (default: `masterKeyChangeThis`)
- `REDIS_PASSWORD` (default: `coresuite_redis`)

Inserire valori sicuri in produzione o nei file `.env` locali.

## Volumi persistenti

I dati critici sono montati su volumi Docker per persistenza:

- `core-mysql-data` — dati MySQL
- `core-minio-data` — oggetti MinIO
- `core-meilisearch-data` — indici Meilisearch
- `core-redis-data` — dump Redis

## Configurazione del proxy (nginx)

La cartella `nginx/` contiene la configurazione usata dal container `core-nginx`. Qui puoi aggiungere regole personalizzate, certificati SSL e location per le app Core*. Le app interne devono esporre i loro servizi sulla rete `core-network` e il proxy può instradarli per dominio/porta.

Esempio di mapping tipico (già presente in `docker-compose.yml`):

- `coremachine-frontend` → porta 3000
- `coremachine-backend` → porta 3001
- `coredocument-frontend` → porta 3000
- `coredocument-backend` → porta 3003

Puoi modificare `nginx/nginx.conf` o aggiungere file `sites` se necessario.

## Suggerimenti e best practice

- In locale usa file `.env` per sovrascrivere password e chiavi.
- Non esporre password di default in ambienti di produzione.
- Per debugging: esegui `docker-compose logs -f <service>` e `docker ps`.

## Troubleshooting rapido

- MySQL non risponde: controlla `docker logs core-mysql -f` e lo stato del volume.
- Porta occupata: usa `netstat`/`ss` per verificare i binding e mappa porte diverse se necessario.
- MinIO console non raggiungibile: verifica `MINIO_ROOT_USER`/`MINIO_ROOT_PASSWORD` e i log `docker logs core-minio -f`.

Se hai bisogno, posso aiutarti a:

- aggiornare `.env.production` con valori personalizzati
- generare script di avvio/stop o una guida passo-passo per Windows
- rendere il proxy compatibile con domini esterni e Let's Encrypt

----

File importanti:

- [docker-compose.yml](docker-compose.yml) — definizione dei servizi
- `nginx/` — configurazioni del reverse proxy

Per procedere: dimmi se vuoi che applichi valori sicuri nel `.env` e/o che crei uno script di avvio/stop specifico per Windows.


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
