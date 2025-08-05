# High Availability PostgreSQL Cluster

A production-ready PostgreSQL high availability cluster using Patroni, Consul, and PgPool2, all orchestrated with Docker Compose.

## Architecture

This setup provides:

- **High Availability**: Automatic failover using Patroni
- **Service Discovery**: Consul as distributed configuration store
- **Load Balancing**: PgPool2 for connection pooling and read/write splitting
- **Monitoring**: Health checks and status endpoints

## Components

| Service    | Description                                | Ports                         |
| ---------- | ------------------------------------------ | ----------------------------- |
| **Consul** | Service discovery and configuration store  | 8500 (UI), 8600 (DNS)         |
| **db1**    | Primary PostgreSQL instance with Patroni   | 5433 (PostgreSQL), 8001 (API) |
| **db2**    | Secondary PostgreSQL instance with Patroni | 5434 (PostgreSQL), 8002 (API) |
| **pgpool** | Connection pooler and load balancer        | 5432 (PostgreSQL)             |

## Quick Start

### 1. Clone and Setup

```bash
git clone <repository-url>
cd ha-postgres
cp .env.example .env
```

### 2. Configure Environment

Edit `.env` file with your preferred passwords:

```bash
# Example configuration - use strong passwords in production
POSTGRES_SUPERUSER_PASSWORD=your_secure_password
PATRONI_SUPERUSER_PASSWORD=your_secure_password
REPLICATION_PASSWORD=your_replication_password
PATRONI_REPLICATION_PASSWORD=your_replication_password
PGPOOL_SR_CHECK_PASSWORD=your_secure_password
PGPOOL_POSTGRES_PASSWORD=your_secure_password
```

### 3. Start the Cluster

```bash
docker-compose up -d
```

### 4. Verify the Setup

Check cluster status:

```bash
# Check Patroni cluster status
curl http://localhost:8001/cluster
curl http://localhost:8002/cluster

# Check Consul UI
open http://localhost:8500
```

## Usage

### Connecting to PostgreSQL

**Production Connection (via PgPool):**

```bash
psql -h localhost -p 5432 -U postgres
```

**Direct Connections (for debugging):**

```bash
# Primary instance
psql -h localhost -p 5433 -U postgres

# Secondary instance
psql -h localhost -p 5434 -U postgres
```

### Monitoring and Management

**Patroni REST API:**

```bash
# Check cluster status
curl http://localhost:8001/cluster

# Check primary status
curl http://localhost:8001/primary

# Check replica status
curl http://localhost:8002/replica
```

**Consul Web UI:**

- URL: <http://localhost:8500>
- Monitor service health and configuration

## High Availability Features

### Automatic Failover

If the primary database fails:

1. Patroni detects the failure
2. Promotes a healthy replica to primary
3. Updates Consul with new topology
4. PgPool2 automatically redirects traffic

### Manual Switchover

```bash
# Switchover to make db2 the new primary
curl -s http://localhost:8001/switchover -XPOST -d '{"leader":"db2"}'
```

### Adding a New Replica

To add a third PostgreSQL instance, update `docker-compose.yml`:

```yaml
db3:
  build: db/
  container_name: db3
  env_file:
    - .env
  environment:
    PATRONI_NAME: db3
  volumes:
    - db3_data:/home/patroni/pgdata
  ports:
    - "5435:5432"
    - "8003:8008"
  depends_on:
    - consul
  restart: unless-stopped
```

## Configuration

### Consul Configuration

Consul serves as the distributed configuration store and service discovery system for the PostgreSQL cluster. The configuration in `consul/consul.json` includes:

**Core Settings:**

- `datacenter`: "dc1" - Logical grouping of Consul nodes
- `data_dir`: "/consul/data" - Persistent storage location for Consul data
- `bind_addr`: "0.0.0.0" - Address Consul binds to for cluster communication
- `client_addr`: "0.0.0.0" - Address clients use to connect to Consul
- `server`: true - Runs Consul in server mode (vs agent mode)
- `bootstrap_expect`: 1 - Number of servers to wait for before bootstrapping (single-node setup)

