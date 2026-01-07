# Currents On-Prem

Docker Compose configuration for running Currents on-premises.

## Quick Start

```bash
# Run the interactive setup
./scripts/setup.sh
```

This will:
1. Guide you through selecting a configuration profile
2. Generate the appropriate `docker-compose.yml`
3. Create a `.env` file with auto-generated secrets

Then start the services:

```bash
docker compose up -d
```

## Configuration Profiles

| Profile | Services Included | Use Case |
|---------|-------------------|----------|
| `full` | Redis, MongoDB, ClickHouse, MinIO | Running everything locally |
| `database` | Redis, MongoDB, ClickHouse | External S3-compatible storage |
| `cache` | Redis | External MongoDB, ClickHouse, and S3 |

## Scripts

### `scripts/setup.sh`

Interactive setup wizard that:
- Prompts for profile selection (or custom service selection)
- Generates the docker-compose configuration
- Creates `.env` from `.env.example` with auto-generated secrets

```bash
./scripts/setup.sh
```

### `scripts/generate-compose.sh`

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
./scripts/generate-compose.sh minio

# Combine multiple profiles/services
./scripts/generate-compose.sh database storage
```

**Available profiles:**

| Profile | Description |
|---------|-------------|
| `full` | All services (redis, mongodb, clickhouse, minio) |
| `database` | Database services (redis, mongodb, clickhouse) |
| `cache` | Cache (redis) |
| `analytics` | Analytics (clickhouse) |
| `storage` | Object storage (minio) |
| `redis` | Redis only |
| `mongodb` | MongoDB only |
| `clickhouse` | ClickHouse only |
| `minio` | MinIO only |

### `scripts/generate-secrets.sh`

Utility for generating secrets and keys.

```bash
# Generate a random token (default 32 characters)
./scripts/generate-secrets.sh token

# Generate a 64-character token
./scripts/generate-secrets.sh token 64

# Generate an RSA private key
./scripts/generate-secrets.sh key mykey.pem
```

## Files

| File | Description |
|------|-------------|
| `docker-compose.yml` | Symlink to your selected configuration |
| `docker-compose.full.yml` | Pre-generated full configuration |
| `docker-compose.database.yml` | Pre-generated database configuration |
| `docker-compose.cache.yml` | Pre-generated cache configuration |
| `.env` | Your environment configuration (git-ignored) |
| `.env.example` | Template for environment configuration |
| `templates/` | Source templates for compose generation |

## Environment Configuration

Copy `.env.example` to `.env` and configure as needed. The `setup.sh` script does this automatically and generates required secrets.

Key variables:
- `JWT_SECRET` - Authentication token secret
- `MINIO_SERVER_ACCESS_KEY` / `MINIO_SERVER_SECRET_KEY` - MinIO credentials
- `GITLAB_STATE_SECRET` - GitLab integration key (base64-encoded PEM)

## Services

### Currents Application
- **director** (port 1234) - Test orchestration service
- **api** (port 4000) - API and dashboard
- **changestreams-worker** - MongoDB change stream processor
- **write-worker** - Async write operations
- **scheduler** - Scheduled tasks and startup migrations
- **webhooks** - Webhook delivery service

### Data Services (optional, based on profile)
- **redis** (port 6379, 8001) - Cache and pub/sub
- **mongodb** (port 27017) - Primary database
- **clickhouse** (port 8123, 9123) - Analytics database
- **minio** (port 9000, 9001) - S3-compatible object storage

## Development

To regenerate the pre-committed docker-compose files after modifying templates:

```bash
./scripts/generate-compose.sh full
./scripts/generate-compose.sh database
./scripts/generate-compose.sh cache
```

A GitHub Action validates that committed compose files stay in sync with templates.

