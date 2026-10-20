---
type: chore
tags: [data-pipeline, tickrake, tractatus, options, candles, observability]
title: Complete collection-to-lakehouse operations and observability
description: Add a manual two-stage publisher workflow, improve options coverage and quality tracking, investigate candle artifacts, and align dashboards with the current system.
created: 2026-10-19
updated: 2026-10-20
status: in-progress
priority: high
source: quant-infra
---

# Summary

Complete the operational path from Tickrake collection through the MinIO staging bucket to the Tractatus Iceberg lakehouse and MinIO cache. Improve options-chain collection coverage and sample-quality visibility, document how candle files are produced and compacted, remove legacy objects from the Tickrake AWS S3 bucket, and bring the quant-infra dashboards in line with the current services and data contracts.

## Progress

- A date-scoped two-stage publisher script and a dry-run-first, monthly options
  S3 cleanup script have been drafted. The publisher has not been run against
  production data, and the cleanup script covers options by month rather than
  inventorying the full legacy bucket.
- The storage metrics exporter and Collection Stats panels are implemented.
  Live query verification across all dashboards remains outstanding.
- The production fundamentals job and extended-hours candidate note exist;
  the requested extended-hours schedule and a separate high-activity schedule
  are not configured.
- No durable degraded-sample status and reason is currently recorded for
  option-chain quality failures.
- The candle path still needs a current end-to-end trace. Existing Tickrake
  candle-compaction notes describe an older reconciler/archive design.

The remaining requirements below are still open. Split this item into focused
backlog entries as each workstream is taken on.

## Requirements

1. Add a script for manually publishing data through both CLIs in sequence:
   - Run Tickrake's `publish-staging` command for a selected dataset or set of
     datasets, with a bounded batch-size option.
   - After staging succeeds, run Tractatus `catalog publish` with supported
     table, provider, date-range, and file-limit filters.
   - Fail fast if either stage fails, report each stage's counts and errors,
     and make the staging-to-lakehouse handoff clear.
   - Preserve local Tickrake files by default; deletion after staging upload
     must require an explicit script option.
2. Clean up the legacy Tickrake AWS S3 bucket (`tickrake`). Record a dry-run
   inventory of object counts and bytes, confirm the target prefixes, then
   delete its data objects. Preserve the bucket itself and the MinIO buckets
   `tickrake-intraday`, `tickrake-staging`, and `tractatus-lakehouse`.
3. Update options scrape jobs for the extended-hours ticker group in
   `docs/notes/schwab_ext_hrs_options.md`. Use timezone-aware schedules for
   the noted 7:30–9:25 AM and 4:00–4:15 PM Eastern windows, and keep the symbol
   membership explicit and maintainable.
4. Define a separate high-trading-activity underlying group and scrape option
   chains more frequently for it during the intended sessions. Document the
   selection basis and schedule, and ensure the combined requests respect
   Tickrake's provider rate limiter and configured concurrency.
5. Define and implement option-chain sample validation either at Tickrake
   scrape time or during Tractatus processing. Preserve the source sample,
   record a boolean degraded-sample status and reason when validation fails,
   and make that status available to downstream users and logs. Cover the
   chosen validation rules with focused tests.
6. Trace the candle path end to end: scrape job and frequency, local file
   layout, write and rotation behavior, structured logs, conversion or
   compaction into Parquet, and resulting file sizes. Document the findings
   and recommend whether the current small per-day Parquet files should be
   consolidated or handled differently.
7. Audit all Grafana dashboards against the current Tickrake jobs, Tractatus
   events, MinIO buckets, and metric labels. Update stale queries and panels,
   then verify each changed panel against live Loki or Prometheus data and
   record any remaining upstream telemetry gaps.

## Acceptance Criteria

- A bounded manual run can publish selected data from Tickrake to
  `tickrake-staging` and then through Tractatus to the lakehouse and
  `tractatus-lakehouse` cache; failures and per-stage results are visible, and
  local deletion is opt-in.
- The legacy Tickrake AWS bucket's data objects are removed after the target
  inventory is recorded, without modifying the three active MinIO buckets.
- Extended-hours and high-activity option schedules are explicit, timezone
  aware, and rate-limit compatible.
- Option samples carry a durable degraded status and reason when they fail the
  agreed validation checks; raw source samples remain available.
- The candle write and Parquet paths, log events, and small-file behavior are
  documented with an evidence-based recommendation.
- Dashboards show current pipeline activity and storage metrics from their
  actual sources, with known telemetry gaps documented.

## Dependencies & Resources

- `docs/notes/tickrake_staging_publisher_job.md`: Tickrake staging CLI,
  datastore, and deletion behavior.
- `docs/notes/schwab_ext_hrs_options.md`: extended-hours ticker group and
  session windows.
- `docs/plans/collection_stats_storage_volume.md`: Collection Stats metrics,
  data-type mapping, and MinIO inventory design.
- Tickrake CLI: `publish-staging` and existing option scrape jobs/configuration.
- Tractatus CLI: `catalog publish`, normalization, Iceberg commit, and cache
  behavior.
- `services/monitoring/grafana/provisioning/dashboards/`: dashboards to audit
  against current structured logs and Prometheus metrics.
