# Currents Self-Hosted Documentation (Docker Compose)

Hosted versions of the docs can be viewed at https://currents-dev.github.io/docker/

Currents on-premise installation using Docker Compose provides a containerized deployment for running Currents services on a single host or small-scale infrastructure.

The Docker Compose configuration is modular, allowing you to choose which data services to run locally versus connecting to external managed services.

## Resources

- [🚀 Quickstart Guide](./quickstart.md)
- [Container Image Access](./container-images.md)
- [Configuration Reference](./configuration.md)
- [Upgrading Currents On-Prem](./upgrading.md)
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
