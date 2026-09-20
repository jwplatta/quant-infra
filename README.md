# Quant Infra

Docker Compose infrastructure for data collection, local research services, and operational visibility. It is the runtime environment around the research workflow.

## What runs here

- **Tickrake jobs** collect and publish market data. Each job runs in its own container.
- **PostgreSQL** provides separate `tickrake`, `mlflow`, and `grafana` databases.
- **MLflow** records experiments and model artifacts for research projects.
- **MinIO** is a local S3-compatible store for intraday data.
- **Grafana, Prometheus, Loki, Promtail, and cAdvisor** provide dashboards, metrics, and logs for the running stack.
- **Options Monitor** is the intraday trading dashboard. It reads Tickrake data through the local runtime interfaces.

Research repositories consume the published data and use MLflow; they do not live in this repository.

## Profiles

| Profile | Command | Starts |
| --- | --- | --- |
| Dev | `make dev-up` | The dev infrastructure plus `futures_candles` and `reconciler`, using local Tickrake source and isolated dev state. |
| Research | `make research-up` | Only PostgreSQL and MLflow. Use this for experiment tracking without data collection or monitoring. |
| Production | `make prod-up` | The complete stack: infrastructure, observability, and all production Tickrake jobs. |

`research` uses the production project, volumes, and ports (Postgres `5432`, MLflow `5000`). Stop the active profile before switching modes: `make research-down` or `make prod-down`.

## Quick start

Prerequisites:

- Docker Desktop with Compose v2
- A local Tickrake checkout at `~/repos/tickrake` for the dev profile
- `~/.schwab_rb/` and `~/.aws/` credentials for Tickrake jobs

Create the ignored environment files once:

```sh
cp envs/example.env envs/dev.env
cp envs/example.env envs/prod.env
cp envs/secrets.example.env envs/secrets.env
```

Start the smallest research stack:

```sh
make research-up
make research-ps
```

Start development or the full production stack:

```sh
make dev-build && make dev-up
make prod-build && make prod-up
```

## Common commands

| Purpose | Dev | Research | Production |
| --- | --- | --- | --- |
| Start | `make dev-up` | `make research-up` | `make prod-up` |
| Stop | `make dev-down` | `make research-down` | `make prod-down` |
| Status | `make dev-ps` | `make research-ps` | `make prod-ps` |
| Logs | `make dev-logs` | `make research-logs` | `make prod-logs` |
| Restart | `make dev-restart` | `make research-restart` | `make prod-restart` |

Build commands are available for the dev and production profiles: `make dev-build`, `make prod-build`, and their `-no-cache` variants. Start one Tickrake service explicitly with `make dev-run JOB=futures_candles` or `make prod-run JOB=spx_0dte_options`.

## Layout

```text
services/
  tickrake/       Tickrake image configuration and dev/prod job definitions
  postgres/       PostgreSQL service and database initialization
  mlflow/         MLflow image and server configuration
  minio/          Local S3-compatible storage
  monitoring/     Grafana, Prometheus, Loki, Promtail, and cAdvisor
  options-monitor/ Intraday trading dashboard Compose definition
deploy/
  dev.yml         Dev ports, local Tickrake build, and dev home/config mounts
  prod.yml        Production ports, remote Tickrake build, and prod mounts
envs/              Ignored local environment and secrets files; tracked examples
scripts/           One-off maintenance and validation scripts
docs/              Setup notes and architecture diagram
```

Each service owns its base Compose definition. `deploy/dev.yml` and `deploy/prod.yml` are overlays for environment-specific ports, volumes, and build contexts; the Makefile combines them with the appropriate Compose profile.

## Service access

| Service | Dev | Production / Research |
| --- | --- | --- |
| PostgreSQL | `localhost:5433` | `localhost:5432` |
| MLflow | `http://localhost:5001` | `http://localhost:5000` |
| Options Monitor | `http://localhost:8504` | `http://localhost:8503` |
| Grafana | `http://localhost:3001` | `http://localhost:3000` |
| MinIO API | `localhost:9002` | `localhost:9000` |
| MinIO console | `http://localhost:9003` | `http://localhost:9001` |

Grafana and MinIO are not part of the research profile.

## Options Monitor

Options Monitor is the user-facing intraday trading dashboard. It is enabled in both dev and production, starts with the rest of those profiles, and depends on MinIO. It reads the `tickrake-intraday` bucket from MinIO and has read-only access to the matching Tickrake home and AWS credentials.

Both profiles build from `https://github.com/jwplatta/options_monitor.git#main`. Dev is available on port `8504`; production is available on port `8503`. The dashboard should rely on its published-data interfaces rather than assume Tickrake's on-disk storage layout is a permanent contract.

## Tickrake jobs

The production profile runs the stock, ETF, SPX options, equity Level 1/order-book, futures candles, ingestion, metadata, publishing, and reconciliation jobs. The dev profile intentionally limits this to `futures_candles` and `reconciler`.

To add a job to dev, place its dev definition under `services/tickrake/jobs/dev/`, add `dev` to its service profile in `services/tickrake/compose.yml`, and override its file path and mounts in `deploy/dev.yml`. See [docs/SETUP.md](docs/SETUP.md) for the complete example.

## Data and operational boundaries

Tickrake publishes durable market-data outputs; this repository supplies its runtime dependencies and observability. MLflow records research metadata and artifacts. Keep credentials in the ignored `envs/*.env` files and user-level credential directories, never in Compose files or committed configuration.

For environment details, database access, and the full Compose composition, see [docs/SETUP.md](docs/SETUP.md). The system relationships are shown in [docs/architecture-diagram.md](docs/architecture-diagram.md).
