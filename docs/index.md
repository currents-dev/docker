---
title: Currents On-Prem Documentation
---

# Currents On-Prem

Docker Compose configuration for self-hosted Currents deployment.

> For Kubernetes deployments and scaled production environments, see the [Currents Helm Chart](https://currents-dev.github.io/helm-charts/docs/) documentation.

## Getting Started

- [Quickstart Guide](quickstart.md) — Get up and running with Docker Compose
- [Configuration Reference](configuration.md) — All environment variables and settings
- [Logging Configuration](logging.md) — Configure container logging for production
- [Backup and Restore](backup-restore.md) — Backup and restore procedures
- [Upgrading Currents On-Prem](upgrading.md) — Upgrade workflows and version management
- [Support Policy](support.md) — What's supported and maintenance responsibilities

## Quick Setup

Clone the [currents-dev/docker repository](https://github.com/currents-dev/docker) and run setup:

```bash
git clone https://github.com/currents-dev/docker.git currents-docker
cd currents-docker/on-prem
./scripts/setup.sh
docker compose up -d
```

You can also [browse the repository on GitHub](https://github.com/currents-dev/docker/tree/main/on-prem) to explore configuration files.

## Configuration Profiles

| Profile | Services Included | Use Case |
|---------|-------------------|----------|
| [`full`](https://github.com/currents-dev/docker/blob/main/on-prem/docker-compose.full.yml) | Redis, MongoDB, ClickHouse, RustFS | Running everything locally |
| [`database`](https://github.com/currents-dev/docker/blob/main/on-prem/docker-compose.database.yml) | Redis, MongoDB, ClickHouse | Using external S3-compatible storage |
| [`cache`](https://github.com/currents-dev/docker/blob/main/on-prem/docker-compose.cache.yml) | Redis | Using external MongoDB, ClickHouse, and S3 |

## Additional Resources

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Podman Documentation](https://docs.podman.io/)
