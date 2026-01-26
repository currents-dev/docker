# Currents.dev - Docker Compose Self Hosted Setup

Set up Currents in self-hosted environments using Docker Compose.

- [Docker Compose Setup](https://currents-dev.github.io/docker)
- [Docker Compose Configuration Reference](https://currents-dev.github.io/docker/configuration.html)
- [AWS IAM User Setup](https://currents-dev.github.io/helm-charts/docs/eks/iam.html)
- [Support Policy](https://currents-dev.github.io/helm-charts/docs/support.html)

⚠️ Important! You must be authenticated as an AWS IAM user to pull images from Current’s Private AWS ECR repositories. Contact [Currents team](mailto:support@currents.dev) with your AWS IAM user details to request access.

<small>Looking for Kubernetes deployment? See [Currents K8S Setup](https://currents-dev.github.io/helm-charts/docs/).</small>

## Quickstart

```bash
cd on-prem
./scripts/setup.sh
docker compose up -d
```

## Development

See [Docker Compose Development Guide](on-prem/README.md) — architecture, scripts, and contribution guidelines.

## Releasing (On-Prem)

Releases are tied to Currents container image tags, which use date-based versioning: `YYYY-MM-DD-NNN`.

### Release Process

> **Note:** `2026-01-14-001` is used as an example version throughout these steps. Replace it with the actual version you're releasing (format: `YYYY-MM-DD-NNN`).

#### 1. Create a release branch

```bash
git checkout -b release-on-prem/2026-01-14-001
```

#### 2. Update the version

Edit `on-prem/VERSION` and `on-prem/.env.example` with the image tag.

#### 3. Update the changelog in `on-prem/CHANGELOG.md`

- Move items from "Unreleased" to a new version section
- Add release date and summary of changes

#### 4. Commit and push the release branch

```bash
git add on-prem/VERSION on-prem/.env.example on-prem/CHANGELOG.md
git commit -m "release: on-prem 2026-01-14-001"
git push -u origin HEAD
```

#### 5. Create a PR and wait for CI

```bash
gh pr create --title "release: on-prem 2026-01-14-001" --body "Release on-prem 2026-01-14-001"
```

CI will run validation and smoke tests. Wait for checks to pass, then get the PR reviewed and merged.

#### 6. Tag the release from main

> **Important:** Always tag from `main` after the PR is merged to ensure the tag points to the merged commit.

```bash
git checkout main && git pull
git tag on-prem/2026-01-14-001
git push origin on-prem/2026-01-14-001
```

#### 7. Create a GitHub release

Create a release on GitHub for the tag:

1. Go to [Releases](https://github.com/currents-dev/docker/releases/new)
2. Select the tag `on-prem/2026-01-14-001`
3. Set the title to `on-prem/2026-01-14-001`
4. Add release notes linking to the CHANGELOG

### Tag Format

Tags are namespaced by tool to allow for future additions:

| Tool    | Tag Format               | Example                  |
| ------- | ------------------------ | ------------------------ |
| On-Prem | `on-prem/YYYY-MM-DD-NNN` | `on-prem/2026-01-14-001` |

List all on-prem releases:

```bash
git tag -l 'on-prem/*'
```
