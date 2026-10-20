# Quant Infra

Docker Compose runtime and integration wiring for the local quantitative research platform. This repository configures collection services, storage, research infrastructure, publication, and observability; the applications and data clients remain in their own repositories.

## System overview

- **Tickrake** collects market and reference data from independent providers, processes streams, compacts completed datasets, and tracks collection state. Schwab integrations use `schwab_rb`; IBKR and other providers connect through their own adapters.
- **Tractatus** reads completed Tickrake data from MinIO staging, normalizes it, and appends it through the AWS Glue catalog to Iceberg tables. Its PostgreSQL ledger records publication state.
- **AWS S3 with Glue/Iceberg** is the durable historical lakehouse and catalog boundary. The Tractatus ledger, S3 object presence, and Iceberg snapshot membership are distinct facts and must be checked separately during recovery.
- **MinIO** provides the local `tickrake-intraday`, `tickrake-staging`, and `tractatus-lakehouse` buckets. Staging is a publication input; the latter bucket is a local Tractatus cache. Neither replaces the authoritative Glue/Iceberg lakehouse.
- **PostgreSQL** backs Tickrake state, the Tractatus publication ledger, MLflow metadata, and Grafana metadata in the configured production stack.
- **MLflow** tracks research experiments and artifacts. **Grafana, Prometheus, Loki, Alloy, and the Docker/MinIO metrics exporters** provide operational visibility.
- **Options Monitor** is a separate Streamlit consumer. Its Compose definition is dev-profiled and configured for MinIO data; verify the active consumer path before assuming historical lakehouse integration is live.

Research applications and strategy code live outside this repository. See [docs/architecture.md](docs/architecture.md) for the system architecture and [docs/architecture-diagram.md](docs/architecture-diagram.md) for its diagram.

## Compose profiles

The Makefile currently exposes research, data-ingestion, and production commands. There is no `make dev-*` target or `deploy/dev.yml` overlay in the current checkout. Research and data-ingestion are profiles of the `quant-infra-prod` Compose project, so they share its project identity, named volumes, and configured host ports with production. Inspect the effective targets before switching profiles.

| Profile | Commands | Starts |
| --- | --- | --- |
| Research | `make research-up`, `make research-ps` | PostgreSQL and MLflow, without collection or monitoring services. |
| Data ingestion | `make data-ingestion-up`, `make data-ingestion-ps` | PostgreSQL, Tickrake collection, MinIO, and collection observability; no MLflow, Grafana, or Options Monitor. |
| Production | `make prod-up`, `make prod-ps` | The full configured production stack, including collection, MinIO, Tractatus publisher, research services, and observability. Treat it as live. |

`make prod-scrapers-up` starts only the configured scraper services with `--no-deps`; it does not bring up the complete production stack. Avoid broad profile switching on a live host. The repository guidance in [AGENTS.md](AGENTS.md) describes operational boundaries.

## Quick start

Prerequisites: Docker Desktop with Compose v2 and the user-level credentials needed by the services you intend to run.

Create ignored environment files as needed:

```sh
cp envs/example.env envs/prod.env
cp envs/secrets.example.env envs/secrets.env
```

Start the research services:

```sh
make research-up
make research-ps
```

Production is live and may start data collection and scheduled publishing. Review the Compose configuration and setup guide before running `make prod-up`. For setup, database access, and publisher commands, see [docs/SETUP.md](docs/SETUP.md).

## Data publication flow

Tickrake's production staging job is scheduled for weekdays at 16:05 and uploads supported completed data files to the `tickrake-staging` MinIO bucket. Tractatus is scheduled at 16:15 America/Chicago every calendar day. It reads staging, normalizes eligible files, appends them through Glue/Iceberg, updates its PostgreSQL ledger, and maintains the `tractatus-lakehouse` MinIO cache. A manual publication can be run with optional date bounds, for example:

```sh
make prod-publish AFTER=2026-10-01 BEFORE=2026-10-02 LIMIT=20
```

The bounds are inclusive `AFTER` and exclusive `BEFORE`. The Tractatus publisher command and current configuration are documented in [docs/SETUP.md](docs/SETUP.md). Tickrake's streaming pending-event spool is not currently scanned by the staging publisher, so a stream write or local spool file alone does not establish that it was staged or published.

The separate intraday publication path uses MinIO as configured by Tickrake. Do not infer historical Glue/Iceberg membership from MinIO objects or ledger rows alone.

## Common commands

| Purpose | Research | Data ingestion | Production |
| --- | --- | --- | --- |
| Start | `make research-up` | `make data-ingestion-up` | `make prod-up` |
| Stop profile | `make research-down` | `make data-ingestion-down` | `make prod-down` |
| Status | `make research-ps` | `make data-ingestion-ps` | `make prod-ps` |
| Logs | `make research-logs` | `make data-ingestion-logs` | `make prod-logs` |
| Restart | `make research-restart` | `make data-ingestion-restart` | `make prod-restart` |

Other targeted commands include `make prod-run JOB=<service>`, `make prod-publisher-logs`, and `make prod-catalog-db-setup`. Check the Makefile before use; service availability varies by Compose profile.

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
  tractatus/            Tractatus catalog publisher Compose wiring and scheduler
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

Each service has a base Compose definition under `services/`; `deploy/prod.yml` supplies production-specific settings. The Makefile combines them with the selected Compose profile.
