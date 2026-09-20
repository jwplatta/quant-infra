# Environment Setup

## Prerequisites

- Docker Desktop (or Docker Engine + Compose plugin)
- `~/.schwab_rb/` with Schwab API credentials
- `~/.aws/` with AWS credentials (profile: `tickrake`)
- `~/repos/tickrake` cloned locally (dev builds from local source)

## Directory Layout

| | Prod | Dev |
|---|---|---|
| Tickrake home | `~/.tickrake` | `~/.tickrake-dev` |
| Config | `~/.tickrake/tickrake.yml` | `~/.tickrake-dev/tickrake-dev.yml` |
| SQLite | `~/.tickrake/tickrake.sqlite3` | `~/.tickrake-dev/tickrake-dev.sqlite3` |
| Logs | `~/.tickrake/logs/` | `~/.tickrake-dev/logs/` |
| Env file | `envs/prod.env` | `envs/dev.env` |
| Job files | `services/tickrake/jobs/prod/` | `services/tickrake/jobs/dev/` |
| Docker project | `quant-infra-prod` | `quant-infra-dev` |

## Isolation

Dev and prod are completely isolated. They share no volumes, networks, databases, or config.

| Service | Dev Port | Prod Port |
|---------|----------|-----------|
| Grafana | 3001 | 3000 |
| MLflow | 5001 | 5000 |
| Postgres | 5433 | 5432 |
| MinIO API | 9002 | 9000 |
| MinIO Console | 9003 | 9001 |

Docker resources (volumes, networks, containers) are namespaced by project name (`quant-infra-dev` vs `quant-infra-prod`).

## Environment Files

Copy the examples and fill in your values:

```sh
cp envs/example.env envs/dev.env
cp envs/example.env envs/prod.env
cp envs/secrets.example.env envs/secrets.env
```

`envs/secrets.env`, `envs/dev.env`, and `envs/prod.env` are gitignored.

## Running the Dev Environment

```sh
# Build images (tickrake from local ~/repos/tickrake, mlflow with psycopg2)
make dev-build

# Start all dev-profiled services
make dev-up

# Check status
make dev-ps

# Tail logs
make dev-logs

# Stop everything
make dev-down

# Run a single service
make dev-run JOB=futures_candles

# Rebuild without cache
make dev-build-no-cache
```

## Services

All services run in both dev and prod unless noted.

| Service | Description |
|---------|-------------|
| **postgres** | Shared PostgreSQL 17 cluster with `mlflow`, `grafana`, and `tickrake` databases |
| **mlflow** | Experiment tracking server backed by Postgres |
| **grafana** | Dashboards and alerting backed by Postgres |
| **prometheus** | Container metrics (scrapes cAdvisor) |
| **loki** | Log aggregation |
| **promtail** | Ships tickrake logs to Loki |
| **cadvisor** | Container resource metrics |
| **minio** | S3-compatible object store for intraday data |
| **futures_candles** | Tickrake job: futures candle collection |
| **reconciler** | Tickrake job: daily data reconciliation |

## Postgres

Connect to the dev cluster:

```sh
psql -h localhost -p 5433 -U postgres
```

Password: `postgres`. List databases with `\l`, connect with `\c mlflow`, list tables with `\dt`.

Databases and users are created automatically on first start via `services/postgres/init/01-create-databases.sql`. Schema migrations for Grafana and MLflow run automatically on their first connection.

## Adding a Tickrake Job to Dev

1. Create a job file in `services/tickrake/jobs/dev/`.

2. Add `dev` to the service's profiles in `services/tickrake/compose.yml`:

   ```yaml
   my_new_job:
     <<: *tickrake-base
     profiles: [dev, prod]  # add dev here
     environment:
       TICKRAKE_JOB_FILE: /jobs/prod/my_new_job.rb
   ```

3. Override the job file path and volumes in `deploy/dev.yml`:

   ```yaml
   my_new_job:
     environment:
       TICKRAKE_JOB_FILE: /jobs/dev/my_new_job.rb
     volumes:
       - ./services/tickrake/jobs:/jobs:ro
       - ~/.tickrake-dev:/root/.tickrake-dev
       - ~/.schwab_rb:/root/.schwab_rb
       - ~/.aws:/root/.aws:ro
   ```

4. `make dev-up` to start it.

## Building Tickrake

Dev builds from local source, prod builds from GitHub:

| | Build Context |
|---|---|
| Dev | `~/repos/tickrake` (local) |
| Prod | `https://github.com/jwplatta/tickrake.git#main` |

To rebuild after local tickrake changes:

```sh
make dev-build
make dev-restart
```

## Compose Architecture

The environment is assembled from multiple compose files using `-f` flags:

```
services/postgres/compose.yml      # shared database
services/tickrake/compose.yml      # all tickrake jobs (YAML anchor for DRY config)
services/mlflow/compose.yml        # experiment tracking
services/monitoring/compose.yml    # grafana, prometheus, loki, promtail, cadvisor
services/minio/compose.yml         # S3-compatible object store
deploy/dev.yml                     # dev overrides (ports, volumes, build context)
deploy/prod.yml                    # prod overrides
```

Each service compose file defines base config. The deploy overlays add environment-specific ports, volumes, and build contexts. Profiles (`[dev]`, `[prod]`, `[dev, prod]`) control which services start per environment.

The Makefile wires it all together so you only need `make dev-up` / `make prod-up`.
