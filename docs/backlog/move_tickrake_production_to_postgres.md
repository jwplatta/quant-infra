---
type: chore
tags: [tickrake, postgres, sqlite-migration]
title: Configure production Tickrake jobs to use PostgreSQL
description: Provision secret-backed Tickrake PostgreSQL access and make the database ready before production ingestion jobs start.
created: 2026-10-14
updated: 2026-10-20
status: complete
priority: critical
source: quant-infra
---

# Summary

Production Tickrake jobs use the shared PostgreSQL `tickrake` database and
`tickrake_user` role. The one-time SQLite import completed with row counts and
generated-ID sequences verified; Tickrake startup does not import SQLite state
or dual-write. The cutover evidence is in
[`tickrake_postgres_cutover_20261014.md`](../notes/tickrake_postgres_cutover_20261014.md),
and the lasting backend decision is in
[`ADR 0002`](../adr/0002-tickrake-production-postgres.md).
