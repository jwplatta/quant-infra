# Remove Tickrake compaction jobs

## Goal

Remove compaction work from Tickrake now that it no longer owns compaction.

## Scope

- Remove Tickrake compaction job definitions and the one-off Docker wrapper.
- Remove the maintenance Compose service and Make target.
- Remove the obsolete Data Operations compaction panel and current architecture reference.
- Keep historical plans, runbooks, and storage telemetry as records of prior compaction activity.

## Validation

- Confirm production and data-ingestion Compose configurations remain valid and have no compaction service.
- Search active Tickrake job/configuration references for compaction job names.
- Run `git diff --check` and `make secrets-check`.
