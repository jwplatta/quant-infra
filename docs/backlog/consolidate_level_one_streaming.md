---
type: feature
tags: [streaming, schwab, reliability]
title: Consolidate production market streaming into one managed session
description: Replace five production stream containers with one managed Schwab WebSocket and dynamically scheduled subscriptions.
created: 2026-09-21
updated: 2026-10-20
status: in-progress
priority: high
source: quant-infra
---

# Summary

The production configuration now uses one `market_streams` service with a
managed stream session for equity/futures Level One, equity order book, and
chart subscriptions. Remaining work is to verify the current schedule, writer
rotation, watchdog/reconnect behavior, and chart flush semantics. Event
ingestion through the former events ingestor is out of scope because that
service has been removed; the pending-events-to-MinIO gap is tracked in
[`complete_data_pipeline_and_collection_operations.md`](complete_data_pipeline_and_collection_operations.md).

## Requirements

- Confirm that configured subscriptions, symbols, and session windows match
  the intended market coverage.
- Verify subscription activation/deactivation, writer rotation, watchdog
  recovery, and disconnect/reconnect behavior against the current job.
- Resolve the chart flush interval mismatch: chart subscriptions configure
  120 seconds, while the consolidated stream watchdog also flushes chart
  buffers every 60 seconds. Decide which interval is the contract and test it.
- Confirm the production deployment uses the consolidated job; do not restart
  unrelated Tickrake services during any required validation.

## Dependencies & Resources

- `services/tickrake/jobs/prod/market_streams.rb`
- `services/tickrake/compose.yml`
- Tickrake stream runner and chart flush implementation
