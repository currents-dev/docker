# Changelog

All notable changes to the Currents on-prem Docker Compose deployment will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

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
