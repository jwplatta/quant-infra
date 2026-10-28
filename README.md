# Quant Infra

Docker Compose runtime and integration wiring for the local quantitative research platform. This repository configures collection services, storage, research infrastructure, publication, and observability; the applications and data clients remain in their own repositories.

## System overview

- **Tickrake** collects market and reference data from independent providers, processes streams, compacts completed datasets, and tracks collection state. Schwab integrations use `schwab_rb`; IBKR and other providers connect through their own adapters.
- **Tractatus** reads completed Tickrake data from MinIO staging, normalizes it, and publishes Iceberg tables using the local PostgreSQL catalog. Its SQLite `catalog_ledger.db` records publication state.
- **MinIO** provides `tickrake-intraday`, `tickrake-staging`, the `tractatus-iceberg` lakehouse bucket, and the `tractatus-lakehouse` cache bucket. The ledger, object presence, and Iceberg snapshot membership are distinct facts to check during recovery.
- **PostgreSQL** backs Tickrake state, the local Iceberg catalog, and Grafana metadata in the configured production stack.
- **Grafana, Prometheus, Loki, Alloy, and the Docker/MinIO metrics exporters** provide operational visibility. MLflow is currently excluded from the production Compose stack.
- **Options Monitor** is a separate Streamlit consumer. Its Compose definition is not included in the production Makefile and is configured for MinIO data; verify the active consumer path before assuming historical lakehouse integration is live.

Research applications and strategy code live outside this repository. See [docs/architecture.md](docs/architecture.md) for the system architecture and [docs/architecture-diagram.md](docs/architecture-diagram.md) for its diagram.

## Production commands

The Makefile uses the `quant-infra-prod` Compose project. `make prod-up` starts the configured PostgreSQL, Tickrake, MinIO, and monitoring services, including Grafana. MLflow and the scheduled Tractatus publisher are not included in the current Compose file list. Treat production as live; see [AGENTS.md](AGENTS.md) for operational boundaries.

## Quick start

Prerequisites: Docker Desktop with Compose v2 and the user-level credentials needed by the services you intend to run.

Create ignored environment files as needed:

```sh
cp envs/example.env envs/prod.env
cp envs/secrets.example.env envs/secrets.env
```

Start production:

```sh
make prod-up
```

Production starts data collection. Review the Compose configuration and setup guide before running `make prod-up`. For setup and publication commands, see [docs/SETUP.md](docs/SETUP.md).

## Data publication flow

For manual, date-scoped options, level-one, or order-book publication, build the
one-off CLI image with `make publish-script-image` and run the relevant
`make publish-*-day` target. These scripts use the current remote `main`
branches of Tickrake and Tractatus when the image is rebuilt; see the
[one-off publication runbook](docs/notes/one-off-daily-publication.md).

The one-off scripts publish files to Tickrake's `tickrake-staging` bucket, then
use Tractatus to normalize them and write to the `tractatus-iceberg` MinIO
bucket through the PostgreSQL catalog and to the `tractatus-lakehouse` cache.
The current `minio_init` service does not create `tractatus-iceberg`, so that
bucket must exist before publication.
They check CLI results and ledger status before Tickrake purges remote staging
for that date and data type. The CLI date bounds are inclusive
`--after` and exclusive `--before`. Tickrake's streaming pending-event spool is
not scanned by the staging publisher, so a stream write or local spool file
alone does not establish that it was staged or published.

The separate intraday publication path uses MinIO as configured by Tickrake. Do not infer Iceberg snapshot membership from MinIO objects or ledger rows alone.

## Common commands

| Purpose | Command |
| --- | --- |
| Build | `make prod-build` or `make prod-build-no-cache` |
| Start all configured services | `make prod-up` |
| Stop the project | `make prod-down` |
| Restart configured services | `make prod-restart` |
| Start or stop one existing service | `make prod-start SERVICE=grafana` or `make prod-stop SERVICE=grafana` |

Use `docker compose` directly for status and logs. The publication targets remain `make publish-script-image` and `make publish-{options,level-one,order-book}-day DATE=YYYY-MM-DD`. Omit `DATE` to use today's Chicago date.

## Secret scanning

Install the repository hooks after installing [Gitleaks](https://github.com/gitleaks/gitleaks):

```sh
brew install gitleaks
make hooks-install
```

The pre-commit hook scans staged changes. The pre-push hook scans Git history. Run `make secrets-check` for a full scan.

## Repository layout

```text
services/
  tickrake/             Tickrake Compose services, jobs, config, and universes
  publish-lakehouse/    One-off Tickrake and Tractatus CLI image and scripts
  postgres/             PostgreSQL service and database initialization
  mlflow/               MLflow server configuration
  minio/                Local S3-compatible storage and bucket initialization
  monitoring/           Grafana, Prometheus, Loki, Alloy, and storage metrics
  docker-stats-exporter/ Host Docker container-metrics exporter
  options-monitor/      Options Monitor Compose definition
deploy/
  prod.yml              Production mounts, build settings, and port mappings
envs/                   Ignored local environment and secrets files; tracked examples
scripts/                One-off maintenance and validation scripts
docs/                   Setup, architecture, plans, notes, and backlog
```

Each service has a base Compose definition under `services/`; `deploy/prod.yml` supplies production-specific settings. The Makefile selects the production service definitions.
