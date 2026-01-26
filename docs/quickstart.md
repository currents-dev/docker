# Docker Compose Quickstart

This guide walks you through setting up Currents on-premises using Docker Compose.

## Prerequisites

- **Docker** 20.10+ with Docker Compose V2, or **Podman** 4.0+ with docker-compose
- At least 8GB RAM available for containers
- Git (for cloning the repository)
- **Container image access** — see [Container Image Access](./container-images.md) to set up AWS ECR access and mirror images to your registry

## Step 1: Clone the Repository

Clone the [currents-dev/docker repository](https://github.com/currents-dev/docker):

```bash
git clone https://github.com/currents-dev/docker.git currents-docker
cd currents-docker/on-prem
```

> **Tip:** You can [browse the repository on GitHub](https://github.com/currents-dev/docker/tree/main/on-prem) to explore the configuration files before cloning.

## Step 2: Create Environment File

A `.env` file is required to run the services. You have two options:

### Option A: Run Setup (Recommended)

The interactive setup wizard will guide you through configuration:

```bash
./scripts/setup.sh
```

This will:
1. Ask you to select a configuration profile
2. Symlink the appropriate `docker-compose.yml`
3. Create a `.env` file with auto-generated secrets

### Option B: Manual Setup

If you prefer to configure manually:

```bash
cp .env.example .env
```

Then edit `.env` to fill in the required secrets. See the [`.env.example` file](https://github.com/currents-dev/docker/blob/main/on-prem/.env.example) for all available variables and [Configuration Reference](./configuration.md) for generation commands.

### Configuration Profiles

| Profile | File | Services Included | Use Case |
|---------|------|-------------------|----------|
| `full` | [`docker-compose.full.yml`](https://github.com/currents-dev/docker/blob/main/on-prem/docker-compose.full.yml) | Redis, MongoDB, ClickHouse, RustFS | Running everything locally |
| `database` | [`docker-compose.database.yml`](https://github.com/currents-dev/docker/blob/main/on-prem/docker-compose.database.yml) | Redis, MongoDB, ClickHouse | Using external S3-compatible storage |
| `cache` | [`docker-compose.cache.yml`](https://github.com/currents-dev/docker/blob/main/on-prem/docker-compose.cache.yml) | Redis | Using external MongoDB, ClickHouse, and S3 |

## Step 3: Configure Environment

Review and customize `.env` as needed.

### Application URLs

Configure the URLs where Currents will be accessible. For production, we recommend using subdomains:

```bash
# Dashboard and API
APP_BASE_URL=https://currents-app.example.com

# Recording endpoint (where test reporters send data)
CURRENTS_RECORD_API_URL=https://currents-record.example.com
```

For local development, use localhost with ports:

```bash
APP_BASE_URL=http://localhost:4000
CURRENTS_RECORD_API_URL=http://localhost:1234
```

### Root User Account

The `ON_PREM_EMAIL` is the email address used to create the initial root admin user:

```bash
ON_PREM_EMAIL=admin@example.com
```

### Object Storage (Recommended: Bring Your Own)

We recommend using your own S3-compatible object storage (AWS S3, Google Object Storage etc.) rather than the included RustFS service. Configure your storage provider:

```bash
# Your S3-compatible endpoint
FILE_STORAGE_ENDPOINT=https://s3.us-east-1.amazonaws.com

# Bucket name (must already exist)
FILE_STORAGE_BUCKET=currents-artifacts

# Credentials
FILE_STORAGE_ACCESS_KEY_ID=<credentials>
FILE_STORAGE_SECRET_ACCESS_KEY=<credentials>

# Region (required for AWS S3)
FILE_STORAGE_REGION=us-east-1

# Use path-style URLs (required for MinIO and most S3-compatible services, not needed for AWS S3)
# FILE_STORAGE_FORCE_PATH_STYLE=true
```

If using the included RustFS for testing, configure the `RUSTFS_*` variables instead. The RustFS profile automatically sets `FILE_STORAGE_FORCE_PATH_STYLE=true` for all services.

> ⚠️ **Production Note:** RustFS is intended for local development and testing only—it is **not recommended for production deployments**. The included Docker Compose configuration is designed for local development; production environments should use external, production-grade object storage backends such as AWS S3, Google Cloud Storage, or a managed MinIO cluster.

### SMTP Configuration

Email is required for notifications, invitations, and reports:

```bash
# SMTP server
SMTP_HOST=smtp.example.com
SMTP_PORT=587
SMTP_SECURE=false

# SMTP credentials
SMTP_USER=your-smtp-username
SMTP_PASS=your-smtp-password

# From addresses for outgoing emails
AUTOMATED_REPORTS_EMAIL_FROM="Currents Report <reports@yourdomain.com>"
INVITE_EMAIL_FROM="Currents App <no-reply@yourdomain.com>"
```

> ⚠️ **Important: FROM Address Configuration**
>
> You **must** change the FROM addresses to use a domain your SMTP provider is authorized to send from. The format is `"Display Name <email@domain.com>"`.
>
> If you leave the default `example.com` addresses, emails will be rejected with DMARC errors:
> ```
> 5.7.26 Unauthenticated email from example.com is not accepted due to domain's DMARC policy
> ```
>
> **For testing:** If using a sandbox (e.g., Mailgun sandbox), use your sandbox domain like `no-reply@sandboxXXXXX.mailgun.org`. Emails may land in spam, but they will be delivered.

> **Note:** `SMTP_SECURE=false` uses STARTTLS (explicit TLS) which starts unencrypted then upgrades to TLS—this is the standard for port 587 and recommended for most providers. Set `SMTP_SECURE=true` for implicit TLS connections (port 465), which establish TLS immediately without upgrading.

Common SMTP configurations:

| Provider | Host | Port | Secure |
|----------|------|------|--------|
| Amazon SES | `email-smtp.us-east-1.amazonaws.com` | 587 | false |
| SendGrid | `smtp.sendgrid.net` | 587 | false |
| Mailgun | `smtp.mailgun.org` | 587 | false |
| Gmail | `smtp.gmail.com` | 587 | false |

See [Configuration Reference](./configuration.md) for all available options.

## Step 4: Start Services

```bash
docker compose up -d
```

Monitor startup progress:

```bash
docker compose logs -f
```

## Step 5: Verify Installation

Once all services are running, access:

- **Dashboard**: http://localhost:4000
- **Director API**: http://localhost:1234

Check service health:

```bash
docker compose ps
```

All services should show as "healthy" or "running".

## Production: TLS Termination

For production deployments, we recommend setting up a reverse proxy with TLS termination in front of the Currents services. You can either:

- **Bring your own** — Use your existing reverse proxy (nginx, HAProxy, AWS ALB, etc.) to handle TLS and route traffic to the Currents services
- **Use the included Traefik** — A pre-configured Traefik profile is included for convenience

### Using Your Own Reverse Proxy

Configure your reverse proxy to route:
- `https://currents-app.example.com` → `http://localhost:4000` (API/Dashboard)
- `https://currents-record.example.com` → `http://localhost:1234` (Director)

Update your `.env` to match the external URLs:
```bash
APP_BASE_URL=https://currents-app.example.com
CURRENTS_RECORD_API_URL=https://currents-record.example.com
```

### Using the Included Traefik Profile

1. Place your wildcard certificate files in `data/traefik/certs/`:
   - `wildcard.crt` - **Fullchain** certificate file (server cert + intermediate certs concatenated)
   - `wildcard.key` - Private key file

   > **Important:** The `wildcard.crt` must be a fullchain certificate containing your server certificate followed by intermediate certificate(s). Without the full chain, clients will fail with "unable to verify certificate" errors. You can create it by concatenating: `cat server.crt intermediate.crt > wildcard.crt`

2. Configure your domain in `.env`:
   ```bash
   TRAEFIK_DOMAIN=example.com
   TRAEFIK_API_SUBDOMAIN=currents-app
   TRAEFIK_DIRECTOR_SUBDOMAIN=currents-record
   ```

3. Start with the TLS profile:
   ```bash
   docker compose --profile tls up -d
   ```

## Common Operations

### View Logs

```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f api
```

### Stop Services

```bash
docker compose down
```

### Restart a Service

```bash
docker compose restart api
```

### Update to Latest Version

```bash
# Pull latest images
docker compose pull

# Restart with new images
docker compose up -d
```

### Regenerate Secrets

```bash
./scripts/setup.sh
# Select "Y" when asked to regenerate secrets
```

## Troubleshooting

### Services Won't Start

Check logs for errors:
```bash
docker compose logs --tail=50
```

Verify `.env` file exists and has all required secrets populated.

### Database Connection Issues

Ensure MongoDB has initialized its replica set. Check logs:
```bash
docker compose logs mongodb
```

The replica set initialization runs automatically on first start.

If you see connection errors in service logs (e.g., "connection refused", "ECONNREFUSED", database connection failures), this is often due to timing issues with dependencies starting. Try restarting the service that's logging the error:

```bash
# Restart the specific service
docker compose restart <service-name>

# Or restart all services
docker compose restart
```

For example, if the `api` service shows MongoDB connection errors, restart it:
```bash
docker compose restart api
```

The service will retry connecting to its dependencies once they're fully ready.

### Port Conflicts

If ports are already in use, customize them in `.env`:
```bash
DC_API_PORT=4001
DC_DIRECTOR_PORT=1235
```

### Podman: Permission Denied Errors

If you're using Podman and see permission errors like:
```
mongodb-1  | chown: changing ownership of '/data/db': Permission denied
mongodb-1  | bash: /data/db/replica.key: Permission denied
```

This is due to Podman's rootless mode and UID mapping. Follow these steps:

#### Step 1: Create Data Directories

Create the data directories manually before starting services:

```bash
mkdir -p data/mongodb data/redis data/clickhouse data/rustfs data/startup data/traefik/certs data/traefik/config
```

#### Step 2: Set Permissions

Set ownership to match container UIDs:

For **rootless Podman** (running as a regular user):
```bash
# MongoDB runs as uid 999
podman unshare chown -R 999:999 data/mongodb

# ClickHouse runs as uid 101
podman unshare chown -R 101:101 data/clickhouse

# Redis runs as uid 999
podman unshare chown -R 999:999 data/redis

# RustFS runs as uid 10001 (if using local object storage)
podman unshare chown -R 10001:10001 data/rustfs

# Scheduler runs as uid 1000
podman unshare chown -R 1000:1000 data/startup

# Traefik runs as root (uid 0) - no chown needed, just create dirs
```

For **rootful Podman** (running as root or with sudo):
```bash
# MongoDB runs as uid 999
sudo chown -R 999:999 data/mongodb

# ClickHouse runs as uid 101
sudo chown -R 101:101 data/clickhouse

# Redis runs as uid 999
sudo chown -R 999:999 data/redis

# RustFS runs as uid 10001 (if using local object storage)
sudo chown -R 10001:10001 data/rustfs

# Scheduler runs as uid 1000
sudo chown -R 1000:1000 data/startup

# Traefik runs as root (uid 0) - no chown needed
```

> **Tip:** To check if you're running rootless Podman, run `podman info --format '{{.Host.Security.Rootless}}'`. If it returns `true`, use `podman unshare`; otherwise use `sudo chown`.

#### Step 3: SELinux (RHEL/CentOS/Fedora)

If SELinux is enabled, you need to relabel the data directories so containers can access them:

```bash
# Relabel data directories for container access
sudo chcon -Rt svirt_sandbox_file_t data/
```

Or for each directory individually:
```bash
sudo chcon -Rt svirt_sandbox_file_t data/mongodb
sudo chcon -Rt svirt_sandbox_file_t data/redis
sudo chcon -Rt svirt_sandbox_file_t data/clickhouse
sudo chcon -Rt svirt_sandbox_file_t data/rustfs
sudo chcon -Rt svirt_sandbox_file_t data/startup
sudo chcon -Rt svirt_sandbox_file_t data/traefik
```

To verify the labels are set correctly:
```bash
ls -lZ data/
```

You should see `svirt_sandbox_file_t` in the output.

#### Alternative: Use Named Volumes

Named volumes avoid permission issues entirely since Podman manages them:

```bash
# Create named volumes
podman volume create mongodb-data
podman volume create redis-data
podman volume create clickhouse-data
podman volume create rustfs-data
podman volume create scheduler-startup
podman volume create traefik-certs
podman volume create traefik-config

# Configure in .env
DC_MONGODB_VOLUME=mongodb-data
DC_REDIS_VOLUME=redis-data
DC_CLICKHOUSE_VOLUME=clickhouse-data
DC_RUSTFS_VOLUME=rustfs-data
DC_SCHEDULER_STARTUP_VOLUME=scheduler-startup
DC_TRAEFIK_CERTS_DIR=traefik-certs
DC_TRAEFIK_CONFIG_DIR=traefik-config
```

> **Note:** Named volumes are stored in Podman's volume directory (typically `~/.local/share/containers/storage/volumes/`) rather than the current directory.

## Advanced: Port Binding Configuration

By default, application ports (API, Director) bind to all interfaces while database ports bind to localhost only. You can customize this behavior using `DC_*_PORT` variables.

### Binding to Specific Interfaces

To restrict a service to localhost only (not accessible from other machines):

```bash
# Bind API to localhost only
DC_API_PORT=127.0.0.1:4000

# Bind Director to localhost only
DC_DIRECTOR_PORT=127.0.0.1:1234
```

To expose a database service to all interfaces (use with caution):

```bash
# Expose MongoDB to all interfaces
DC_MONGODB_PORT=27017

# Expose Redis to all interfaces
DC_REDIS_PORT=6379
```

### Port Configuration Reference

| Variable | Default | Description |
|----------|---------|-------------|
| `DC_API_PORT` | `4000` | Dashboard/API (all interfaces) |
| `DC_DIRECTOR_PORT` | `1234` | Director API (all interfaces) |
| `DC_MONGODB_PORT` | `127.0.0.1:27017` | MongoDB (localhost only) |
| `DC_REDIS_PORT` | `127.0.0.1:6379` | Redis (localhost only) |
| `DC_CLICKHOUSE_HTTP_PORT` | `127.0.0.1:8123` | ClickHouse HTTP (localhost only) |
| `DC_CLICKHOUSE_TCP_PORT` | `127.0.0.1:9123` | ClickHouse TCP (localhost only) |
| `DC_RUSTFS_S3_PORT` | `9000` | RustFS S3 API (all interfaces) |
| `DC_RUSTFS_CONSOLE_PORT` | `9001` | RustFS Console (all interfaces) |

> **Security Note:** Database ports default to localhost-only binding to prevent unintended external access. Only expose them to all interfaces if you have proper firewall rules in place.

## Advanced: Volume Configuration

By default, data is stored in local directories under `./data/`. You can customize volume paths or use named Docker volumes for more advanced storage configurations.

### Using Custom Paths

To store data in different directories:

```bash
# Store MongoDB data on a separate disk
DC_MONGODB_VOLUME=/mnt/ssd/mongodb

# Store ClickHouse data on high-performance storage
DC_CLICKHOUSE_VOLUME=/mnt/nvme/clickhouse
```

### Using Named Docker Volumes

For advanced volume management (encryption, network storage, custom drivers), create Docker volumes first and reference them by name:

```bash
# Create volumes with custom options
docker volume create --driver local \
  --opt type=none \
  --opt o=bind \
  --opt device=/mnt/encrypted/mongodb \
  mongodb-data

docker volume create --driver local \
  --opt type=none \
  --opt o=bind \
  --opt device=/mnt/encrypted/clickhouse \
  clickhouse-data
```

Then reference them in `.env`:

```bash
DC_MONGODB_VOLUME=mongodb-data
DC_CLICKHOUSE_VOLUME=clickhouse-data
```

### Volume Configuration Reference

| Variable | Default | Description |
|----------|---------|-------------|
| `DC_REDIS_VOLUME` | `./data/redis` | Redis data storage |
| `DC_MONGODB_VOLUME` | `./data/mongodb` | MongoDB data storage |
| `DC_CLICKHOUSE_VOLUME` | `./data/clickhouse` | ClickHouse data storage |
| `DC_RUSTFS_VOLUME` | `./data/rustfs` | RustFS object storage |
| `DC_SCHEDULER_STARTUP_VOLUME` | `./data/startup` | Scheduler startup state |

> **Tip:** Named Docker volumes are useful when you need encryption, network-attached storage, or custom volume drivers that aren't possible with bind mounts.

## Next Steps

- Review the [Configuration Reference](./configuration.md) for all available options
- Set up [Backup & Restore](./backup-restore.md) procedures for production use
- Read the [Upgrading Guide](./upgrading.md) to learn how to update to new versions
- Configure [Logging for Production](./logging.md) to ensure proper log management
- Read the [Support Policy](./support.md) to understand support boundaries
