---
adr: 0002
title: Use PostgreSQL for production Tickrake state
status: accepted
date: 2026-10-14
tags: [tickrake, postgres, persistence]
---

# Use PostgreSQL for production Tickrake state

## Context

Production Tickrake services share one host-mounted state directory. Concurrent
SQLite access through Docker Desktop produced transient I/O errors; the
available offline integrity check did not identify persistent corruption or
prove the cause.

## Decision

Configure production Tickrake to use the existing PostgreSQL service and a
dedicated `tickrake` database role. Keep SQLite supported for development and
standalone use. Perform SQLite imports as an explicit operator-run migration;
do not add startup migrations, automatic probing, or dual writes.

## Consequences

Production state is shared through PostgreSQL rather than concurrent access to
a SQLite file on the host bind mount. Back up the SQLite source before a
one-time import and validate copied row counts and generated-ID sequences.
The incident's underlying filesystem or SQLite cause remains unconfirmed.
