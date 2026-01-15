# Currents On-Prem

Docker Compose configuration for running Currents on-premises.

## Documentation

📚 **For setup and configuration instructions, see the [docs](../docs/) folder:**

- [Quickstart Guide](../docs/quickstart.md) — Get up and running
- [Configuration Reference](../docs/configuration.md) — All environment variables
- [Support Policy](../docs/support.md) — What's supported

---

## Development Guide

This section is for developers working on the docker-compose configuration itself.

### Architecture

The configuration is built from modular templates that are merged together based on the selected profile. This allows users to include only the services they need.

```
templates/
├── compose.currents.yml    # Core Currents application services (always included)
├── compose.redis.yml       # Redis cache
├── compose.mongodb.yml     # MongoDB database
├── compose.clickhouse.yml  # ClickHouse analytics
├── compose.rustfs.yml      # S3-compatible object storage
└── compose.traefik.yml     # TLS termination proxy (optional profile)
```

### Configuration Profiles

| Profile | Services Included | Use Case |
|---------|-------------------|----------|
| `full` | Redis, MongoDB, ClickHouse, RustFS | Running everything locally |
| `database` | Redis, MongoDB, ClickHouse | External S3-compatible storage |
| `cache` | Redis | External MongoDB, ClickHouse, and S3 |

### Scripts

#### `scripts/setup.sh`

Interactive setup wizard that:
- Prompts for profile selection (or custom service selection)
- Generates the docker-compose configuration
- Creates `.env` from `.env.example` with auto-generated secrets

#### `scripts/generate-compose.sh`

Generates a docker-compose file for a specific profile. Used by `setup.sh` but can also be run directly.

```bash
# Generate for a predefined profile
./scripts/generate-compose.sh full
./scripts/generate-compose.sh database
./scripts/generate-compose.sh cache

# Generate for individual services
./scripts/generate-compose.sh redis
./scripts/generate-compose.sh mongodb
./scripts/generate-compose.sh clickhouse
./scripts/generate-compose.sh rustfs

# Combine multiple profiles/services
./scripts/generate-compose.sh database storage
```

**Available profiles:**

| Profile | Description |
|---------|-------------|
| `full` | All services (redis, mongodb, clickhouse, rustfs) |
| `database` | Database services (redis, mongodb, clickhouse) |
| `cache` | Cache (redis) |
| `analytics` | Analytics (clickhouse) |
| `storage` | Object storage (rustfs) |
| `redis` | Redis only |
| `mongodb` | MongoDB only |
| `clickhouse` | ClickHouse only |
| `rustfs` | RustFS only |

#### `scripts/generate-secrets.sh`

Utility for generating secrets and keys.

```bash
# Generate a random token (default 32 characters)
./scripts/generate-secrets.sh token

# Generate a 64-character token
./scripts/generate-secrets.sh token 64

# Generate an RSA private key
./scripts/generate-secrets.sh key mykey.pem
```

### Files

| File | Description |
|------|-------------|
| `docker-compose.yml` | Symlink to your selected configuration |
| `docker-compose.full.yml` | Pre-generated full configuration |
| `docker-compose.database.yml` | Pre-generated database configuration |
| `docker-compose.cache.yml` | Pre-generated cache configuration |
| `.env` | Your environment configuration (git-ignored) |
| `.env.example` | Template for environment configuration |
| `templates/` | Source templates for compose generation |
| `../docs/` | User-facing documentation |

### Services

#### Currents Application
- **director** (port 1234) - Test orchestration service
- **api** (port 4000) - API and dashboard
- **changestreams-worker** - MongoDB change stream processor
- **write-worker** - Async write operations
- **scheduler** - Scheduled tasks and startup migrations
- **webhooks** - Webhook delivery service

#### Data Services (optional, based on profile)
- **redis** (port 6379) - Cache and pub/sub
- **mongodb** (port 27017) - Primary database
- **clickhouse** (port 8123, 9123) - Analytics database
- **rustfs** (port 9000, 9001) - S3-compatible object storage

#### Optional Services
- **traefik** (ports 80, 443) - TLS termination proxy (enabled with `--profile tls`)

### Regenerating Compose Files

After modifying templates, regenerate the pre-committed docker-compose files:

```bash
./scripts/generate-compose.sh full
./scripts/generate-compose.sh database
./scripts/generate-compose.sh cache
```

A GitHub Action validates that committed compose files stay in sync with templates.

### Variable Naming Convention

- **`DC_` prefix**: Docker-compose-only variables (not passed to containers)
  - `DC_MONGODB_PORT`, `DC_CURRENTS_IMAGE_TAG`, `DC_REDIS_VOLUME`
- **No prefix**: App config variables that containers need
  - `MONGODB_PASSWORD`, `APP_BASE_URL`, `CLICKHOUSE_CURRENTS_PASSWORD`
