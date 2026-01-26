# Configuration Reference

This document lists all configurable environment variables for the Currents Docker Compose deployment.

Variables are configured in the `.env` file. Run `./scripts/setup.sh` to generate secrets automatically, or use the manual generation commands shown below.

## Values

### Required

These values must be set before starting. Secrets can be generated with `./scripts/setup.sh` or manually.

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `ON_PREM_EMAIL` | string | `admin@localhost` | Email address for the root admin user |
| `SMTP_HOST` | string | `localhost` | SMTP server hostname |
| `SMTP_USER` | string | `test` | SMTP username |
| `SMTP_PASS` | string | `test` | SMTP password |
| `JWT_SECRET` | string | _(empty)_ | Authentication token secret. Generate with: `./scripts/generate-secrets.sh token 64` |
| `API_SECRET` | string | _(empty)_ | Internal API secret for service-to-service auth. Generate with: `./scripts/generate-secrets.sh token 64` |
| `RUSTFS_SECRET_KEY` | string | _(empty)_ | RustFS/S3 secret key (only if using included RustFS). Generate with: `./scripts/generate-secrets.sh token 32` |
| `MONGODB_PASSWORD` | string | _(empty)_ | MongoDB password. Generate with: `./scripts/generate-secrets.sh token 32` |
| `CLICKHOUSE_DEFAULT_PASSWORD` | string | _(empty)_ | ClickHouse default user password (only if using included ClickHouse). Generate with: `./scripts/generate-secrets.sh token 32` |
| `CLICKHOUSE_CURRENTS_PASSWORD` | string | _(empty)_ | ClickHouse currents user password. Generate with: `./scripts/generate-secrets.sh token 32` |
| `GITLAB_STATE_SECRET` | string | _(empty)_ | GitLab integration key (base64-encoded RSA private key) |

### Frequently Used

These have defaults but you'll likely want to customize them.

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `APP_BASE_URL` | string | `http://localhost:4000` | Base URL for the dashboard/API |
| `CURRENTS_RECORD_API_URL` | string | `http://localhost:1234` | Base URL for the recording endpoint (director) |
| `SMTP_PORT` | int | `587` | SMTP server port |
| `SMTP_SECURE` | bool | `false` | Whether SMTP uses TLS |
| `AUTOMATED_REPORTS_EMAIL_FROM` | string | `Currents Report <report@example.com>` | From address for automated report emails |
| `INVITE_EMAIL_FROM` | string | `Currents App <no-reply@example.com>` | From address for invitation emails |
| `FILE_STORAGE_ENDPOINT` | string | `http://localhost:9000` | Object storage endpoint (external access) |
| `FILE_STORAGE_BUCKET` | string | `currents` | Object storage bucket name |
| `FILE_STORAGE_ACCESS_KEY_ID` | string | `${RUSTFS_ACCESS_KEY}` | Object storage access key ID |
| `FILE_STORAGE_SECRET_ACCESS_KEY` | string | `${RUSTFS_SECRET_KEY}` | Object storage secret access key |
| `FILE_STORAGE_REGION` | string | _(commented)_ | S3 region (required for AWS S3) |
| `CLICKHOUSE_URL` | string | `http://clickhouse:8123` | ClickHouse HTTP endpoint |
| `CLICKHOUSE_USERNAME` | string | `currents` | ClickHouse username |
| `MONGODB_USERNAME` | string | `currents-user` | MongoDB username |
| `MONGODB_DATABASE` | string | `currents` | MongoDB database name |
| `MONGODB_URI` | string | _(derived)_ | Full MongoDB connection string |
| `TRAEFIK_DOMAIN` | string | `localhost` | Base domain for Traefik TLS routing |
| `TRAEFIK_API_SUBDOMAIN` | string | `currents-app` | Subdomain for API/Dashboard |
| `TRAEFIK_DIRECTOR_SUBDOMAIN` | string | `currents-record` | Subdomain for Director |
| `TRAEFIK_STORAGE_SUBDOMAIN` | string | `currents-storage` | Subdomain for RustFS S3 API |
| `TRAEFIK_ENABLE_STORAGE` | bool | `false` | Enable storage routing (auto-set when rustfs included) |

### Other Values

