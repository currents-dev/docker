# Logging Configuration

This guide covers configuring container logging for production deployments. Proper log management is essential for monitoring, debugging, and compliance.

## Overview

Container runtimes provide different default logging behaviors:

| Runtime | Default Driver | Production-Ready |
|---------|---------------|------------------|
| Podman | journald | Yes |
| Docker | json-file | No (unbounded growth) |

## Podman

Podman uses **journald** as its default logging driver, which is already production-ready. Logs are written to the systemd journal, providing:

- Automatic log rotation and retention
- Structured logging with metadata
- Integration with system logging infrastructure
- Rate limiting to prevent log floods

### Viewing Logs

```bash
# View logs for a specific container
journalctl CONTAINER_NAME=currents-api

# Follow logs in real-time
journalctl -f CONTAINER_NAME=currents-api

# View logs since a specific time
journalctl CONTAINER_NAME=currents-api --since "1 hour ago"
```

### Shipping Logs to Remote Systems

Since logs are already in journald, you can use standard tools to ship them to remote logging systems:

Some log shippers include:

- **Fluent Bit** is a lightweight log processor that can read from journald and forward to various destinations
- **Vector** — High-performance observability data pipeline
- **Promtail** — Loki's log collector with journald support
- **rsyslog** — Traditional syslog with journald input module

### Customizing journald Retention

Configure retention in `/etc/systemd/journald.conf`:

```ini
[Journal]
# Maximum disk space for logs
SystemMaxUse=2G

# Maximum size of individual log files
SystemMaxFileSize=100M

# How long to keep logs
MaxRetentionSec=30day
```

Apply changes with:

```bash
sudo systemctl restart systemd-journald
```

## Docker

Docker's default **json-file** logging driver writes logs to JSON files on disk without automatic rotation, which can cause disk space issues in production.

### Recommended: Configure a Production Logging Driver

For production deployments, configure Docker to use a logging driver with built-in rotation or remote shipping.

#### Option 1: Syslog Driver

Route logs to your system's syslog daemon:

```json
{
  "log-driver": "syslog",
  "log-opts": {
    "syslog-address": "udp://localhost:514",
    "tag": "{{.Name}}"
  }
}
```

#### Option 2: json-file with Rotation

If you prefer local files, enable rotation:

```json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "5"
  }
}
```

#### Option 3: Log Shipping Drivers

Docker includes drivers for shipping logs directly to remote systems:

| Driver | Destination |
|--------|-------------|
| `splunk` | Splunk Enterprise / Splunk Cloud |
| `fluentd` | Fluentd / Fluent Bit collectors |
| `gelf` | Graylog Extended Log Format (Graylog, Logstash) |
| `awslogs` | Amazon CloudWatch Logs |
| `gcplogs` | Google Cloud Logging |

Example Fluentd configuration:

```json
{
  "log-driver": "fluentd",
  "log-opts": {
    "fluentd-address": "fluentd.example.com:24224",
    "tag": "docker.{{.Name}}"
  }
}
```

### Applying Docker Logging Configuration

1. Edit `/etc/docker/daemon.json` with your chosen configuration
2. Restart the Docker daemon:

   ```bash
   sudo systemctl restart docker
   ```

3. Recreate containers to apply the new logging driver:

   ```bash
   docker compose down
   docker compose up -d
   ```

> **Note:** Logging driver changes only apply to newly created containers. Existing containers continue using their original logging configuration until recreated.

### Per-Service Configuration

You can also configure logging per-service using a Docker Compose override file. Create `docker-compose.override.yml` in the `on-prem/` directory—Docker Compose automatically merges this with the main compose file:

```yaml
# on-prem/docker-compose.override.yml
services:
  api:
    logging:
      driver: syslog
      options:
        syslog-address: "udp://localhost:514"
        tag: "currents-api"
```

See the [Docker Compose documentation on merging files](https://docs.docker.com/compose/how-tos/multiple-compose-files/merge/) for more details.

## Further Reading

- [Docker Logging Drivers Documentation](https://docs.docker.com/config/containers/logging/configure/)
- [Podman Logging Documentation](https://docs.podman.io/en/latest/markdown/podman-logs.1.html)
- [Fluent Bit Documentation](https://docs.fluentbit.io/)
- [systemd-journald Documentation](https://www.freedesktop.org/software/systemd/man/journald.conf.html)
