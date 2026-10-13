# Changelog

All notable changes to the Currents on-prem Docker Compose deployment will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Compose File Changes
- The bundled RustFS image is `rustfs/rustfs:1.0.1` (requires `./scripts/generate-compose.sh` if using custom templates)
- The `rustfs` service sets `RUSTFS_CORS_ALLOWED_ORIGINS: "*"`. `1.0.1` sends no CORS headers without it, which breaks trace.playwright.dev and the dashboard's stdout and attachment previews. If you run `1.0.1` from your own compose file, add it there too.
- The `api`, `changestreams-worker` and `write-worker` services read the app content bucket from `APP_CONTENT_STORAGE_*`, and `api` sets `MCP_ENABLED` and `OAUTH_JWKS_URL` (requires `./scripts/generate-compose.sh` if using custom templates)
- `rustfs-init` creates the app content bucket beside the artifact bucket and replaces both buckets' lifecycle configuration on every run

### New Environment Variables
- `APP_CONTENT_STORAGE_ENDPOINT`, `APP_CONTENT_STORAGE_BUCKET`, `APP_CONTENT_STORAGE_ACCESS_KEY_ID`, `APP_CONTENT_STORAGE_SECRET_ACCESS_KEY`, `APP_CONTENT_STORAGE_REGION`, `APP_CONTENT_STORAGE_INTERNAL_ENDPOINT`, `APP_CONTENT_STORAGE_FORCE_PATH_STYLE` — the app content bucket for context shares, organization logos and session files. Without it, context sharing and logo editing are off and uploading session files answers `503`. Copy the block from `.env.example`; on your own storage, create the bucket and add the lifecycle rules in [docs/object-storage.md](../docs/object-storage.md#app-content-bucket)
- `MCP_ENABLED` (default `true`), `MCP_ORIGINS` — remote MCP at `/mcp`
- `OAUTH_PROVIDER_ENABLED`, `OAUTH_DYNAMIC_CLIENT_REGISTRATION_ENABLED`, `OAUTH_CIMD_ENABLED`, `OAUTH_HTTP_ALLOWED_HOSTS` — sign-in to remote MCP with a Currents account. `.env.example` turns the provider on; an upgraded `.env` without `OAUTH_PROVIDER_ENABLED=true` keeps it off. It needs an `https` `APP_BASE_URL`, or `http` on `localhost` (or, for an evaluation, a `.localhost` name in `OAUTH_HTTP_ALLOWED_HOSTS`): with `http` on any other host the API refuses to start, so set `OAUTH_PROVIDER_ENABLED=false`
- `API_BASE_URL` — public API origin, default `APP_BASE_URL`
- `DC_RUSTFS_DELETE_ARTIFACTS_AFTER_DAYS` — delete artifacts in the bundled RustFS after this many days. Unset keeps them

### Changed Environment Variables
- `DC_RUSTFS_IMAGE` defaults to `rustfs/rustfs:1.0.1`. If your `.env` sets it, update the value to pick up the fixes below.

### Removed Environment Variables
- `SSO_SAML_SP_CERT_FILE` — the API never read it. Signed AuthnRequests need only `SSO_SAML_SP_KEY_FILE`; upload the certificate to your IdP.

### Fixed
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
