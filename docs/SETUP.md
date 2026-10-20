# Environment Setup

This repository runs the local quant research platform with Docker Compose.
Use the Makefile targets so each profile gets the intended Compose files,
project name, environment, and service set. Production is a live environment;
inspect the exact targets before changing running services.

## Prerequisites and environment files

- Docker Desktop or Docker Engine with Compose v2
- A local `~/repos/tickrake` checkout for development image builds
- User-level `~/.aws/` credentials for the `tickrake` AWS profile
- User-level `~/.schwab_rb/` credentials for Schwab collection jobs

Create local environment files from the tracked examples:

```sh
cp envs/example.env envs/dev.env
cp envs/example.env envs/prod.env
cp envs/secrets.example.env envs/secrets.env
```

These files are ignored by Git. Put provider credentials and `PGPASSWORD` in
`envs/secrets.env`; keep ordinary runtime settings in `envs/dev.env` and
`envs/prod.env`. The examples include the Tickrake home/config paths, AWS
profile and region, and the Iceberg bucket setting. Never copy user credential
directories into the repository.

Production Tickrake config explicitly selects PostgreSQL at host `postgres`,
database `tickrake`, role `tickrake_user`. Development config uses its own
Tickrake home and SQLite state. Compose mounts versioned Tickrake configuration
read-only from `services/tickrake/config/${ENV}`.

## Profiles

| Profile | Start command | Services included |
| --- | --- | --- |
| Research | `make research-up` | PostgreSQL and MLflow only, using the production Compose project and ports. |
| Data ingestion | `make data-ingestion-up` | Production Tickrake collection, PostgreSQL, MinIO, and collection observability. |
| Production | `make prod-up` | Full production Compose profile, including Tickrake, Tractatus publisher, observability, PostgreSQL, and MinIO. |

The current Makefile does not expose a dev profile or dev targets. The
Options Monitor Compose service is marked `dev` only, but there is no dev
overlay in this checkout. Research and data-ingestion use the production
project name and its volumes, so stop the active profile before switching
modes. Production commands can affect live collection services. Never stop
or recreate Tickrake jobs without explicit operational approval.

Common status and log commands use the same profile prefix, for example
`make dev-ps`, `make research-logs`, `make data-ingestion-ps`, and
`make prod-publisher-logs`. See `make` targets in the repository Makefile for
the complete command set. Host ports are defined in `deploy/dev.yml` and
`deploy/prod.yml`; the production MLflow port is 5005 on this machine.

## MinIO buckets

MinIO uses the host directory `/Users/jplatta/minio-data` for object storage.
The `minio_init` service creates these buckets idempotently when the service
starts:

- `tickrake-intraday`: intraday publication for consumers such as Options Monitor.
- `tickrake-staging`: completed Tickrake files for Tractatus publication.
- `tractatus-lakehouse`: local cache written by Tractatus and read by Options Monitor.

MinIO is local staging and cache storage. The durable historical lakehouse is
AWS S3 with Iceberg tables registered in Glue; the MinIO cache is not a second
authoritative catalog.

## Starting profiles

Start research services without collection:

```sh
make research-up
make research-ps
```

For production, review the services first, then use the production targets:

```sh
make prod-ps
make prod-build
make prod-up
```

`make data-ingestion-up` runs the production ingestion subset. It still uses
the production Tickrake configuration and persistent state.

## Tickrake staging and Tractatus publication

The weekday Tickrake staging job runs at 16:05 America/Chicago. It uploads
supported completed dataset files to `tickrake-staging` and deletes each local
file only after a successful upload. The subsequent Tractatus scheduler runs
at 16:15 America/Chicago, reads from that MinIO bucket, normalizes the data,
appends through the AWS Glue/Iceberg catalog, records publication state in the
`tractatus` PostgreSQL database, and caches output to `tractatus-lakehouse`.

The scheduler receives an inclusive `--after 2026-10-01` lower bound from its
Compose command. A one-off bounded publication can pass the same date filters
and an optional limit:

```sh
make prod-publish AFTER=2026-10-01 BEFORE=2026-10-15 LIMIT=20
```

`--after` includes the specified date and `--before` excludes it. Omitted
Makefile variables are not passed to the CLI. Do not run publication as part
of setup; inspect its current schedule and logs first.

The Tractatus ledger is separate from Glue catalog state and MinIO objects.
When investigating a publication, verify the source object, ledger entry,
Glue/Iceberg table state, and cache independently. Tickrake's stream writer
currently puts pending event files under `~/.tickrake/staging/pending_events`,
which the staging publisher does not scan. See the
[staging-path note](notes/tickrake_streaming_staging_path.md) before assuming
streaming Level One or order-book files reached MinIO.

### Tractatus PostgreSQL setup

New PostgreSQL volumes create the `tractatus` database and `tractatus_user`
through `services/postgres/init/02-create-catalog-tables.sql`. For an existing
volume, `make prod-catalog-db-setup` runs
`scripts/setup_tractatus_database.sql` against the PostgreSQL container. The
publisher creates its `catalog_files` ledger table when it connects.

The publisher uses AWS credentials from the mounted `~/.aws` directory and
the `tickrake` profile/region settings. Its logs are written under
`~/.tractatus/logs/` and shipped to Loki by Alloy.

## Service and configuration layout

```text
services/
  tickrake/       Jobs and versioned dev/prod Tickrake configuration
  postgres/       PostgreSQL service and initialization scripts
  minio/          Local S3-compatible staging and cache storage
  tractatus/      Scheduled publisher wrapper
  options-monitor/ Dashboard Compose definition (dev profile)
  mlflow/         Experiment tracking service
  monitoring/     Grafana, Prometheus, Loki, Alloy, storage metrics exporter
  docker-stats-exporter/ Host Docker metrics exporter
deploy/
  dev.yml         Development overrides
  prod.yml        Production overrides
envs/              Ignored local environment and credentials files
docs/              Setup, architecture, ADRs, plans, and operational notes
```

The Makefile composes service definitions with `deploy/dev.yml` or
`deploy/prod.yml`. Research projects live outside this repository and consume
published data through their own data-access workflows.
