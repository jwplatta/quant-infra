---
type: chore
tags: [data-pipeline, tickrake, tractatus]
title: Implement one-off Tickrake-to-lakehouse publication
description: Provide a manual, date-scoped container command that stages, publishes, verifies, and purges one dataset.
created: 2026-10-19
updated: 2026-10-28
status: complete
priority: high
source: quant-infra
---

# Summary

Implement a simple, manual path from local Tickrake files through the
`tickrake-staging` MinIO bucket to the Tractatus Iceberg lakehouse and
`tractatus-lakehouse` cache. Run one dataset and sample date at a time. Keep
local Tickrake files and leave scheduling for later.

## Completed implementation

- `services/publish-lakehouse/` contains a one-off CLI image, a host runner,
  and a shared publication script. The image builds Tickrake and Tractatus
  from their remote `main` branches when rebuilt; it is not a Compose service.
- `make publish-options-day`, `make publish-level-one-day`, and
  `make publish-order-book-day` select the dataset. `DATE=YYYY-MM-DD` selects a
  sample date; without it, the script uses today's America/Chicago date after
  that date has closed in UTC.
- For the selected date and dataset, the script runs Tickrake
  `publish-staging --no-delete`, Tractatus `catalog discover`, and Tractatus
  `catalog publish --cache`. Level One covers both the equities and futures
  tables.
- Before remote purge, it requires matching Tickrake scan/upload counts,
  matching Tractatus discovery counts, zero reported publication errors, and
  date/type ledger rows marked committed and cached without errors. These are
  count and state checks, not a file-identity comparison.
- On a successful check, the script runs Tickrake `purge-staging --remote` for
  that dataset and date. It never purges local Tickrake files. Progress,
  failures, and success are logged under `tmp/logs/`.

## Verification boundary

Shell syntax, Make command construction, and Docker build wiring were checked
without running a live publication or purge. Completion here means the manual
workflow is implemented; a successful end-to-end production run has not been
established by these checks. A failure during remote purge may leave staging
partly deleted and requires investigation before retrying.

## Runbook

See [one-off daily publication](../notes/one-off-daily-publication.md) for the
current commands, environment files, mounts, and failure behavior.
