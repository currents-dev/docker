# Currents.dev Docker

Docker configurations for running Currents services.

## Repository Structure

```
├── on-prem/          # Self-hosted deployment using Docker Compose
│   ├── docs/         # User documentation
│   ├── scripts/      # Setup and generation scripts
│   └── templates/    # Modular compose templates
└── (future tools)    # Additional Docker configurations may be added here
```

## On-Premises

For self-hosted Currents deployment, see the [On-Prem documentation](on-prem/docs/).

```bash
cd on-prem
./scripts/setup.sh
docker compose up -d
```

## Development

- [On-Prem Development Guide](on-prem/README.md) — Architecture, scripts, and contribution guidelines

## Releasing (On-Prem)

Releases are tied to Currents container image tags, which use date-based versioning: `YYYY-MM-DD-NNN`.

### Release Process

1. **Update the image tag** in `on-prem/.env.example`:

2. **Update the changelog** in `on-prem/CHANGELOG.md`:
   - Move items from "Unreleased" to a new version section
   - Add release date and summary of changes

3. **Commit the release**:
   ```bash
   git add on-prem/.env.example on-prem/CHANGELOG.md
   git commit -m "release: on-prem 2026-01-14-001"
   ```

4. **Create a git tag** (namespaced for on-prem):
   ```bash
   git tag on-prem/2026-01-14-001
   ```

5. **Push**:
   ```bash
   git push && git push --tags
   ```

### Tag Format

Tags are namespaced by tool to allow for future additions:

| Tool | Tag Format | Example |
|------|------------|---------|
| On-Prem | `on-prem/YYYY-MM-DD-NNN` | `on-prem/2026-01-14-001` |

List all on-prem releases:
```bash
git tag -l 'on-prem/*'
```
