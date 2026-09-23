---
type: chore
tags: [monitoring, docker, prometheus]
title: Remove redundant cAdvisor monitoring path
description: Retire cAdvisor after the host Docker stats exporter is the validated source for container metrics.
created: 2026-09-21
updated: 2026-09-21
status: not-started
priority: medium
source: quant-infra
---

# Summary

Production currently runs cAdvisor and the host Docker stats exporter in
parallel. The exporter provides container-name labels for the container-stats
dashboard, so cAdvisor should be removed once the exporter remains healthy and
the dashboard no longer depends on cAdvisor metrics.

## Requirements

- Confirm the Grafana container-stats dashboard uses only `docker_stats` job
  metrics and remains useful across a normal data-collection interval.
- Remove the `cadvisor` service and its Prometheus scrape configuration from
  the monitoring Compose configuration.
- Remove any obsolete cAdvisor dashboard queries, alerts, dependencies, and
  documentation.
- Validate the rendered production Compose configuration and Prometheus target
  set before deployment.
- Apply the production configuration only with explicit approval; do not
  restart, stop, recreate, or otherwise interrupt Tickrake jobs as part of
  this work.

## Dependencies & Resources

- `services/monitoring/compose.yml`
- `services/monitoring/prometheus/prometheus.yml`
- `services/docker-stats-exporter/`
- `services/monitoring/grafana/provisioning/dashboards/container-stats.json`
