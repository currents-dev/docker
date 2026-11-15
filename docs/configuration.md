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
| `APP_CONTENT_STORAGE_ENDPOINT` | string | `${FILE_STORAGE_ENDPOINT}` | App content bucket endpoint (external access): context shares, organization logos and session files. Unset, context sharing and logo editing are off and session files cannot be uploaded ([details](./object-storage.md#app-content-bucket)) |
| `APP_CONTENT_STORAGE_BUCKET` | string | `currents-app-content` | App content bucket name |
| `APP_CONTENT_STORAGE_ACCESS_KEY_ID` | string | `${FILE_STORAGE_ACCESS_KEY_ID}` | App content bucket access key ID |
| `APP_CONTENT_STORAGE_SECRET_ACCESS_KEY` | string | `${FILE_STORAGE_SECRET_ACCESS_KEY}` | App content bucket secret access key |
| `APP_CONTENT_STORAGE_REGION` | string | _(commented)_ | S3 region (required for AWS S3) |
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
| `FILE_STORAGE_INTERNAL_ENDPOINT` | string | `http://host.docker.internal:9000` | Object storage endpoint the services use from inside Docker. For AWS S3, set it to `FILE_STORAGE_ENDPOINT` ([details](./object-storage.md)) |
| `FILE_STORAGE_FORCE_PATH_STYLE` | bool | _(commented)_ | Use path-style S3 URLs (auto-set to `true` when using RustFS profile) |
| `APP_CONTENT_STORAGE_INTERNAL_ENDPOINT` | string | `${FILE_STORAGE_INTERNAL_ENDPOINT}` | App content bucket endpoint the services use from inside Docker |
| `APP_CONTENT_STORAGE_FORCE_PATH_STYLE` | bool | _(commented)_ | Path-style URLs for the app content bucket (auto-set to `true` when using RustFS profile) |
| `API_BASE_URL` | string | `${APP_BASE_URL}` | Public API origin, used in share links and as the OAuth token audience |
| `AUTOMATED_REPORTS_EMAIL_BCC` | string | _(empty)_ | BCC address for automated reports |
| `INVITE_EMAIL_BCC` | string | _(empty)_ | BCC address for invitation emails |
| `INVITE_EXPIRATION_DAYS` | int | `14` | Number of days before invitations expire |
| `EMAIL_LINKS_BASE_URL` | string | `${APP_BASE_URL}` | Base URL for links in emails (derived from APP_BASE_URL) |
| `BETTER_AUTH_RATE_LIMIT_MAX` | int | `100` | Requests to `/api/auth/*` per client address per window. The dashboard reads the session on every page load, so a team behind one NAT or proxy shares one budget, and past it pages load with no data |
| `BETTER_AUTH_RATE_LIMIT_WINDOW_SECONDS` | int | `10` | The window for `BETTER_AUTH_RATE_LIMIT_MAX` |

### Remote MCP and OAuth

Remote MCP lets coding agents use Currents tools over HTTP at `<APP_BASE_URL>/mcp`. Clients authenticate with a Currents API key or personal access token, or, with the OAuth provider on, by signing in with a Currents account. Both endpoints are reachable by anyone who can reach the install; they refuse requests without a valid credential.

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `MCP_ENABLED` | bool | `true` | Serve remote MCP at `/mcp`. Set `false` to turn it off; `/mcp` then answers 503 |
| `MCP_ORIGINS` | string | _(empty)_ | Other origins clients reach `/mcp` on, comma separated |
| `OAUTH_PROVIDER_ENABLED` | bool | `true` in `.env.example` | Serve OAuth authorization (`/api/auth/oauth2/*`, `/.well-known/oauth-*`). Issuer, token audience and JWKS URL are derived from `APP_BASE_URL`. Off when absent, so an upgraded `.env` keeps it off until added. Use an `https` `APP_BASE_URL` for any real setup. Over `http` it works only on `localhost`, or, for an evaluation, on a `.localhost` name in `OAUTH_HTTP_ALLOWED_HOSTS`. On any other `http` host the API refuses to start with it on, so set it to `false` there |
| `OAUTH_DYNAMIC_CLIENT_REGISTRATION_ENABLED` | bool | `true` in `.env.example` | Let clients register themselves, the way to add a client without internet access |
| `OAUTH_CIMD_ENABLED` | bool | `true` | Accept clients identified by a client ID metadata document: an https URL the server fetches. Hosts resolving to private, loopback or link-local addresses are refused |
| `OAUTH_HTTP_ALLOWED_HOSTS` | string | _(empty)_ | For an evaluation without TLS: a `.localhost` name (e.g. `currents.localhost`) the OAuth endpoints may serve over `http`. Browsers resolve `.localhost` names to this machine. Another `http` host starts, but OAuth clients are sent to an `https` issuer the install does not serve |
| `OAUTH_JWKS_URL` | string | `<APP_BASE_URL>/api/auth/jwks` | Where the API fetches its own signing keys to check access tokens. With a `.localhost` `APP_BASE_URL`, set `http://localhost:4000/api/auth/jwks`: the container cannot resolve `.localhost` names, so every token is rejected. Set the same when the container cannot reach or trust `APP_BASE_URL` (split DNS, an internal CA) |
| `OAUTH_RATE_LIMIT_REGISTER_MAX`, `OAUTH_RATE_LIMIT_TOKEN_MAX`, `OAUTH_RATE_LIMIT_AUTHORIZE_MAX`, `OAUTH_RATE_LIMIT_USERINFO_MAX` | int | `5`, `20`, `30`, `60` | OAuth requests per client address per 60 seconds, on top of `BETTER_AUTH_RATE_LIMIT_MAX` |

### Trace Links

The API answers trace links at `<API_BASE_URL>/t`, with nothing to set. A trace link gives an agent read access to one failed test's Playwright trace: its summary, frames, page snapshots, network requests and an animation of the failure. Agents get the links in context shares and from MCP, and reach them at the same address as the dashboard.

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `TRACE_LINK_BASE_URL` | string | `<API_BASE_URL>/t` | The address trace links point at, to serve them on a host of their own, such as `https://traces.example.com/t`. Keep the `/t`: the API serves trace links only under it, and a value without it gives links that open the dashboard |

With `TRACE_LINK_BASE_URL` on another host, route that host to the `api` container (port 4000) in your proxy, with its own TLS certificate. The bundled Traefik (`tls` profile) routes only its API, director and storage hosts (`TRAEFIK_*_SUBDOMAIN` under `TRAEFIK_DOMAIN`).

Trace work runs on worker threads in the `api` container, one job per thread, so it doesn't slow the rest of the API. The threads follow the container's CPUs: the host's, since the compose files set no CPU limit.

| CPUs | Threads |
|------|---------|
| 1 | One, for reads and renders |
| 2–3 | One for reads, one for renders |
| 4 or more | Two for reads, one for renders |

In testing, an `api` container with 2 CPUs and 2 GB answered about 2 agent investigations per second, with animations under 1.5 s at the 95th percentile and the rest of the API still answering in 2–3 ms. A busy hour of 10 failing runs uses about a sixth of that. The test ran on Apple Silicon; x86 cloud vCPUs render more slowly, so take it as an upper bound.

- Memory peaked at 0.8–1.0 GB under load, plus up to 128 MB of cached trace answers. The cache size is fixed.
- One render thread runs at a time, so more CPUs make quick reads faster but not animations.
- Past capacity, trace requests answer `503` with `Retry-After: 5`, and agents retry.

### CI OIDC Token Exchange (Optional)

A CI job can get a record key from the OIDC token its CI provider gives it, so no record key is stored as a CI secret. The reporters ask for a key this way only when no record key is set. The key is valid for 6 hours and works for the whole organization that owns the project the job names (the project only picks the organization and its trust policy), and the reporter revokes it when the job ends. An organization admin adds a trust policy for each repository or owner in the dashboard; a job without a matching policy is refused.

The exchange is off. Set `OIDC_TOKEN_EXCHANGE_ENABLED=true` in `.env` and run `docker compose up -d` once the requirements below are met. It needs the images of a release that includes the exchange.

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `OIDC_TOKEN_EXCHANGE_ENABLED` | bool | _(unset)_ | Turn the exchange on. Off, `POST /oidc/token` answers 404. On with no `OIDC_TOKEN_AUDIENCE`, it answers 503 |
| `OIDC_TOKEN_AUDIENCE` | string | _(empty)_ | **Required when the exchange is on.** A name you choose for this install, such as `currents:record-key:acme`. It is not a URL, so a change of DNS does not affect it. A token is accepted only when its audience is exactly this string. The CI jobs have to ask for a token with this audience, see Requirements. Do not use `currents:record-key`, the name Currents cloud uses: a token made for the cloud would then be accepted here. A token made for another install is refused |
| `OIDC_EXTRA_ISSUERS` | string | _(empty)_ | Self-managed GitLab and GitHub Enterprise Server instances whose jobs may exchange tokens, besides the cloud providers. Comma-separated `provider=issuer` entries, for example `gitlab=https://gitlab.acme.internal,github=https://ghes.acme.internal/_services/token`. The director and the API read it, and both refuse to start with an invalid value. Unset: cloud providers only. See Requirements |
| `OIDC_TRUST_FORWARDED_FOR` | bool | _(unset)_ | Count the exchange's requests per client address by the last entry of `X-Forwarded-For`. Set it to `true` only when a proxy in front of the director appends the client's address to that header and passes on none that the caller wrote. Otherwise a caller writes the header and gets a new count for each request, so the limit does nothing. Unset, the limit counts the address of the connection, which behind a proxy is the proxy's: every caller then shares 120 requests a minute. Check what your proxy writes before setting it |

Requirements:

- **Network.** The director checks a token with the CI provider's public signing keys, which it fetches over https through the provider's OpenID Connect discovery document. It needs outbound access to the providers you use: GitHub Actions (`token.actions.githubusercontent.com`), GitLab.com (`gitlab.com`), CircleCI (`oidc.circleci.com`), Buildkite (`agent.buildkite.com`) and Bitbucket Pipelines (`api.bitbucket.org`). It does not work on an install without internet access, unless the only issuers are self-hosted ones you list in `OIDC_EXTRA_ISSUERS`. For each listed instance the director needs outbound https access to its host, which can be private or internal; only the listed hosts are fetched.
- **Self-managed GitLab and GitHub Enterprise Server.** Tokens from these are accepted when you list their issuers in `OIDC_EXTRA_ISSUERS`: `gitlab=` followed by the URL of the GitLab instance, and `github=` followed by `https://<host>/_services/token` for GitHub Enterprise Server. The issuer is compared with the `iss` claim of the token as an exact string. Write each as `https`, with the host in lowercase, no default port, and no user, password, trailing slash, query or fragment. An issuer of a cloud provider, an issuer listed twice, an unknown provider and more than 20 entries are refused. The director and the API do not start with an entry they cannot use, so check `docker compose logs director api` after you change it. The `.env` file reaches both services, so you set it once. A trust policy stores the issuer it was made for and matches only tokens of that issuer, because a self-hosted instance chooses its own owner and project IDs, which can equal IDs on GitLab.com or github.com. The dashboard form for adding a policy for a listed issuer is not available yet. This part needs the images of a release that includes self-hosted issuers.
- **Internal certificate authority.** When a listed instance uses a certificate from your own authority, give the director that authority with `NODE_EXTRA_CA_CERTS`, the path of a PEM file inside the container. Only the director fetches signing keys, so only it needs the file. Put the file on the host and mount it into the director, for example in a `docker-compose.override.yml` next to `docker-compose.yml`, which `docker compose` reads on its own:

  ```yaml
  services:
    director:
      environment:
        NODE_EXTRA_CA_CERTS: /certs/internal-ca.pem
      volumes:
        - ./certs/internal-ca.pem:/certs/internal-ca.pem:ro
  ```

  Node.js adds the file to its built-in authorities; it does not replace them. If you start the stack with `-f`, add the same lines to a file you pass with `-f`.
- **Audience.** There is no default. Pick a name for your install, such as `currents:record-key:<company>`, and set it as `OIDC_TOKEN_AUDIENCE`. On GitHub Actions the reporter requests the token itself, with the audience in `CURRENTS_OIDC_AUDIENCE`, which defaults to `currents:record-key`, the name Currents cloud uses: set it to your name in those jobs. On the other providers the job supplies the token, so the audience is whatever the job asks the provider for (`aud` in a GitLab CI `id_tokens` entry, and the commands on CircleCI, Buildkite and Bitbucket Pipelines): use your name there. The hint the reporter prints when it has neither a record key nor a token shows `CURRENTS_OIDC_AUDIENCE` when it is set.
- **Indexes.** The scheduler creates the indexes the exchange needs when it starts, with the other indexes the release declares: a TTL index on `recordKeys.expiresAt` that removes expired keys, and a partial index on `recordKeys.issuedFor.policyId` that finds the keys of a removed trust policy. There is nothing to build by hand. Record keys are looked up by hash without an index on-prem, which is fast while the collection is small; keys from the exchange expire after six hours, and MongoDB's TTL cleanup removes their documents later.
- **Limits.** The director counts at most 120 requests a minute from one address before it checks a token, and at most 600 keys a minute for one organization. When Redis is down it refuses the requests.

### AI Explanations and Chat (Optional)

The `ai-queue-worker` service runs the AI tasks (test explanations, chat) from the `ai-bmq` queue. `webhooks` does not run AI tasks.

The service is off by default, because it needs an LLM endpoint you provide. AI stays off for an organization until an admin grants AI consent in its settings, so turn the worker on first: AI tasks requested without it wait in the queue and never finish. To turn it on, add to `.env`:

```bash
COMPOSE_PROFILES=ai
AI_QUEUE_WORKER_ENABLED=true
```

- `COMPOSE_PROFILES=ai` starts `ai-queue-worker` with `docker compose up -d`. With TLS, set `COMPOSE_PROFILES=tls,ai` and run `docker compose up -d` without `--profile tls`: a `--profile` flag replaces `COMPOSE_PROFILES`, so `--profile tls` starts Traefik but not the worker.
- `AI_QUEUE_WORKER_ENABLED=true` has the scheduler build the MongoDB indexes for the AI collections, including the ones that expire old AI sessions. In `webhooks` it also starts the Slack AI answer worker, unless `SLACK_AI_CALLBACK_WORKER_ENABLED` is set.

Then set the LLM endpoint below and run `docker compose up -d`. The worker reads these variables from `.env`, as do all services.

To turn the worker off, remove `ai` from `COMPOSE_PROFILES` and run `docker compose rm -sf ai-queue-worker`. `docker compose up -d` does not stop a service whose profile is no longer listed, so the worker keeps running with its old settings.

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `LLM_PROVIDER_URL` | string | `http://localhost:4001/v1` | Base URL of an OpenAI-compatible API |
| `LLM_API_KEY` | string | _(empty)_ | API key for the LLM provider |
| `LLM_MODEL` | string | `gpt-6-luna` | Model for chat and run-analysis sessions |
| `LLM_EXPLANATION_MODEL` | string | `gpt-6-luna` | Model for test and error explanations |
| `LLM_REASONING_EFFORT` | string | `medium` | `none`, `low`, `medium` or `high`; any other value falls back to `medium` |
| `LLM_EXPLANATION_REASONING_EFFORT` | string | `LLM_REASONING_EFFORT` | Reasoning effort for explanations; same values |
| `EXPLANATION_TRACE_TOOLS` | bool | `false` | `true`: error explanations read the Playwright trace of the failed attempt |
| `AI_QUEUE_CONCURRENCY` | int | `5` | AI tasks run at the same time |
| `USE_MOCK_AI` | bool | `false` | Return mock answers without calling an LLM (testing) |

### Test Steps in ClickHouse (Optional)

Currents can keep the steps of each test attempt in ClickHouse instead of object storage. It is off by default: until you set a time below, steps stay in object storage. Add the variables to `.env`; every service reads it, so they all get the same values.

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `STEPS_CLICKHOUSE_DUAL_WRITE_FROM` | timestamp | _(empty)_ | Tests that start at or after this time write their steps to ClickHouse and to object storage. The dashboard and AI read them from object storage once Redis no longer has them. Read by `director` and `write-worker` |
| `STEPS_CLICKHOUSE_ONLY_FROM` | timestamp | _(empty)_ | Tests that start at or after this time write steps to ClickHouse only, and read them from there. It wins over `STEPS_CLICKHOUSE_DUAL_WRITE_FROM` when both match. Read by `director` and `write-worker` |
| `STEPS_RETENTION_DAYS` | int | `21` | Days steps stay in ClickHouse: 7, 14, 21, 30, 60, 90, 180 or 365. Other values round up. Applies to steps inserted after `write-worker` restarts. To change it, see [Changing the retention](#changing-the-retention). Read by `write-worker` |

Both times are ISO 8601 with a timezone, such as `2026-12-01T00:00:00Z`. The services read them at startup, so set a time that has not come yet, and recreate the containers before it comes. A service still on the old value chooses the storage differently for tests that start after the new time. Tests that started before the time you set keep their steps in object storage. Steps in ClickHouse are deleted after the retention period.

There is no separate test-record ingestion service on Compose: `director` does that work.

To turn it on:

1. Upgrade to images that include this feature (see [Upgrading](./upgrading.md)). `scheduler` creates the `test_attempt_steps` table in ClickHouse when it starts, and the table stays empty until you set a time.
2. Check that `write-worker`, `api` and `ai-queue-worker` reach ClickHouse. They get `CLICKHOUSE_URL` and `CLICKHOUSE_USERNAME` from `.env`, and `CLICKHOUSE_PASSWORD` from `CLICKHOUSE_CURRENTS_PASSWORD`. `api` and `ai-queue-worker` read steps from ClickHouse, and `write-worker` inserts them:

   ```bash
   docker compose exec write-worker printenv | grep CLICKHOUSE_
   docker compose exec api printenv | grep CLICKHOUSE_
   docker compose exec ai-queue-worker printenv | grep CLICKHOUSE_
   ```

   `ai-queue-worker` runs only with the `ai` profile (see [AI Explanations and Chat](#ai-explanations-and-chat-optional)). With your own ClickHouse, `CLICKHOUSE_URL` must be reachable from all three containers.
3. Set `STEPS_CLICKHOUSE_DUAL_WRITE_FROM` to a future time in `.env`, and `STEPS_RETENTION_DAYS` if 21 days is not right. Run `docker compose up -d` to recreate the containers.
4. After that time, run tests, then query `test_attempt_steps` in ClickHouse directly for tests that started after it:

   ```sql
   SELECT record_id, attempt, step_count
   FROM default.test_attempt_steps
   WHERE started_at >= toDateTime64('2026-12-01 00:00:00', 3, 'UTC')
   ORDER BY started_at DESC
   LIMIT 20
   ```

   Every completed attempt that has steps must have a row, and its `step_count` must match the steps in its object storage file, `<orgId>/steps/<runId>/<recordId>/<attempt>.json.gz`. The dashboard reads object storage for these tests, so it does not show whether ClickHouse has them.
5. Set `STEPS_CLICKHOUSE_ONLY_FROM` to a future time, and run `docker compose up -d` again.

Do not set `STEPS_CLICKHOUSE_ONLY_FROM` unless `write-worker`, `api` and `ai-queue-worker` reach ClickHouse. Without it `write-worker` cannot insert steps and nothing else holds them, so the steps of those tests are lost. The dashboard and AI show no steps when `api` or `ai-queue-worker` cannot read them.

#### Changing the retention

To change `STEPS_RETENTION_DAYS`, stop `write-worker`, change `.env`, then start it. If you run more than one `write-worker`, stop all of them first. Writers restarted one at a time can store two versions of one test with different expiry dates.

```bash
docker compose stop write-worker
# Wait until docker compose ps -a shows write-worker as exited, so in-flight inserts finish
# edit STEPS_RETENTION_DAYS in .env
docker compose up -d write-worker
```

#### Going back

To go back, empty both times in `.env` and run `docker compose up -d`. New tests then write steps to object storage. Tests already stored in ClickHouse are still read from there.

### SAML SSO (Optional)

Enable SAML single sign-on by setting the two required variables and mounting your IdP metadata file into `./data/sso`. See [Enable SAML SSO](sso-saml.md) for the full walkthrough. SSO turns on automatically once both required variables are set — there is no separate enable flag.

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `SSO_SAML_IDP_METADATA_FILE` | string | _(empty)_ | Path to the mounted IdP metadata XML (e.g. `/etc/currents/sso/idp-metadata.xml`). **Required to enable SSO.** |
| `SSO_SAML_ISSUER` | string | _(empty)_ | SP entityID / audience — a stable opaque identifier (e.g. `currents-onprem:your-org`). Must match the Audience / SP Entity ID configured in your IdP. **Required to enable SSO.** |
| `SSO_SAML_PROVIDER_ID` | string | `onprem-saml` | Provider id; recommend your IdP name (e.g. `okta`). Becomes the last path segment of the ACS URL, `<APP_BASE_URL>/api/auth/sso/saml2/sp/acs/<provider id>`. |
| `SSO_SAML_DEFAULT_ROLE` | string | `member` | Role granted to auto-provisioned SSO users |
| `SSO_ALLOWED_DOMAINS` | string | _(empty)_ | Comma-separated email domains allowed to sign in via SSO |
| `SSO_SAML_AUTHN_REQUESTS_SIGNED` | bool | `false` | Sign outbound AuthnRequests (requires the SP key below) |
| `SSO_SAML_SP_KEY_FILE` | string | _(empty)_ | Path to the mounted SP private key PEM (only when signing requests) |
| `SSO_SAML_ALLOW_IDP_INITIATED` | bool | `false` | Accept sign-ins started from the IdP's app dashboard. Off, such a sign-in is refused and users start from the Currents sign-in page |

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
| `DC_RUSTFS_IMAGE` | string | `rustfs/rustfs:1.0.1` | RustFS image |
| `DC_AWS_CLI_IMAGE` | string | `amazon/aws-cli:latest` | AWS CLI image (for bucket init) |

#### Included RustFS

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `DC_RUSTFS_DELETE_ARTIFACTS_AFTER_DAYS` | int | _(unset)_ | Delete artifacts (screenshots, videos, traces, stdout) older than this many days, through a lifecycle rule `rustfs-init` applies. Unset keeps them until deleted. Other storage: [Artifact expiry](./object-storage.md#artifact-expiry) |

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
| `DC_SSO_VOLUME` | string | `./data/sso` | SAML SSO files directory (IdP metadata + optional SP PEMs), mounted read-only to `/etc/currents/sso` |

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
