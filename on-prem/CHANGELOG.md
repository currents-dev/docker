# Changelog

All notable changes to the Currents on-prem Docker Compose deployment will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

## [2026-10-14-002] - 2026-10-21

Image-only update on `2026-10-14-001`: no compose file or environment variable changes.

- **From `2026-10-14-001`:** update `DC_CURRENTS_IMAGE_TAG`, then `docker compose pull && docker compose up -d`.
- **From `2026-07-26-00x`:** upgrade straight to this release, but with every step of `2026-10-14-001`, since this release keeps its compose files and `.env` settings:
  - regenerate the compose file if you use custom templates (see its Compose File Changes);
  - add its new `.env` block (see its New Environment Variables);
  - follow its Breaking Changes and Upgrade Notes.

  Without the `.env` block, context sharing and logo editing are off, session file uploads answer `503`, and remote MCP sign-in stays off.

### Fixed
- After upgrading to `2026-10-14-001`, users who had signed in before the upgrade could not sign in again. SAML SSO returned to the sign-in page with `account_not_linked`, and the root admin's email and password sign-in answered `INVALID_EMAIL_OR_PASSWORD`. They sign in again with no change to the database. If you added an `issuer` field to the `account` documents by hand, leave it: nothing reads it.
- On `2026-10-14-001`, the first sign-in that created a new account, such as a new SAML user, could hang until the proxy timed out. Signing in again worked.

### Upgrade Notes
- The scheduler drops the `account_issuer_accountId_uidx` index from the MongoDB `account` collection when it starts (migration `20261021-drop-account-issuer-index`). `2026-10-14-001` created it on the first new account. An install that never ran `2026-10-14-001` doesn't have it, and the migration does nothing.
- A SAML sign-in started before the containers restart and finished after fails. Start it again from the Currents sign-in page.

### Changed
- An MCP client that asks only for identity scopes (`openid`, `profile`, `email`, `offline_access`) shows the consent screen once, even when the person already allowed the same client into an organization.
- A `localhost` redirect URI matches on any port, as `127.0.0.1` and `[::1]` already did.
- A client can register a custom-scheme redirect URI that names a host, such as Cursor's `cursor://anysphere.cursor-retrieval/oauth/callback`.
- An authorization whose `redirect_uri` holds a fragment (`#…`) or a user name and password is refused.

## [2026-10-14-001] - 2026-10-14

Feature release: remote MCP with sign-in through an OAuth provider, context sharing and session files in a second bucket, and artifact expiry in the bundled RustFS. It changes the SAML SSO sign-in URL, so read Breaking Changes before upgrading. Update `DC_CURRENTS_IMAGE_TAG`, regenerate the compose file if you use custom templates, add the new `.env` block, then `docker compose pull && docker compose up -d`.

### Breaking Changes
- **SAML SSO: the ACS URL moves** from `<APP_BASE_URL>/api/auth/sso/saml2/callback/<provider id>` to `<APP_BASE_URL>/api/auth/sso/saml2/sp/acs/<provider id>`. The old path answers `404`, so SSO sign-in fails until your IdP sends assertions to the new one. The root admin's email and password sign-in is unaffected. Schedule the IdP change for the upgrade window:
  1. In the IdP's SAML app, set the Single Sign-On / ACS URL (Entra ID: Reply URL) to the new URL. Set the Recipient and Destination URLs to the new URL as well. In Okta, leave "Use this for Recipient URL and Destination URL" checked (the default) and both follow the Single Sign-On URL. Currents rejects an assertion whose Recipient or Destination is any other URL.
  2. Keep the Audience / SP Entity ID. It must still equal `SSO_SAML_ISSUER`, which doesn't change.
  3. Sign in from the Currents sign-in page to confirm.
- **SAML SSO: sign-ins started from the IdP's app dashboard** (an Okta tile, the Entra My Apps portal) are refused unless `SSO_SAML_ALLOW_IDP_INITIATED=true`. Sign-ins started from the Currents sign-in page work either way.
- **SAML SSO: the assertion must be signed**, not just the response. An unsigned `Assertion` is refused with `SAML_ASSERTION_SIGNATURE_REQUIRED`. In Okta, set Assertion Signature to Signed under the app's Sign On → Advanced Settings.

