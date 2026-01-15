# Agent Guidelines for currents-dev-docker

## Docker Compose Patterns

### Variable Naming

- **`DC_` prefix**: Use for docker-compose-only variables (not passed to containers)
  - `DC_MONGODB_PORT`, `DC_CURRENTS_IMAGE_TAG`, `DC_REDIS_VOLUME`
- **No prefix**: For app config variables that containers need
  - `MONGODB_PASSWORD`, `APP_BASE_URL`, `CLICKHOUSE_CURRENTS_PASSWORD`

### Port Configuration

- Default **database ports to localhost-only**: `${DC_MONGODB_PORT:-127.0.0.1:27017}:27017`
- Default **application ports to all interfaces**: `${DC_API_PORT:-4000}:4000`
- Don't use `expose:` - it has no functional effect

### Image Configuration

- **Currents services**: Use repository + tag pattern
  ```yaml
  image: ${DC_CURRENTS_IMAGE_REPOSITORY:-currents-}api:${DC_CURRENTS_IMAGE_TAG:-dev}
  ```
- **Infrastructure services**: Use full image reference
  ```yaml
  image: ${DC_MONGODB_IMAGE:-mongo:8.2.3}
  ```

### Environment Variables

- **Use key-value format** instead of array format for `environment:` sections - makes files more extensible and easier to merge:
  ```yaml
  environment:
    KEY: value
    ANOTHER_KEY: ${VAR}
  ```
  Not: `environment: - KEY=value` (array format)

### Initialization

- Use `command` instead of `entrypoint` when you want to keep the default Docker entrypoint behavior
- For multi-line scripts in YAML, use array format with block scalar to avoid parsing issues with colons:
  ```yaml
  post_start:
    - command:
        - bash
        - -c
        - |
          echo "script here"
  ```

## MongoDB Specifics

- **Replica sets + auth require keyFile** - even single-node replica sets
- **Change streams require replica sets** - can't use standalone MongoDB
- **Connection strings need `authSource=admin`** for root users created by `MONGO_INITDB_ROOT_*`
- Use localhost exception for initial user creation when auth is enabled

## Security Patterns

- **Never default passwords** - require them to be set, generate in setup.sh
- **Keep credentials out of healthcheck commands** - they show in `docker inspect`
- Use variable interpolation for derived URLs: `API_URL=${APP_BASE_URL}/v1`

## Project Structure

- Templates live in `on-prem/templates/compose.*.yml`
- `generate-compose.sh` merges templates into final compose files
- `setup.sh` generates secrets using `generate-secrets.sh`
- `.env.example` documents all configurable variables
- Documentation lives in `docs/`

## Documentation Requirements

**Always update documentation when making changes.** The docs folder (`docs/`) contains user-facing documentation that must stay in sync with the codebase.

### When to Update Each File

| File | Update When... |
|------|----------------|
| `docs/configuration.md` | Adding/removing/changing environment variables, changing defaults, adding new `DC_*` variables |
| `docs/quickstart.md` | Changing setup flow, adding new features users need to configure, changing ports/volumes/services |
| `docs/support.md` | Changing support boundaries, adding new component categories |
| `docs/README.md` | Adding new documentation pages, changing known limitations |
| `.env.example` | Adding any new environment variable (always document generation commands for secrets) |
| `on-prem/README.md` | Changing scripts, profiles, or file structure |

### Documentation Style

- Use tables for configuration references (Variable | Type | Default | Description)
- Group settings into **Required**, **Frequently Used**, and **Other** sections
- Include example values and generation commands for secrets
- Document both localhost development and production deployment patterns

## Environment Variables Reference

When adding new environment variables, ensure they're documented in `.env.example`. Key variables that should be present:

- **Authentication**: `JWT_SECRET`, `JWT_SECRET_EXPIRY`, `API_SECRET` (internal service-to-service auth)
- **ClickHouse**: `CLICKHOUSE_CURRENTS_PASSWORD`, `CLICKHOUSE_ACCESS_TOKEN` (optional token-based auth)
- **Object Storage**: `FILE_STORAGE_REGION` (required for AWS S3, optional for local/MinIO)
- **Initial Setup**: `ON_PREM_EMAIL` (root admin user email)

## CI/CD

- GitHub workflows validate compose files using `docker compose config` and `podman compose config`
- Validation runs on both Ubuntu (Docker) and AlmaLinux 8 (Podman) to ensure compatibility
