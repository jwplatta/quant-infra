---
status: completed
date: 2026-10-14
tags: [tickrake, postgres, migration]
---

# Tickrake PostgreSQL cutover evidence

Production state was imported from a consistent SQLite backup into PostgreSQL
after an empty-target dry run. The importer verified row counts and generated
ID sequences. It copied 1,184 tickers, 1 market index, 23 aliases, 1,236
memberships, 400,675 fetch runs, and 144,253 file metadata rows. The
SQLite-only `lost_and_found_2` recovery table was preserved in the backup and
excluded from the application import.

Production services reconnected as `tickrake_user` after restart. See
[ADR 0002](../adr/0002-tickrake-production-postgres.md) for the lasting
database decision.