**UI and API:**

- `ui_config.enabled`: true - Enables the Consul web UI at http://localhost:8500
- `ports.grpc`: 8502 - gRPC port for modern Consul features

**Service Mesh and Health Checks:**

- `connect.enabled`: true - Enables Consul Connect service mesh features
- `enable_script_checks`: true - Allows health check scripts
- `enable_local_script_checks`: true - Allows local script execution for health checks

**Security and Performance:**

- `disable_remote_exec`: true - Security best practice (disables remote execution)
- `acl.enabled`: false - ACLs disabled for development (enable in production)
- `acl.default_policy`: "allow" - Permissive policy for development
- `performance.raft_multiplier`: 1 - Optimizes Raft consensus performance
- `log_level`: "INFO" - Appropriate logging level for monitoring

**Production Considerations:**

- For production, enable ACLs by setting `acl.enabled: true`
- Consider adding encryption with `encrypt` and `ca_file` settings
- Use `retry_join` to connect multiple Consul servers in a cluster

### PostgreSQL Settings

The cluster is configured with production-ready PostgreSQL settings in `db/patroni-template.yml`:

- Connection pooling optimized
- Comprehensive logging enabled
- Replication configured
- Checksums enabled for data integrity

### Security Considerations

⚠️ **Important Security Notes:**

1. **Change Default Passwords**: Never use default passwords in production
2. **Use Secrets Management**: Consider Docker secrets or external secret managers
3. **Network Security**: Restrict network access in production
4. **SSL/TLS**: Enable SSL for all connections in production

### Production Deployment

For production use:

1. **Use Docker Secrets:**

```yaml
secrets:
  postgres_password:
    external: true
```

2. **Configure SSL/TLS:**

```yaml
# Add SSL certificates to patroni-template.yml
ssl: "on"
ssl_cert_file: "/path/to/cert.pem"
ssl_key_file: "/path/to/key.pem"
```

3. **Resource Limits:**

```yaml
deploy:
  resources:
    limits:
      memory: 2G
      cpus: "1.0"
```

## Backup and Recovery

### Continuous Archiving

Configure WAL archiving in `patroni-template.yml`:

```yaml
postgresql:
  parameters:
    archive_mode: "on"
    archive_command: "cp %p /backup/wal/%f"
```

### Point-in-Time Recovery

```bash
# Create base backup
pg_basebackup -h localhost -p 5432 -U postgres -D /backup/base

# Restore from backup
# (Detailed PITR steps depend on your backup strategy)
```

## Troubleshooting

### Common Issues

**Cluster won't start:**

```bash
# Check logs
docker-compose logs consul
docker-compose logs db1
docker-compose logs db2
```

**Split-brain scenario:**

```bash
# Check cluster status
curl http://localhost:8001/cluster
curl http://localhost:8002/cluster

# Reinitialize replica if needed
curl -s http://localhost:8002/reinitialize -XPOST
```

**Connection issues:**

```bash
# Test PgPool connection
telnet localhost 5432

# Check PgPool status
docker-compose exec pgpool pcp_node_info -h localhost -p 9898 -U postgres
```

### Logs

View service logs:

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f db1
docker-compose logs -f pgpool
docker-compose logs -f consul
```

## Development

### Project Structure

```
ha-postgres/
├── consul/
│   └── consul.json          # Consul configuration
├── db/
│   ├── Dockerfile           # PostgreSQL + Patroni image
│   ├── patroni-template.yml # Patroni configuration template
│   └── entrypoint.sh        # Container startup script
├── docker-compose.yml       # Service orchestration
├── .env                     # Environment variables (not in git)
├── .env.example            # Environment template
├── .gitignore              # Git ignore rules
└── README.md               # This file
```

### Testing Changes

```bash
# Rebuild and restart
docker-compose down
docker-compose build --no-cache
docker-compose up -d

# Test failover
docker-compose stop db1
# Verify db2 becomes primary
curl http://localhost:8002/primary
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License.

## Support

For issues and questions:

- Check the troubleshooting section
- Review logs for error messages
- Open an issue in the repository
