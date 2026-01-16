# Backup and Restore

This guide covers backing up and restoring data for your Currents on-prem deployment.

## Overview

Currents stores data in several locations:

| Service | Default Path | Data Type |
|---------|--------------|-----------|
| MongoDB | `data/mongodb` | Primary application data (projects, runs, tests, users) |
| ClickHouse | `data/clickhouse` | Analytics and reporting data |
| Redis | `data/redis` | Cache and session data (optional to backup) |
| RustFS | `data/rustfs` | Artifacts, screenshots, videos (if using the provided rustfs) |

## Before You Begin

> **Important:** Always stop services before backing up to ensure data consistency.

```bash
cd on-prem
docker compose stop
```

## Backup Procedures

### Full Backup (All Data)

The simplest approach is to backup the entire `data/` directory:

```bash
# Stop services
docker compose stop

# Create timestamped backup
tar -czvf backup-$(date +%Y%m%d-%H%M%S).tar.gz data/

# Restart services
docker compose start
```

> **Important:** In addition to data backups, securely store:
> - Your `.env` file (contains credentials needed for restore) - use a password manager or secrets vault
> - Your `docker-compose.yml` (or keep it version controlled)

### MongoDB Backup

MongoDB contains your primary application data. For production environments, consider using `mongodump` for more reliable backups.

#### Option 1: File-based backup (services stopped)

```bash
docker compose stop
tar -czvf mongodb-backup-$(date +%Y%m%d).tar.gz data/mongodb/
docker compose start
```

#### Option 2: mongodump (services running)

```bash
# Source credentials from .env
source .env

# Run mongodump inside the container
docker compose exec mongodb mongodump \
  -u "$MONGODB_USERNAME" \
  -p "$MONGODB_PASSWORD" \
  --authenticationDatabase admin \
  --archive=/data/db/backup.archive

# Copy backup out of container
docker compose cp mongodb:/data/db/backup.archive ./mongodb-backup-$(date +%Y%m%d).archive

# Clean up backup file in container
docker compose exec mongodb rm /data/db/backup.archive
```

### ClickHouse Backup

ClickHouse stores analytics data. For large datasets, use ClickHouse's native backup.

#### Option 1: File-based backup (services stopped)

```bash
docker compose stop
tar -czvf clickhouse-backup-$(date +%Y%m%d).tar.gz data/clickhouse/
docker compose start
```

#### Option 2: ClickHouse native backup (services running)

```bash
# Source credentials from .env
source .env

# Create backup using clickhouse-client
docker compose exec clickhouse clickhouse-client \
  --user currents \
  --password "$CLICKHOUSE_CURRENTS_PASSWORD" \
  --query "BACKUP DATABASE currents TO Disk('backups', 'backup-$(date +%Y%m%d)')"
```

> **Note:** Native backups require configuring a backup disk in ClickHouse. See [ClickHouse backup documentation](https://clickhouse.com/docs/en/operations/backup).

### RustFS / Object Storage Backup

If using local RustFS for object storage:

```bash
docker compose stop
tar -czvf rustfs-backup-$(date +%Y%m%d).tar.gz data/rustfs/
docker compose start
```

If using external S3-compatible storage, use your cloud provider's backup features or tools like `aws s3 sync` or `rclone`.

### Redis Backup (Optional)

Redis primarily stores cache data that can be regenerated. Backup is optional but can speed up recovery:

```bash
docker compose stop
tar -czvf redis-backup-$(date +%Y%m%d).tar.gz data/redis/
docker compose start
```

## Restore Procedures

### Prerequisites

Before restoring, ensure you have:
- Your backed up `.env` file (or recreate with the same credentials)
- Your `docker-compose.yml` file (or clone the repository and run setup)

### Full Restore

```bash
# Stop services
docker compose down

# Remove existing data (careful!)
rm -rf data/

# Extract backup
tar -xzvf backup-YYYYMMDD-HHMMSS.tar.gz

# Set permissions (Podman users - see quickstart troubleshooting)
# Example for rootful Podman:
# sudo chown -R 999:999 data/mongodb data/redis
# sudo chown -R 101:101 data/clickhouse

# Restart services
docker compose up -d
```

### MongoDB Restore

#### From file-based backup

```bash
docker compose down
rm -rf data/mongodb/
tar -xzvf mongodb-backup-YYYYMMDD.tar.gz
docker compose up -d
```

#### From mongodump archive

```bash
# Copy backup into container
docker compose cp ./mongodb-backup-YYYYMMDD.archive mongodb:/data/db/backup.archive

# Source credentials
source .env

# Restore using mongorestore
docker compose exec mongodb mongorestore \
  -u "$MONGODB_USERNAME" \
  -p "$MONGODB_PASSWORD" \
  --authenticationDatabase admin \
  --archive=/data/db/backup.archive \
  --drop

# Clean up
docker compose exec mongodb rm /data/db/backup.archive
```

### ClickHouse Restore

#### From file-based backup

```bash
docker compose down
rm -rf data/clickhouse/
tar -xzvf clickhouse-backup-YYYYMMDD.tar.gz
docker compose up -d
```

### RustFS Restore

```bash
docker compose down
rm -rf data/rustfs/
tar -xzvf rustfs-backup-YYYYMMDD.tar.gz
docker compose up -d
```

