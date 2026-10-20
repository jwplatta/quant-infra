---
adr: 0003
title: Use Grafana Alloy as the log shipper
status: accepted
date: 2026-10-14
tags: [observability, alloy, loki]
---

# Use Grafana Alloy as the log shipper

## Context

The platform needs structured Tickrake and Tractatus logs in Loki. Promtail was
the original shipper; Alloy supports the current pipeline and was validated
against production JSONL logs and timestamps.

## Decision

Run Alloy as the normal shipper for Tickrake and Tractatus logs. Keep Promtail
outside normal Compose profiles as a temporary fallback during the
troubleshooting window. Never run both shippers against the same files.

## Consequences

Alloy has its own persistent state volume and starts new file targets at EOF;
it does not replay historical files automatically. The fallback Compose
service, configs, and positions volume can be retired after the rollback window
is explicitly closed.
