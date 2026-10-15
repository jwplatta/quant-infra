# Promtail to Alloy migration

## Objective

Replace the Promtail log shipper with Grafana Alloy while preserving the
Tickrake-to-Loki label, timestamp, and dashboard query contracts. Coordinate
the production change with the queued production rebuild and expanded
collection universes.

## Scope

- Add native Alloy configurations for dev and production.
- Run Alloy in the existing monitoring profiles with its own persistent
  storage volume; retain Promtail and its positions volume as a fallback.
- Keep Promtail outside normal profiles so only one shipper runs at a time.
- During an approved after-hours window, rebuild and deploy the full intended
  production stack, then verify Alloy, Loki labels and timestamps, dashboards,
  and the expanded Tickrake universes.

## Validation

- Validate both Alloy configs using the pinned Alloy image.
- Render dev and production Compose configurations and inspect the effective
  service profiles, mounts, image tags, and fallback wiring.
- During rollout, confirm Alloy is healthy, new JSONL records arrive in Loki
  with the expected labels and `ts` timestamps, and existing dashboard queries
  continue to return data.
- Confirm expanded collection jobs start with their intended universes.

## Production controls

- The user authorized the production rebuild and cutover on 2026-10-14 after
  the originally planned 4–5 PM Central troubleshooting window had passed,
  and accepted the possible futures data gap.
- Do not restart, stop, or recreate Tickrake jobs outside this authorized
  rollout without explicit approval.
- Cut over without Promtail and Alloy running together. Keep both state
  volumes and Promtail configs until Alloy is verified through the
  troubleshooting window; use Promtail only as a fallback if Alloy is
  unhealthy.

## Rollout result

- Stopped the production stack with `make prod-down`, stopped the retained
  legacy Promtail container, rebuilt with `make prod-build-no-cache`, then
  started with `make prod-up`.
- Alloy v1.20.1 and the production profile are healthy; all current production
  services, including the 12 Tickrake jobs, are up and PostgreSQL is healthy.
- Loki queries returned new `market_streams` and `futures_candles` entries
  with the `prod`, `job_name_from_file`, and `level` labels. Loki timestamps
  matched JSON `ts` values. The futures candle run reported 32 successes and
  zero failures, including the added `/HG` symbol.
- The Promtail container is stopped and its positions volume remains present;
  the separate Alloy state volume is also present. Alloy logs showed no
  errors during verification.
- Equity option jobs restarted with the expanded mounted production config;
  their next scheduled market-session collection remains the verification
  point for newly added equity symbols.
