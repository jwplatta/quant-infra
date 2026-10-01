# Production scrapers start target

## Objective

Provide one Make target for a production host that starts only the configured
Tickrake scrapers, stream owner, and required ingestion jobs.

## Scope

- Add `make prod-scrapers-up` using the existing production Compose profile.
- Start the approved ten services without starting their dependencies.
- Exclude research, observability, MinIO, Options Monitor, and intraday
  publishing services.

## Validation

- Dry-run the Make target and verify its complete service list.
- Run `git diff --check`.

## Production controls

The target creates or updates only its named services. Operators retain
explicit control over starting, stopping, and restarting other production
services.
