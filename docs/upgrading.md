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

## Index Builds Before an Upgrade

A release that declares a new index builds it the first time the new scheduler starts, as part of its startup tasks. On a large `instances` collection that has taken about an hour, and the services are up but incomplete the whole time: `docker compose up -d` returns immediately, while the API answers against a database that is still building.

Between `docker compose pull` and `docker compose up -d` the new images are on disk and the old containers are still running. That is the window to find out what the build will cost:

```bash
docker compose run --rm scheduler \
  node /app/packages/mongo/dist/scripts/migrate.js index-plan --gate
```

This only reads. It runs the image you are upgrading **to** — `docker compose run` uses the `DC_CURRENTS_IMAGE_TAG` already set in your `.env`, which is the new version by this point in the upgrade.

- **Exit 0** — nothing pending, or the estimate is under ten minutes. Carry on with `docker compose up -d`.
- **Exit 2** — the estimated build is over ten minutes. The output names the collections, their sizes and the indexes:

```
Index build estimated at 64 minutes, which is over the limit of 10 minutes.

  instances: 109.0 GB, about 62 minutes (createdAt_1)

Estimated at 30.0 MB/s, the built-in default — this deployment has recorded no index builds of its own, so the real build may be several times faster.
```

- **Any other exit code** — the check itself failed. That is a different problem from a slow build; read the error before deciding.

That rate line matters. Until a build has been recorded the estimate uses a deliberately slow rate, so a first upgrade can report an hour for something that really takes a few minutes. Once one build has been recorded the estimate uses this deployment's own measured rate and the figure is worth trusting.

Pass `--gate-seconds <n>` to use a limit other than 600.

### Building the Indexes First

If the estimate is more downtime than you want, build the indexes before the upgrade, while the old containers keep serving:

```bash
docker compose run --rm scheduler \
  node /app/packages/mongo/dist/scripts/migrate.js sync-indexes
```

Same image, same database. Index sync only adds indexes, so the running version gets indexes it does not use yet and is otherwise unaffected. Index builds read whole collections, so pick a quiet window — nothing is down, but the database is busy.

When it finishes, run `docker compose up -d` as usual. The new scheduler finds the indexes already there and its startup tasks complete immediately.

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

## Upgrading from 2026-10-14 to 2026-11-10

