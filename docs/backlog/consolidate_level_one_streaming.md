---
type: feature
tags: [streaming, schwab, reliability]
title: Consolidate production market streaming into one managed session
description: Replace five production stream containers with one managed Schwab WebSocket and dynamically scheduled subscriptions.
created: 2026-09-21
updated: 2026-09-21
status: not-started
priority: high
source: quant-infra
---

# Summary

Production equity and futures Level One collectors, equity order book, and two
chart streams use separate Schwab stream clients while sharing credentials. A
stream can become silent without ending its container, and reconnect activity
can interact poorly with shared token state. Use Tickrake PR #96's consolidated
stream job to run all five subscriptions on one managed websocket connection.

## Requirements

- Merge Tickrake PR #96 and rebuild the production Tickrake image with
  `schwab_rb >= 1.0.4`.
- Add one `market_streams` production DSL job containing these subscriptions:
  `equity_level_one`, `equity_order_book`, `spx_chart_stream`,
  `futures_level_one`, and `futures_chart_stream`.
- Preserve the current symbols, service names, market windows, rotation/flush
  intervals, and subscription names. The names must remain the pending-event
  writer names so the existing events ingestor continues to process the same
  file families.
- Replace the five Compose services with one `market_streams` service; do not
  change the events ingestor or unrelated Tickrake services.
- Validate subscription activation/deactivation, writer rotation, chart flush,
  liveness watchdog, disconnect recovery, and event ingestion before cutover.
- Resolve or test PR #96's fixed 60-second chart flush behavior against each
  subscription's configured `flush_interval`.
- Perform the production cutover only with explicit approval for the required
  targeted stream-service replacement. Do not restart unrelated Tickrake jobs.

## Dependencies & Resources

- `docs/notes/level_one_stream_watchdog.md` in the Tickrake repository
- `https://github.com/jwplatta/tickrake/pull/96`
- `services/tickrake/jobs/prod/equity_level_one.rb`
- `services/tickrake/jobs/prod/futures_level_one.rb`
- `services/tickrake/jobs/prod/equity_order_book.rb`
- `services/tickrake/jobs/prod/spx_chart_stream.rb`
- `services/tickrake/jobs/prod/futures_chart_stream.rb`
- `services/tickrake/compose.yml`
- `schwab_rb` stream-client reconnect behavior
