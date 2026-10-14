---
type: chore
tags: [tickrake, postgres, sqlite-migration]
title: Configure production Tickrake jobs to use PostgreSQL
description: Provision secret-backed Tickrake PostgreSQL access and make the database ready before production ingestion jobs start.
created: 2026-10-14
updated: 2026-10-14
status: complete
priority: critical
source: quant-infra
---

# Summary

Production Tickrake containers now use the shared `tickrake` PostgreSQL
database. Development retains Tickrake's default SQLite backend. Existing
production state was moved by the separate operator-run Tickrake importer;
Tickrake startup does not inspect or import SQLite state.

## Requirements

- Add the Tickrake database password to the ignored secrets environment flow;
  do not store an application password in tracked files.
- Provision the `tickrake_user` role and grant access to the `tickrake`
  database without a tracked hard-coded password. Include a safe procedure for
  applying credentials to an already initialized PostgreSQL volume.
- Configure production Tickrake services to select PostgreSQL at
  `postgres:5432/tickrake` as `tickrake_user`; leave dev configured for SQLite.
- Include PostgreSQL in the production `data-ingestion` profile and gate
  production Tickrake job startup on PostgreSQL readiness.
- Add Tickrake's PostgreSQL driver/client libraries to the production image
  through the owning Tickrake task.
- Update setup documentation with secret setup, backend selection, and the
  coordinated cutover/rollback steps. The live cutover must be after market
  close, use a consistent SQLite backup and the one-time importer, verify state
  before jobs start, and retain the backup and pre-cutover config.
- Do not dual-write. Retain the verified SQLite backup and pre-cutover
  configuration for rollback.

## Dependencies & Resources

- Tickrake task: `docs/backlog/add_postgresql_backend_and_one_time_sqlite_importer.md`
- `services/tickrake/compose.yml`
- `services/postgres/compose.yml` and `services/postgres/init/`
- `deploy/prod.yml`, `envs/secrets.example.env`, and `docs/SETUP.md`
- `docs/plans/move_tickrake_production_to_postgres.md`