### Upgrade Notes
- Upgrade to `2026-10-14-002` or later: on this release, users who signed in before the upgrade can't sign in again.
- **The scheduler builds new MongoDB indexes, then runs this release's migrations, when it starts.**
  - On `instances` it first drops the indexes `2026-07-26` reads a run's spec files with, so those reads have no index until the build finishes.
  - On a large database the builds take hours and keep MongoDB's CPU busy.
  - Estimate the time for your install, and on a large database build the indexes before upgrading, in a maintenance window. See [Upgrading from 2026-07-26 to 2026-10-14](../docs/upgrading.md#upgrading-from-2026-07-26-to-2026-10-14).
  - The migrations take about a minute per 100,000 runs.
  - The dashboard, API and run recording keep running, more slowly. Until the migrations finish, filtering runs by status can leave out runs recorded before the upgrade, and new results can take longer to process. Check that the scheduler's last startup in `docker compose logs scheduler` ends with `Startup tasks complete` (see [Database migration issues](../docs/upgrading.md#database-migration-issues)). If it logs an error instead, such as a ClickHouse `Timeout error.`, the remaining migrations don't run until the scheduler starts again: run `docker compose restart scheduler`. Finished migrations are skipped, and the run backfills skip the runs they already updated.

### Compose File Changes
- The bundled RustFS image is `rustfs/rustfs:1.0.1` (requires `./scripts/generate-compose.sh` if using custom templates)
- The `rustfs` service sets `RUSTFS_CORS_ALLOWED_ORIGINS: "*"`. `1.0.1` sends no CORS headers without it, which breaks trace.playwright.dev and the dashboard's stdout and attachment previews. If you run `1.0.1` from your own compose file, add it there too.
- The `api`, `changestreams-worker` and `write-worker` services read the app content bucket from `APP_CONTENT_STORAGE_*`, and `api` sets `MCP_ENABLED` (requires `./scripts/generate-compose.sh` if using custom templates)
- `rustfs-data-init` runs before `rustfs` and makes uid `10001` the owner of its data directory (requires `./scripts/generate-compose.sh` if using custom templates)
- `rustfs-init` creates the app content bucket beside the artifact bucket and adds its lifecycle rules. Each run rewrites only the rules it owns, matched by ID (`ai-context-share`, `share-3d`, `share-7d`, `trace-links`, `delete-artifacts-after-days`), and keeps any others

### New Environment Variables
- `APP_CONTENT_STORAGE_ENDPOINT`, `APP_CONTENT_STORAGE_BUCKET`, `APP_CONTENT_STORAGE_ACCESS_KEY_ID`, `APP_CONTENT_STORAGE_SECRET_ACCESS_KEY`, `APP_CONTENT_STORAGE_REGION`, `APP_CONTENT_STORAGE_INTERNAL_ENDPOINT`, `APP_CONTENT_STORAGE_FORCE_PATH_STYLE` — the app content bucket for context shares, organization logos and session files. Without it, context sharing and logo editing are off and uploading session files answers `503`. Copy the block from `.env.example`; on your own storage, create the bucket and add the lifecycle rules in [docs/object-storage.md](../docs/object-storage.md#app-content-bucket)
- `MCP_ENABLED` (default `true`), `MCP_ORIGINS` — remote MCP at `/mcp`
- `OAUTH_PROVIDER_ENABLED`, `OAUTH_DYNAMIC_CLIENT_REGISTRATION_ENABLED`, `OAUTH_CIMD_ENABLED`, `OAUTH_HTTP_ALLOWED_HOSTS`, `OAUTH_JWKS_URL` — sign-in to remote MCP with a Currents account. `.env.example` turns the provider on; an upgraded `.env` without `OAUTH_PROVIDER_ENABLED=true` keeps it off. It needs an `https` `APP_BASE_URL`, or `http` on `localhost` (or, for an evaluation, a `.localhost` name in `OAUTH_HTTP_ALLOWED_HOSTS`, with `OAUTH_JWKS_URL` on `localhost`): with `http` on any other host the API refuses to start, so set `OAUTH_PROVIDER_ENABLED=false`
- `API_BASE_URL` — public API origin, default `APP_BASE_URL`
- `SSO_SAML_ALLOW_IDP_INITIATED` — accept SAML sign-ins started from the IdP's app dashboard. Default `false`
- `BETTER_AUTH_RATE_LIMIT_MAX` (default `100`), `BETTER_AUTH_RATE_LIMIT_WINDOW_SECONDS` (default `10`) — requests to `/api/auth/*` per client address. Raise them for a large team behind one NAT or proxy
- `OAUTH_RATE_LIMIT_REGISTER_MAX`, `OAUTH_RATE_LIMIT_TOKEN_MAX`, `OAUTH_RATE_LIMIT_AUTHORIZE_MAX`, `OAUTH_RATE_LIMIT_USERINFO_MAX` — OAuth requests per client address per 60 seconds (defaults `5`, `20`, `30`, `60`)
- `DC_RUSTFS_DELETE_ARTIFACTS_AFTER_DAYS` — delete artifacts in the bundled RustFS after this many days. Unset keeps them

### Changed Environment Variables
- `DC_RUSTFS_IMAGE` defaults to `rustfs/rustfs:1.0.1`. If your `.env` sets it, update the value to pick up the fixes below.

### Added
- Remote MCP at `<APP_BASE_URL>/mcp`: coding agents use Currents tools with a Currents API key, a personal access token, or a sign-in through the OAuth provider
- Personal access tokens, for the REST API and MCP
- Context sharing and share links, organization logo editing and session file uploads, stored in the app content bucket

### Changed
- The Improve Currents consent is not shown, and a new organization is created with no AI consent granted. It never applied to a self-hosted install.
- Images are built on Debian trixie (`node:24-trixie-slim`)

### Removed Environment Variables
- `SSO_SAML_SP_CERT_FILE` — the API never read it. Signed AuthnRequests need only `SSO_SAML_SP_KEY_FILE`; upload the certificate to your IdP.

### Fixed
- On a fresh Linux install with the `full` profile, RustFS exited with `Permission denied`: Docker created `./data/rustfs` owned by root, and RustFS runs as uid `10001`.
- Share links, MCP and the assistant pointed at `api.currents.dev` instead of the install's own API. `API_BASE_URL` now defaults to `APP_BASE_URL`.
- The dashboard signed users out everywhere when sign-in requests hit the rate limit, and all users shared one limit. It now applies per client address, and `BETTER_AUTH_RATE_LIMIT_*` sets it.
- Records of who did something showed a user ID instead of an email address.
- The bundled RustFS enforces bucket lifecycle rules. `1.0.0-alpha.79` accepted a lifecycle configuration and returned it from `GetBucketLifecycleConfiguration`, but never expired the matching objects.
- The bundled RustFS includes the fix for CVE-2026-73288, where lifecycle and scanner sweeps could expire objects under COMPLIANCE retention when lock metadata was missing or unreadable.

## [2026-07-26-006] - 2026-10-07

Image-only update: no compose file or environment variable changes. Update `DC_CURRENTS_IMAGE_TAG`, then `docker compose pull && docker compose up -d`.

### Fixed
- The dashboard no longer sends errors and session replays to Currents' Sentry account.
- The director no longer exits when Redis or MongoDB rejects a request, for example Redis returning `MISCONF` after a failed snapshot. The failing request gets a 500 and the director keeps serving. This affected artifact uploads, Cypress spec claims, run cancellation checks and record key validation.
- The director and writer no longer write every log line to files inside the container. Logs still go to stdout, so `docker compose logs` is unchanged.

### Changed
- Redis keys that track which filter values a project has seen (branches, tags, authors, annotations) store a hash of the value instead of the full value, which can be up to 512 characters.
- Test step upload state in Redis expires after 2 hours instead of 24.

## [2026-07-26-005] - 2026-10-01

Image-only update: no compose file or environment variable changes. Update `DC_CURRENTS_IMAGE_TAG`, then `docker compose pull && docker compose up -d`.

### Fixed
- Admins can promote a Guest to Member or Admin, and invite with any role. On-prem organizations were held to a single billable seat, so invites were limited to Guest and a Guest's role could not be changed.

## [2026-07-15-001] - 2026-07-15

### Compose File Changes
- Added SSO volume mount to compose templates (requires `./scripts/generate-compose.sh` if using custom templates)

### New Environment Variables
- `SSO_SAML_IDP_METADATA_FILE`, `SSO_SAML_ISSUER` — required to enable SAML SSO
- `SSO_SAML_PROVIDER_ID`, `SSO_SAML_DEFAULT_ROLE`, `SSO_SAML_AUTHN_REQUESTS_SIGNED`, `SSO_SAML_SP_CERT_FILE`, `SSO_SAML_SP_KEY_FILE` — optional SAML SSO configuration
- `DC_SSO_VOLUME` — SAML SSO files directory (IdP metadata + optional SP PEMs)

### Added
- SAML SSO support — delegate sign-in to your SAML 2.0 identity provider (Okta, Entra ID, etc.)
- GitHub Container Registry (GHCR) as an alternative image source for customer accounts without AWS IAM access
- Version discrepancy check in `check-env.sh` — warns when `DC_CURRENTS_IMAGE_TAG` does not match `on-prem/VERSION`

## [2026-01-26-001] - 2026-01-26

### Added
- Initial public release
- Docker Compose configuration with modular profiles (full, database, cache)
- Optional Traefik TLS termination
- Documentation for quickstart, configuration, and container image access

<!-- Template for future releases:

## [YYYY-MM-DD-NNN]

### Breaking Changes
- List any breaking changes that require user action

### Compose File Changes
- Changes requiring `./scripts/sync-templates.sh` or `./scripts/generate-compose.sh`

### New Environment Variables
- New variables added to `.env.example`

### Changed Environment Variables
- Variables with changed defaults or behavior

### Added
- New features

### Changed
- Changes to existing features

### Fixed
- Bug fixes

### Removed
- Removed features
-->
