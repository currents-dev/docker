# Currents Self-Hosted Documentation (Docker Compose)

Currents on-premise installation using Docker Compose provides a containerized deployment for running Currents services on a single host or small-scale infrastructure.

The Docker Compose configuration is modular, allowing you to choose which data services to run locally versus connecting to external managed services.

## Resources

- [🚀 Quickstart Guide](./quickstart.md)
- [Configuration Reference](./configuration.md)
- [Support Policy](./support.md)

## Additional Resources

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Podman Documentation](https://docs.podman.io/)

## Upstream Services

- The self-hosted solution requires an existing Identity Provider for access provisioning.
- The recommended configuration for the stateful services (MongoDB, ClickHouse, Redis) may not be adequate for all production loads.
- Currents team doesn't provide support for the upstream services (MongoDB, ClickHouse, Redis), see [Support Policy](./support.md).

## Known Limitations

The following features are not fully available for self-hosted version. If you need them let us know in advance:

- Code coverage collection and reporting
- Bitbucket and MS Teams integrations are still WIP
