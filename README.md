# CoreServices

Servizi infrastrutturali condivisi per tutta la suite Core*.

## Servizi Inclusi

- **MySQL** - Database relazionale
- **MinIO** - Object Storage (S3-compatible)
- **Meilisearch** - Full-text search engine
- **PHPMyAdmin** - Interfaccia web per MySQL

## Comandi Rapidi

```bash
# Avvia tutti i servizi
start.bat

# Ferma tutti i servizi
stop.bat

# Visualizza i log
logs.bat
```

## Comandi Manuali

```bash
# Start
docker-compose -p coreservices up -d

# Stop
docker-compose -p coreservices down

# Logs
docker-compose -p coreservices logs -f [service-name]

# Status
docker-compose -p coreservices ps
```

## Accesso ai Servizi

- **MySQL**: `localhost:3306`
- **PHPMyAdmin**: http://localhost:8080
- **MinIO API**: `localhost:9000`
- **MinIO Console**: http://localhost:9001
- **Meilisearch**: http://localhost:7700

## Network

Tutti i servizi sono sulla network Docker `core-network`. Le applicazioni Core* devono connettersi a questa network per usare i servizi.

## Volumi

I dati sono persistenti nei volumi Docker:
- `core-mysql-data` - Database MySQL
- `core-minio-data` - File MinIO
- `core-meilisearch-data` - Indici Meilisearch
