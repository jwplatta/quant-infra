---
type: chore
tags: [monitoring, alloy, promtail, production-rollout]
title: Migrate Promtail to Alloy with the queued production rollout
description: Replace Promtail with Alloy and deploy the queued production changes and expanded collection universes after the market close.
created: 2026-10-14
updated: 2026-10-14
status: complete
priority: high
source: quant-infra
---

# Summary

Promtail is end-of-life and the production log pipeline should move to Grafana
Alloy. Coordinate that migration with the other queued production changes,
including the expanded symbol universes, in the planned after-hours full-stack
rebuild and rollout. The user accepted a brief log collection gap during the
Promtail-to-Alloy handoff. The production rollout was completed after the
original 4–5 PM Central window had passed.

## Requirements

- Replace Promtail with a pinned stable Grafana Alloy image in the shared
  Compose service and dev/prod overlays; retain the existing profiles and Loki
  destination.
- Convert the current dev and production pipelines to native Alloy config.
  Preserve file targets and the `job_name_from_file`, `level`, `job_name`,
  `job_type`, and `provider` label contract. Parse JSON `ts` as the event
  timestamp and begin new targets at EOF to avoid replaying old logs.
- Give Alloy a separate persistent state volume. Retain Promtail's config,
  container, and positions volume through the troubleshooting window.
- Build and recreate the full intended production stack using the repository's
  Makefile workflow, including the other queued changes and expanded symbol
  universes. This was authorized and completed after the original 4–5 PM
  Central window; the user accepted the possible futures data gap.
- Cut over without running Promtail and Alloy together. Inspect startup errors
  and verify new Loki events, preserved labels/timestamps, existing Grafana
  queries, and the expanded collection universe. Use Promtail as fallback
  only if Alloy cannot be made healthy; preserve both state volumes during
  recovery. Alloy is healthy; the new `/HG` futures symbol collected
  successfully, and equity additions await their next scheduled market-session
  run.
- Validate both Alloy configs and the effective production Compose config
  before cutover. Keep Loki, Grafana dashboards, datasource, and existing
  LogQL label selectors compatible.
- The production rollout and its verification are documented in
  `docs/plans/promtail_to_alloy.md`.

## Dependencies & Resources

- `services/monitoring/compose.yml`
- `deploy/dev.yml` and `deploy/prod.yml`
- `services/monitoring/promtail/promtail-dev.yml` and
  `services/monitoring/promtail/promtail-prod.yml`
- `services/monitoring/grafana/provisioning/dashboards/`
- Production Tickrake configuration and universe changes in
  `services/tickrake/config/prod/`
- Grafana Alloy migration documentation:
  https://grafana.com/docs/alloy/latest/set-up/migrate/from-promtail/
