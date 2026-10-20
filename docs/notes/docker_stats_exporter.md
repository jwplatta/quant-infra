---
status: current
tags: [docker, prometheus, operations]
---

# Docker stats exporter operations

The macOS launchd job `gui/502/com.quant-infra.docker-stats-exporter` serves
metrics on port 9105. Inspect it with
`launchctl print gui/502/com.quant-infra.docker-stats-exporter` and
`curl http://127.0.0.1:9105/metrics`. Prometheus scrapes
`host.docker.internal:9105`.

The exporter is read-only and must not change container state. Its design
rationale is in [ADR 0004](../adr/0004-host-docker-stats-exporter.md).
