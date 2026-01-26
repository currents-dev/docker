# Upgrading Currents On-Prem

This guide covers upgrading your Currents on-prem deployment to a new version.

## Before You Begin

1. Check the [CHANGELOG](https://github.com/currents-dev/docker/blob/main/on-prem/CHANGELOG.md) for the version you're upgrading to
2. Review any breaking changes or required configuration updates
3. Back up your data (see [Backup and Restore](./backup-restore.md))

## Upgrade Types

### Image-Only Updates

When a new version only includes updated container images (no compose or config changes):

```bash
cd on-prem

# Update the image tag in your .env file
# Change DC_CURRENTS_IMAGE_TAG to the new version (e.g., 2026-01-26-001)

# Pull the new images
docker compose pull

# Restart with new images
docker compose up -d
```

> **Note:** The `DC_CURRENTS_IMAGE_TAG` in your `.env` file controls which version of Currents images are pulled. You must update this value to pull a new version. Run `./scripts/check-env.sh` to see if your tag differs from the current release.

### Updates with Compose File Changes

When the CHANGELOG indicates compose file changes:

```bash
cd on-prem

# Stop services (recommended for major updates)
docker compose down

# Pull latest repository changes
git pull

# Update DC_CURRENTS_IMAGE_TAG in your .env file to the new version
# Check VERSION file for the current release version: cat VERSION

# Regenerate your compose file (if using custom profile)
./scripts/generate-compose.sh <your-profile>

# Or if using a pre-generated profile, it's already updated by git pull

# Pull new images
docker compose pull

# Start services
docker compose up -d
```

### Updates with New Environment Variables

When the CHANGELOG indicates new environment variables:

```bash
cd on-prem

# Pull latest repository changes
git pull

# Check for missing variables and version discrepancies
./scripts/check-env.sh

# Add any missing variables to your .env file
# The script will show which variables are missing

# Update DC_CURRENTS_IMAGE_TAG in your .env file to the new version
# Check VERSION file for the current release version: cat VERSION

# Pull new images and restart
docker compose pull
docker compose up -d
```

## Version Checking

Check your current version:

```bash
# View the VERSION file
cat on-prem/VERSION

# Or check the header in your compose file
head -5 on-prem/docker-compose.yml
```

Check running container versions:

```bash
docker compose ps --format "table {{.Name}}\t{{.Image}}"
```

## Rollback

If you need to rollback to a previous version:

```bash
cd on-prem

# Stop services
docker compose down

# Checkout the previous version
git checkout <previous-tag-or-commit>

# Regenerate compose file if needed
./scripts/generate-compose.sh <your-profile>

# Start services
docker compose up -d
```

## Troubleshooting

### Services won't start after upgrade

1. Check logs for errors: `docker compose logs --tail=50`
2. Verify all required environment variables are set: `./scripts/check-env.sh`
3. Ensure compose file was regenerated if templates changed

### Connection errors in logs

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

### Database migration issues

Some upgrades may require database migrations. The scheduler service runs migrations automatically on startup. Check scheduler logs:

```bash
docker compose logs scheduler
```

### Missing environment variables

If services fail with missing configuration errors:

```bash
# Check what variables are missing
./scripts/check-env.sh

# Compare your .env with .env.example for new required variables
# See: https://github.com/currents-dev/docker/blob/main/on-prem/.env.example
diff <(grep -v '^#' .env | grep '=' | cut -d'=' -f1 | sort) \
     <(grep -v '^#' .env.example | grep '=' | cut -d'=' -f1 | sort)
```