This release changes the Compose files, so upgrade as in [Updates with Compose File Changes](#updates-with-compose-file-changes). If you use AI explanations or chat, turn on the new `ai-queue-worker` service in the same upgrade: see [AI explanations and chat](#ai-explanations-and-chat).

`2026-11-10` builds six MongoDB indexes and runs five migrations when the scheduler starts. None of the indexes is on `instances`, `runs` or `testRecord`, and the migrations read only keys and secrets, so there is nothing to build ahead of the upgrade. On a test install with 3.1 million `instances` (41 GB), 310,000 runs and 124,000 orchestration sessions, the scheduler logged `Startup tasks complete` 18 seconds after `docker compose up -d`.

Run the check in [Index Builds Before an Upgrade](#index-builds-before-an-upgrade) before `docker compose up -d`. On the test install it exited `0` with an estimate of 25 seconds, and the builds took 1 second.

Of this release's indexes, only the one on `orchestrationSession` grows with your history, and only if you use orchestration. At the check's default rate the collection would need about 18 GB to pass the 10-minute limit. If the check exits `2` and names `orchestrationSession`, build it first as in [Building the Indexes First](#building-the-indexes-first).

### What the scheduler builds and runs

| Index | Collection |
|---|---|
| `orchestrationSession` `{ runId: 1 }` | Grows with orchestrated runs. 0.79 GB took about 1 second in testing. |
| `oauthRefreshToken` `{ rotationReplayExpiresAt: 1 }` | Small: refresh tokens of MCP clients. |
| `orgStorageDaily` `{ date: 1, orgId: 1, bytes: 1 }` | Empty on-prem. |
| `scimPendingUsers` `{ orgId: 1, email: 1 }` (unique) | Written only by SCIM provisioning. |
| `customerRequests`, two indexes | Empty on-prem. |

| Migration | What it does | Time in testing |
|---|---|---|
| `20261028-drop-superseded-instances-indexes` | Drops two `instances` indexes that newer ones replace, once the replacements exist. `2026-10-14` already dropped them, so it finds nothing. | 3 ms |
| `20261103-redact-audit-log-secrets` | Masks credentials in stored audit log records. On-prem doesn't store audit records in MongoDB, so it usually finds none. | 553 ms for 10,000 records |
| `20261109-backfill-api-key-hashes` | Stores a hash and the last 4 characters of each organization API key. | 202 ms for 3,000 keys |
| `20261110-backfill-record-key-hashes` | Stores a hash and the last 4 characters of each record key. | 25 ms for 400 keys |
| `20261110-backfill-scim-secret-hashes` | Stores a hash and the last 4 characters of the SCIM secret. | 2 ms |

The two key migrations leave a key without a hash when another document holds the same value, and log a warning with the documents' ids:

- `left N organization API key(s) in M group(s) without a hash`: API keys that share a value already fail to authenticate. Delete the extra copies.
- `left N record key(s) without a hash`: a record key shared by two organizations. Have all but one of them rotate their record key; deleting a copy breaks that organization's CI.

Still on `2026-07-26`? The scheduler also builds the `2026-10-14` indexes on `instances`, `runs` and `testRecord`: estimate and build them first as in [Upgrading from 2026-07-26 to 2026-10-14](#upgrading-from-2026-07-26-to-2026-10-14). `2026-11-10` builds the replacement `instances` indexes before it drops the old ones, so reading a run's spec files keeps an index throughout.

### AI explanations and chat

`webhooks` doesn't run AI tasks in `2026-11-10`. The new `ai-queue-worker` service runs them, and it is in the `ai` Compose profile, which is off by default. If you set `AI_QUEUE_WORKER_ENABLED=true` to use AI, AI stops at this upgrade until you turn the worker on. Before `docker compose up -d`, add to `.env`:

```bash
COMPOSE_PROFILES=ai
```

- Keep `AI_QUEUE_WORKER_ENABLED=true` and your `LLM_*` settings. The worker reads them from the same `.env`.
- With TLS, set `COMPOSE_PROFILES=tls,ai` and run `docker compose up -d` without `--profile tls`. A `--profile` flag replaces `COMPOSE_PROFILES`, so `--profile tls` starts Traefik but not the worker.
- Pull or mirror the `ai-queue-worker` image with the others, and add its repository to your ECR policy. See [Container Image Access](./container-images.md).

The settings are in [AI Explanations and Chat](./configuration.md#ai-explanations-and-chat-optional). If you don't use AI, nothing changes.

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
const indexGB = 2 * gb('instances') + gb('runs') + gb('testRecord') + gb('instanceStats');
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
3. Upgrade straight after the last build. `2026-10-14` has both compose file changes and new environment variables, so:

   ```bash
   cd on-prem
   git pull

   # Lists the variables your .env is missing. Add them: the CHANGELOG's
   # 2026-10-14-001 New Environment Variables says what each one does
   ./scripts/check-env.sh

   # Set DC_CURRENTS_IMAGE_TAG in your .env to the version in the VERSION file
   cat VERSION

   # Only if setup built a custom configuration; the full, database and cache
   # files are updated by git pull. Pass the services in your compose file's
   # name as separate words: for docker-compose.redis-mongodb.yml, run
   # ./scripts/generate-compose.sh redis mongodb
   ./scripts/generate-compose.sh <services>

   docker compose pull
   docker compose up -d
   ```

   Without the new variables, context sharing and logo editing are off, session file uploads answer `503`, and remote MCP sign-in stays off. Without the regenerated compose file, the services don't receive them.

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

Rolling back from `2026-11-10` to `2026-10-14` builds and drops nothing: the `2026-10-14` scheduler keeps the new indexes, and the stored hashes are fields it doesn't read.

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

A long gap with no error between those two lines is usually an index build on a large collection, not a stuck service. See [Index Builds Before an Upgrade](#index-builds-before-an-upgrade) for how to find out what the build costs before you upgrade.

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
