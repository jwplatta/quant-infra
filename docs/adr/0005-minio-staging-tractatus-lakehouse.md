---
adr: 0005
title: Publish Tickrake data through MinIO staging to the Tractatus lakehouse
status: accepted
date: 2026-10-19
updated: 2026-10-28
tags: [data-pipeline, minio, tickrake, tractatus, iceberg]
---

# Publish Tickrake data through MinIO staging to the Tractatus lakehouse

## Context

Tickrake produces local market-data files. Research consumers need normalized
Iceberg tables with a repeatable publication ledger and a local object cache.

## Decision

Run a manual, date-scoped container workflow for options, Level One, or order
book. Tickrake uploads local files to its `tickrake-staging` MinIO bucket
without deleting the source files. Tractatus discovers the staged files,
normalizes them, and commits Iceberg tables through the local PostgreSQL SQL
catalog into MinIO's `tractatus-iceberg` bucket. It records publication state
in the SQLite `~/.tractatus/catalog_ledger.db` and writes the
`tractatus-lakehouse` MinIO cache. After CLI count and ledger-state checks,
Tickrake purges remote staging for that dataset and date. Keep the catalog,
ledger, Iceberg objects, staging objects, and cache as distinct state layers.

## Consequences

The active production Compose stack does not run a scheduled staging or
Tractatus publisher. Run the one-off workflow only after the selected UTC
sample date has closed. The checks compare counts and ledger state, not exact
file identities; a failed purge can leave staging partly deleted. The current
Tickrake staging scanner does not read sealed event files from
`~/.tickrake/staging/pending_events`; successful stream writes do not by
themselves prove staging publication. Verify each layer independently.
