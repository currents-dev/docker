---
title: Currents On-Prem Documentation
---

# Currents On-Prem

Docker Compose configuration for self-hosted Currents deployment.

## Getting Started

- [Quickstart Guide](quickstart.md) — Get up and running with Docker Compose
- [Configuration Reference](configuration.md) — All environment variables and settings
- [Backup and Restore](./backup-restore.md)
- [Support Policy](support.md) — What's supported and maintenance responsibilities

## Quick Setup

```bash
git clone https://github.com/currents-dev/docker.git currents-docker
cd currents-docker/on-prem
./scripts/setup.sh
docker compose up -d
```

## Configuration Profiles

| Profile | Services Included | Use Case |
|---------|-------------------|----------|
| `full` | Redis, MongoDB, ClickHouse, RustFS | Running everything locally |
| `database` | Redis, MongoDB, ClickHouse | Using external S3-compatible storage |
| `cache` | Redis | Using external MongoDB, ClickHouse, and S3 |

## Additional Resources

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Podman Documentation](https://docs.podman.io/)
