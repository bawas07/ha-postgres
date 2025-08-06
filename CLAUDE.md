# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

### Docker Compose
- Start the cluster: `docker-compose up -d`
- Stop the cluster: `docker-compose down`
- View logs: `docker-compose logs -f [service]`
- Rebuild and restart: `docker-compose down && docker-compose build --no-cache && docker-compose up -d`

### PostgreSQL
- Connect via PgPool: `psql -h localhost -p 5432 -U postgres`
- Direct connection to primary: `psql -h localhost -p 5433 -U postgres`
- Direct connection to replica: `psql -h localhost -p 5434 -U postgres`

### Patroni API
- Check cluster status: `curl http://localhost:8001/cluster`
- Check primary status: `curl http://localhost:8001/primary`
- Check replica status: `curl http://localhost:8002/replica`
- Manual switchover: `curl -s http://localhost:8001/switchover -XPOST -d '{"leader":"db2"}'`

### Consul
- Web UI: `open http://localhost:8500`

## Architecture

### Components
- **Consul**: Service discovery and distributed configuration store.
- **Patroni**: Manages PostgreSQL high availability and failover.
- **PgPool2**: Connection pooling and load balancing.
- **PostgreSQL**: Primary and replica instances.

### Key Features
- Automatic failover via Patroni.
- Service discovery via Consul.
- Load balancing and read/write splitting via PgPool2.

### Configuration
- Environment variables in `.env`.
- Consul settings in `consul/consul.json`.
- PostgreSQL and Patroni settings in `db/patroni-template.yml`.

### Security
- Ensure `.env` passwords are strong and secure.
- Enable SSL/TLS for production deployments.
- Use Docker secrets for sensitive data in production.

### Monitoring
- Consul UI for service health.
- Patroni API for cluster status.
- Docker logs for troubleshooting.

### Backup and Recovery
- Configure WAL archiving in `patroni-template.yml`.
- Use `pg_basebackup` for base backups.

### Development
- Project structure follows standard Docker Compose layout.
- Test changes by rebuilding and restarting the cluster.
- Simulate failover by stopping the primary instance (`docker-compose stop db1`).