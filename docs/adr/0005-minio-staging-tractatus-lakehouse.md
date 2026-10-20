---
adr: 0005
title: Publish Tickrake data through MinIO staging to the Tractatus lakehouse
status: accepted
date: 2026-10-19
tags: [data-pipeline, minio, tickrake, tractatus, iceberg]
---

# Publish Tickrake data through MinIO staging to the Tractatus lakehouse

## Context

Tickrake produces local market-data files. Research consumers need normalized
tables with a repeatable publication ledger and a local object cache. The
legacy Tickrake S3 archive is not the selected current publication path.

## Decision

Tickrake's weekday staging job uploads supported completed files to MinIO's
`tickrake-staging` bucket and deletes each local file only after successful
upload. Tractatus reads the staging bucket, appends normalized data through the
AWS Glue Iceberg catalog, tracks publication state in its PostgreSQL ledger,
and caches output in the existing `tractatus-lakehouse` MinIO bucket. Keep the
catalog, ledger, staging objects, and cache as distinct state layers.

## Consequences

Tickrake staging is scheduled for 16:05 and Tractatus for 16:15
America/Chicago, leaving time for writers to seal files. Candle files contain
cumulative history and require separate date-filtering treatment. The current
Tickrake staging scanner does not read sealed event files from
`~/.tickrake/staging/pending_events`; successful stream writes do not by
themselves prove staging publication. Verify each layer independently.