Less commonly changed settings with sensible defaults.

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `JWT_SECRET_EXPIRY` | string | `10m` | How often to expire session tokens |
| `REDIS_URI` | string | `redis://redis:6379` | Redis connection URI |
| `REDIS_URI_SLAVE` | string | `redis://redis:6379` | Redis replica connection URI |
| `RUSTFS_ACCESS_KEY` | string | `rustfs-access-key` | RustFS/S3 access key |
| `FILE_STORAGE_INTERNAL_ENDPOINT` | string | `http://host.docker.internal:9000` | Object storage internal endpoint |
| `FILE_STORAGE_FORCE_PATH_STYLE` | bool | _(commented)_ | Use path-style S3 URLs (auto-set to `true` when using RustFS profile) |
| `AUTOMATED_REPORTS_EMAIL_BCC` | string | _(empty)_ | BCC address for automated reports |
| `INVITE_EMAIL_BCC` | string | _(empty)_ | BCC address for invitation emails |
| `INVITE_EXPIRATION_DAYS` | int | `14` | Number of days before invitations expire |
| `EMAIL_LINKS_BASE_URL` | string | `${APP_BASE_URL}` | Base URL for links in emails (derived from APP_BASE_URL) |

### Docker Compose Configuration

These variables configure Docker Compose behavior only (not passed to containers). All are optional with sensible defaults.

#### Image Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `DC_CURRENTS_IMAGE_REPOSITORY` | string | `currents-` | Image repository prefix for Currents services |
| `DC_CURRENTS_IMAGE_TAG` | string | `dev` | Image tag for Currents services |
| `DC_MONGODB_IMAGE` | string | `mongo:8.2.3` | MongoDB image |
| `DC_REDIS_IMAGE` | string | `redis/redis-stack-server:7.4.0-v8` | Redis image |
| `DC_CLICKHOUSE_IMAGE` | string | `clickhouse/clickhouse-server:25.8` | ClickHouse image |
| `DC_RUSTFS_IMAGE` | string | `rustfs/rustfs:1.0.0-alpha.79` | RustFS image |
| `DC_AWS_CLI_IMAGE` | string | `amazon/aws-cli:latest` | AWS CLI image (for bucket init) |

#### Port Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `DC_DIRECTOR_PORT` | string | `1234` | Director API port (all interfaces) |
| `DC_API_PORT` | string | `4000` | Dashboard/API port (all interfaces) |
| `DC_MONGODB_PORT` | string | `127.0.0.1:27017` | MongoDB port (localhost only) |
| `DC_REDIS_PORT` | string | `127.0.0.1:6379` | Redis port (localhost only) |
| `DC_CLICKHOUSE_HTTP_PORT` | string | `127.0.0.1:8123` | ClickHouse HTTP port (localhost only) |
| `DC_CLICKHOUSE_TCP_PORT` | string | `127.0.0.1:9123` | ClickHouse TCP port (localhost only) |
| `DC_RUSTFS_S3_PORT` | string | `9000` | RustFS S3 API port (all interfaces) |
| `DC_RUSTFS_CONSOLE_PORT` | string | `9001` | RustFS Console port (all interfaces) |

#### Volume Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `DC_REDIS_VOLUME` | string | `./data/redis` | Redis data volume path |
| `DC_MONGODB_VOLUME` | string | `./data/mongodb` | MongoDB data volume path |
| `DC_CLICKHOUSE_VOLUME` | string | `./data/clickhouse` | ClickHouse data volume path |
| `DC_RUSTFS_VOLUME` | string | `./data/rustfs` | RustFS data volume path |
| `DC_SCHEDULER_STARTUP_VOLUME` | string | `./data/startup` | Scheduler startup data volume |

#### Traefik Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `DC_TRAEFIK_IMAGE` | string | `traefik:v3.3` | Traefik image |
| `DC_TRAEFIK_HTTP_PORT` | string | `80` | Traefik HTTP port |
| `DC_TRAEFIK_HTTPS_PORT` | string | `443` | Traefik HTTPS port |
| `DC_TRAEFIK_CERTS_DIR` | string | `./data/traefik/certs` | Certificate directory |
| `DC_TRAEFIK_CONFIG_DIR` | string | `./data/traefik/config` | Custom config directory |
| `TRAEFIK_GENERATE_TEMP_CERTS` | bool | `false` | Generate temporary self-signed certs |

### Observability (Optional)

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `CORALOGIX_API_ENDPOINT` | string | _(empty)_ | Coralogix API endpoint |
| `CORALOGIX_API_KEY` | string | _(empty)_ | Coralogix API key |
| `CORALOGIX_APP_NAME` | string | `customer-name` | Application name for Coralogix |
