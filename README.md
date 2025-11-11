# Spilo PostgreSQL with Custom Extensions

Custom [Zalando Spilo](https://github.com/zalando/spilo) PostgreSQL 17 Docker image with [pg_uuidv7](https://github.com/fboulnois/pg_uuidv7) and [pg_partman](https://github.com/pgpartman/pg_partman) extensions pre-installed.

## Overview

This project builds a custom Spilo image that extends the official Zalando Spilo PostgreSQL 17 image with additional PostgreSQL extensions. Spilo is a highly available PostgreSQL cluster solution using Patroni, designed for cloud environments and Kubernetes.

## Features

- **Base Image**: Zalando Spilo PostgreSQL 17 (version 4.0-p2)
- **Extensions**:
  - pg_uuidv7 for generating UUID v7 identifiers
  - pg_partman for native table partitioning management
- **Multi-Architecture**: Supports both `linux/amd64` and `linux/arm64`
- **Automated Builds**: GitHub Actions workflow for CI/CD

## Extensions

### pg_uuidv7

[pg_uuidv7](https://github.com/fboulnois/pg_uuidv7) is a PostgreSQL extension that provides UUID v7 generation. UUID v7 is a time-ordered UUID format that:

- Contains a Unix timestamp for better database indexing performance
- Maintains lexicographical sortability
- Reduces index fragmentation compared to random UUIDs (v4)
- Improves query performance on indexed UUID columns

### pg_partman

[pg_partman](https://github.com/pgpartman/pg_partman) is an extension to help manage time-based and serial-based table partition sets. Features include:

- Automatic partition creation and management
- Support for native PostgreSQL partitioning (declarative partitioning)
- Time-based and serial-based partitioning strategies
- Automatic partition maintenance and retention management
- Sub-partitioning support
- Undo partitioning capabilities

## Usage

### Pull the Image

```bash
docker pull ghcr.io/YOUR_USERNAME/spilo-extensions:latest
```

### Using in Kubernetes with Zalando Postgres Operator

```yaml
apiVersion: "acid.zalan.do/v1"
kind: "postgresql"
metadata:
  name: "my-postgres-cluster"
spec:
  teamId: "myteam"
  numberOfInstances: 2
  dockerImage: ghcr.io/YOUR_USERNAME/spilo-extensions:17-4.0-p2
  postgresql:
    version: "17"
  preparedDatabases:
    mydb:
      extensions:
        pg_uuidv7: public
        pg_partman: public
  volume:
    size: "10Gi"
```

### Enabling the Extensions

Once your PostgreSQL cluster is running, connect to your database and enable the extensions:

```sql
CREATE EXTENSION IF NOT EXISTS pg_uuidv7;
CREATE EXTENSION IF NOT EXISTS pg_partman;
```

### Using UUID v7

```sql
-- Generate a new UUID v7
SELECT uuid_generate_v7();

-- Use in a table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v7(),
    username TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert data
INSERT INTO users (username) VALUES ('alice');

-- UUID v7 IDs are time-ordered
SELECT id, username FROM users ORDER BY id;
```

### Using pg_partman

```sql
-- Create a parent table with native partitioning
CREATE TABLE events (
    id BIGSERIAL,
    event_time TIMESTAMPTZ NOT NULL,
    event_data JSONB,
    PRIMARY KEY (id, event_time)
) PARTITION BY RANGE (event_time);

-- Set up pg_partman to manage partitions
SELECT partman.create_parent(
    p_parent_table => 'public.events',
    p_control => 'event_time',
    p_type => 'native',
    p_interval => 'daily',
    p_premake => 7
);

-- Update partition configuration
UPDATE partman.part_config 
SET infinite_time_partitions = true,
    retention = '30 days',
    retention_keep_table = false
WHERE parent_table = 'public.events';

-- Schedule partition maintenance (run this periodically via cron or pg_cron)
SELECT partman.run_maintenance_proc();
```

## Building Locally

### Prerequisites

- Docker with buildx support
- Git

### Build Command

```bash
docker buildx build -t spilo-extensions:local .
```

### Multi-Architecture Build

```bash
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t spilo-extensions:local \
  .
```

## GitHub Actions Workflow

This repository includes a GitHub Actions workflow that automatically:

1. Builds the Docker image on push to `main`/`master` or on version tags
2. Publishes to GitHub Container Registry (ghcr.io)
3. Supports multi-architecture builds (amd64, arm64)
4. Generates appropriate tags:
   - Branch names for branch pushes
   - Semantic versions for tags (e.g., `1.0.0`, `1.0`, `1`)
   - Git SHA for every build

### Triggering a Build

```bash
# Push to main branch
git push origin main

# Create and push a version tag
git tag 17-4.0-p2
git push origin 17-4.0-p2
```

## Customization

To modify the Spilo version or add additional extensions:

1. Edit the `SPILO_VERSION` ARG in the Dockerfile
2. Add additional extension installation steps in the RUN command
3. Rebuild the image

```dockerfile
ARG SPILO_VERSION=4.0-p2  # Change this to update Spilo version
```

## Included Files

- `Dockerfile` - Image definition
- `.github/workflows/build-and-push.yml` - CI/CD workflow
- `.dockerignore` - Files excluded from build context

## Version Matrix

| Spilo Version | PostgreSQL Version | pg_uuidv7 Version | pg_partman Version |
| ------------- | ------------------ | ----------------- | ------------------ |
| 4.0-p2        | 17                 | latest (main)     | latest (master)    |

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## License

This project follows the same license as the upstream projects it builds upon.

## Related Projects

- [Zalando Spilo](https://github.com/zalando/spilo) - High availability PostgreSQL with Patroni
- [pg_uuidv7](https://github.com/fboulnois/pg_uuidv7) - PostgreSQL UUID v7 extension
- [pg_partman](https://github.com/pgpartman/pg_partman) - PostgreSQL partition manager
- [Zalando Postgres Operator](https://github.com/zalando/postgres-operator) - Kubernetes operator for PostgreSQL

## Support

For issues related to:

- **This custom image**: Open an issue in this repository
- **Spilo**: See [Zalando Spilo issues](https://github.com/zalando/spilo/issues)
- **pg_uuidv7**: See [pg_uuidv7 issues](https://github.com/fboulnois/pg_uuidv7/issues)
- **pg_partman**: See [pg_partman issues](https://github.com/pgpartman/pg_partman/issues)
