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

## Upgrading from 2026-07-26 to 2026-10-14

Upgrade to `2026-10-14-002` or later. On `2026-10-14-001`, users who signed in before the upgrade can't sign in again: SAML SSO returns them to the sign-in page with `account_not_linked`, and the root admin's password sign-in answers `INVALID_EMAIL_OR_PASSWORD`. `2026-10-14-002` signs them in with no change to the database.

`2026-10-14` adds MongoDB indexes to collections that grow with your history: `instances`, `runs` and `testRecord`. The scheduler builds any that are missing when it starts, before it runs the migrations:

- **On `instances`, it first drops the two indexes `2026-07-26` uses to read a run's spec files**, then builds their replacements. Until the first build finishes, reading a run's spec files has no index.
- **Each build reads the whole collection**, and loads MongoDB while it runs.

On a large database the builds can take hours and keep MongoDB's CPU busy, so build the indexes yourself before you upgrade, in a maintenance window, as below.

### Estimate the upgrade time

Open `mongosh` on the bundled MongoDB, with the credentials the `mongodb` container already has:

```bash
cd on-prem
docker compose exec mongodb sh -c \
  'mongosh -u "$MONGO_INITDB_ROOT_USERNAME" -p "$MONGO_INITDB_ROOT_PASSWORD" --authenticationDatabase admin currents'
```

Replace `currents` if you changed `MONGODB_DATABASE`. With your own MongoDB, connect `mongosh` with the `MONGODB_URI` from your `.env`. Then run:

```js
const gb = (c) => db.getCollection(c).stats().size / 1e9;
const runs = db.runs.estimatedDocumentCount();
const indexGB = 2 * gb('instances') + gb('runs') + gb('testRecord');
print(`runs: ${runs}`);
print(`data the index builds read: ${indexGB.toFixed(1)} GB`);
print(`index builds: ${Math.ceil(indexGB / 60)} to ${Math.ceil(indexGB * 0.6)} minutes`);
print(`migrations: about ${Math.ceil(runs / 100000)} minutes`);
```

How the numbers are worked out:

- **Index builds** take time in proportion to the data they read. Each build reads its whole collection, and `instances` is read twice. The range is:
  - **Low end, about 1 second per GB:** measured on a Compose install with 100,000 runs, 500,000 `instances` (6.6 GB) and 600,000 `testRecord` documents (5.9 GB), on a fast local disk with nothing else running. All the builds took 13 seconds.
  - **High end, about 0.6 minutes per GB:** measured on a large production database, with the API reading while the indexes built.

  Use the high end to plan unless your MongoDB has fast disks, enough memory to hold the data, and no other load during the window.
- **Migrations** took about a minute per 100,000 runs in testing: about 30 seconds for the run status backfill, 10 to 25 seconds for the ClickHouse run backfill, and 10 seconds to create the ClickHouse tables.

If the index builds come to more than a few minutes, build the indexes before you upgrade.

### Build the indexes before you upgrade

With the indexes already built, the upgrade only drops the two old `instances` indexes, and run reads keep an index throughout. `2026-07-26` runs normally while they build: they are extra indexes it doesn't use.

1. Start at the beginning of the upgrade window, and allow the time the estimate gives.
2. In the same `mongosh` session, run:

   ```js
   db.runCommand({
     createIndexes: 'instances',
     indexes: [{ key: { runId: 1, createdAt: 1, _id: -1 }, name: 'runId_1_createdAt_1__id_-1' }],
   });
   db.runCommand({
     createIndexes: 'instances',
     indexes: [{ key: { createdAt: 1 }, name: 'createdAt_1' }],
   });
   const prRuns = { 'meta.pr.id': { $type: 'string' }, deletedAt: null };
   db.runCommand({
     createIndexes: 'runs',
     indexes: [
       { key: { orgId: 1, projectId: 1, status: 1, _id: -1 }, name: 'runs_status_recent_by_project' },
       { key: { orgId: 1, projectId: 1, _id: -1, 'meta.pr.id': 1 }, name: 'runs_pr_list_recent_by_project', partialFilterExpression: prRuns },
       {
         key: { orgId: 1, projectId: 1, _id: -1, 'meta.pr.id': 1, status: 1, completionState: 1, 'meta.pr.title': 1, 'meta.pr.source': 1 },
         name: 'runs_pr_list_search_recent_by_project',
         partialFilterExpression: prRuns,
       },
       { key: { orgId: 1, projectId: 1, 'meta.pr.source': 1, _id: -1 }, name: 'runs_pr_source_recent_by_project', partialFilterExpression: prRuns },
     ],
   });
   db.runCommand({
     createIndexes: 'testRecord',
     indexes: [
       { key: { runId: 1 }, name: 'runId_1' },
       { key: { recordId: 1, _t: 1 }, name: 'recordId_1__t_1' },
     ],
   });
   db.runCommand({
     createIndexes: 'instanceStats',
     indexes: [{ key: { 'props.projectId': 1, 'props.spec': 1, date: -1 }, name: 'props.projectId_1_props.spec_1_date_-1' }],
   });
   ```

   Each command returns when its build is done, with `ok: 1`. To follow a build in progress from a second session, run `db.currentOp({ 'command.createIndexes': { $exists: true } })`.
3. Upgrade straight after the last build, as in [Updates with New Environment Variables](#updates-with-new-environment-variables).

**Don't restart the `2026-07-26` scheduler between the builds and the upgrade.** When it starts, it drops the two `instances` indexes above and rebuilds its own, so run reads lose their index again. Before upgrading, check that `db.instances.getIndexes()` lists `runId_1_createdAt_1__id_-1` and `createdAt_1`; if it doesn't, run the two `instances` commands again.

The scheduler builds the remaining new indexes itself, on `usage`, `runTimeouts`, `apiKeys`, `notifications` and `user`. Those collections stay small, and their builds take seconds.

### While the scheduler starts

The dashboard, API and run recording keep running while the scheduler builds indexes and migrates, but more slowly. Until the migrations finish, filtering runs by status can leave out runs recorded before the upgrade. Wait for `Startup tasks complete` in its log, as in [Database migration issues](#database-migration-issues).

If you use SAML SSO, also update your IdP: the ACS URL moves, and the assertion must be signed. See the `2026-10-14-001` entry in the [CHANGELOG](https://github.com/currents-dev/docker/blob/main/on-prem/CHANGELOG.md) and [Enable SAML SSO](./sso-saml.md).

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

Rolling back from `2026-10-14` to `2026-07-26` rebuilds indexes. When the `2026-07-26` scheduler starts, it drops the two `instances` indexes `2026-10-14` builds and rebuilds its own, which takes as long as the `instances` builds in the [estimate](#estimate-the-upgrade-time). Reading a run's spec files has no index until the first one finishes, so roll back in a maintenance window too.

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

Some upgrades may require database migrations. The scheduler service runs migrations automatically on startup and logs `Startup tasks complete` when they finish. Check scheduler logs:

```bash
docker compose logs scheduler | grep -E 'Running startup tasks|Startup tasks complete|"level":50'
```

The last `Running startup tasks...` line should be followed by `Startup tasks complete`. `docker compose restart` keeps the logs of earlier starts, so a `Startup tasks complete` line before it doesn't count.

If a migration fails, for example with a ClickHouse `Timeout error.` on a busy host, the scheduler logs the error (`"level":50`) and keeps running, but the remaining migrations don't run until it starts again. Restart it:

```bash
docker compose restart scheduler
```

Finished migrations are skipped, and an interrupted backfill skips the records it already updated, so a restart is safe to repeat.

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
