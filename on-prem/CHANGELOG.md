# Changelog

All notable changes to the Currents on-prem Docker Compose deployment will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

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
