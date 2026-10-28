# Environment Setup

This repository runs the live `quant-infra-prod` Docker Compose project. The
Makefile starts PostgreSQL, MinIO, Tickrake collection jobs, and monitoring.
Lakehouse publication is a manual, short-lived container run; there is no
scheduled Tractatus publisher in the active Compose stack.

## Prerequisites and local environment

- Docker Desktop or Docker Engine with Compose v2
- The ignored `envs/prod.env`, `envs/tickrake.env`, and `envs/secrets.env` files
- User-level `~/.schwab_rb/` and `~/.aws/` credentials for jobs that require them

Start from the tracked examples where applicable:

```sh
cp envs/example.env envs/prod.env
cp envs/secrets.example.env envs/secrets.env
```

Keep credentials in ignored environment files and user directories. Do not
commit them or copy credential directories into this repository. The
production Tickrake config is `services/tickrake/config/prod/tickrake.yml`;
inside Compose it uses the hostname `postgres` and MinIO at `minio:9000`.

## Production services

The Makefile selects `services/postgres/compose.yml`,
`services/tickrake/compose.yml`, `services/monitoring/compose.yml`,
`services/minio/compose.yml`, and `deploy/prod.yml` with the `prod` profile.
The stack includes Grafana. MLflow, Options Monitor, the Tickrake scheduled
staging job, and a scheduled Tractatus publisher are not active in this stack.

```sh
make prod-build
make prod-up
```

Other supported Make targets are `prod-build-no-cache`, `prod-restart`, and
`prod-down`. To start or stop one **existing** container by Compose service
name, use `make prod-start SERVICE=grafana` or
`make prod-stop SERVICE=grafana`. `prod-start` does not create a missing
container. Check exact targets before broad production operations; do not
restart Tickrake jobs without explicit approval.

For basic status and logs, use Docker directly, for example:

```sh
docker ps --filter label=com.docker.compose.project=quant-infra-prod
docker logs quant-infra-prod-grafana-1
```

Grafana is published on host port 3000, PostgreSQL on 5432, and MinIO on
9000 (API) and 9001 (console).

## Storage and catalog setup

On a new PostgreSQL volume, `services/postgres/init/01-create-databases.sql`
creates the Tickrake and Grafana databases, and
`02-create-tractatus-database.sql` creates the `tractatus` database and role
for the local Iceberg SQL catalog. Docker runs these files only when the
database volume is first initialized. Inspect an existing volume before
applying setup SQL manually.

The `minio_init` service creates `tickrake-intraday`, `tickrake-staging`, and
`tractatus-lakehouse`. Tractatus uses a fourth bucket, `tractatus-iceberg`,
for Iceberg data and metadata. The current `minio_init` does not create that
bucket. In the configured Tractatus environment,
`tractatus catalog init-local` can create the bucket and Iceberg tables; it
also initializes the SQLite publication ledger at
`~/.tractatus/catalog_ledger.db`. The publication script requires this ledger
file before it starts.

The handoff bucket `tickrake-staging` is owned by Tickrake. Tractatus reads
from it, commits to Iceberg using the PostgreSQL catalog, and writes the
`tractatus-lakehouse` cache. The SQLite ledger records per-file publication
state. A staging object, a ledger row, a cache object, and an Iceberg snapshot
are separate evidence when investigating a publish.

## Manual daily publication

Create the ignored `envs/publish-day.env` with the non-secret settings
described in the [publication runbook](notes/one-off-daily-publication.md).
The runner sources it along with `envs/secrets.env`, `envs/tickrake.env`, and
`envs/prod.env`. It joins the production Docker network, mounts local
`~/.tickrake/data` read-only, and writes logs under `tmp/logs/`.

Build Tickrake and Tractatus from their remote `main` branches, then run one
dataset and sample date at a time:

```sh
make publish-script-image
make publish-options-day DATE=2026-10-26
make publish-level-one-day DATE=2026-10-26
make publish-order-book-day DATE=2026-10-26
```

Omit `DATE` to use today's America/Chicago date. The script refuses a date
that has not yet closed in UTC. For each selected dataset, it runs Tickrake
`publish-staging --no-delete`, Tractatus discovery and publication with cache,
checks CLI counts and the SQLite ledger, then runs Tickrake
`purge-staging --remote` for that date and dataset. Local Tickrake files are
retained. A failure before purge leaves staging in place; a purge failure
may leave it partly deleted. See the runbook for the checks and retry limits.

No live end-to-end publication was run as part of documenting this setup.
