---
date: 2026-10-28
description: Run date-scoped Tickrake and Tractatus publication in a short-lived container.
tags: [publication, operations]
---

# One-off daily publication

Build the CLI image from the current remote `main` branches of Tickrake and
Tractatus:

```sh
make publish-script-image
```

The image is used only by short-lived `docker run` commands. It does not add a
Compose service, scheduler, or container that stays running. Start the normal
PostgreSQL and MinIO stack separately before publishing.

The runner sources ignored `envs/secrets.env` without printing it, plus
`envs/tickrake.env`, `envs/prod.env`, and `envs/publish-day.env`. All four
environment files are Git-ignored.
The latter derives `ICEBERG_POSTGRES_URL` from `CATALOG_DATABASE_URL` in
`envs/prod.env`, which already uses the container hostname `postgres`. It mounts
`~/.tickrake/data` read-only, the production Tickrake config read-only,
`~/.tractatus` for the SQLite publication ledger, and `tmp/logs` for run logs.
The container joins the existing `quant-infra-prod_default` network.

Run one data type after its UTC sample date has closed. With no `DATE`, each
command uses today's Chicago date; that will be accepted after midnight UTC
(7 PM or 6 PM Chicago, depending on daylight saving time):

```sh
make publish-options-day
make publish-level-one-day
make publish-order-book-day
```

For an explicit date:

```sh
make publish-options-day DATE=2026-10-26
```

The same flow can be run with
`bash services/publish-lakehouse/run-one-off.sh <dataset> [YYYY-MM-DD]`, where `dataset`
is `options`, `level_one`, or `order_book`. The runner invokes
`services/publish-lakehouse/publish-day.sh` directly in the container. It uses
Tickrake to stage without local deletion, Tractatus to discover and publish
with cache, then Tickrake to purge **only remote staging**. Before purge, the
script checks that Tickrake's scanned and uploaded counts match, that the
Tractatus discovery count matches, and that publication reports zero errors.
It also requires the date/type rows in `catalog_files` to be committed and
cached without errors. These are count checks, not a comparison of file
identities. A failure before purge leaves staging in place; a failure during
purge may leave it partly deleted. Investigate Tractatus `error` rows before
retrying.

Progress, CLI output, publication count failures, and final success/error
messages are in `tmp/logs/` in this repository. A failed container launch is
also logged there. No local `~/.tickrake/data` file is purged by these scripts.
Snapshot expiration is not part of this one-off routine.
