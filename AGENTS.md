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
