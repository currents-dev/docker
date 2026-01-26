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

#### 1. Update the version

Edit `on-prem/VERSION` and `on-prem/.env.example` with the image tag.

#### 2. **Update the changelog** in `on-prem/CHANGELOG.md`

- Move items from "Unreleased" to a new version section
- Add release date and summary of changes

#### 3. Commit the release

```bash
git add on-prem/VERSION on-prem/.env.example on-prem/CHANGELOG.md
git commit -m "release: on-prem 2026-01-14-001"
```

#### 4. Create a git tag (namespaced for on-prem)

```bash
git tag on-prem/2026-01-14-001
```

#### 5. Push

```bash
git push && git push --tags
```

### Tag Format

Tags are namespaced by tool to allow for future additions:

| Tool    | Tag Format               | Example                  |
| ------- | ------------------------ | ------------------------ |
| On-Prem | `on-prem/YYYY-MM-DD-NNN` | `on-prem/2026-01-14-001` |

List all on-prem releases:

```bash
git tag -l 'on-prem/*'
```
