---
adr: 0004
title: Collect Docker Desktop metrics with a host-side exporter
status: accepted
date: 2026-10-15
tags: [observability, docker, prometheus]
---

# Collect Docker Desktop metrics with a host-side exporter

## Context

cAdvisor could not reliably map Docker Desktop's Linux VM cgroups to useful
container names. A containerized exporter also cannot reliably mount the
user-scoped Docker Engine socket on macOS.

## Decision

Run a read-only, standard-library Python exporter on the macOS host. It reads
Docker Engine stats and Compose labels; Prometheus scrapes it through
`host.docker.internal`. Grafana dashboards use its named container metrics.

## Consequences

The exporter is a host launchd service rather than a Compose service. It may
read container metadata and metrics, but it must not call Docker endpoints
that change container state. cAdvisor remains removed from the active profile.
