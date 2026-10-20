---
adr: 0001
title: Use Docker Compose on a single host as the primary runtime
status: accepted
date: 2026-10-20
tags: [deployment, docker-compose]
---

# Use Docker Compose on a single host as the primary runtime

## Context

The platform runs collection, storage, research support, and observability
services on a personal Docker Desktop host. A remote EC2 deployment has also
been used as a travel or host-availability fallback. The workload has not
required multi-host scheduling.

## Decision

Use Docker Compose as the deployment and operations interface. Keep dev and
production as separate projects, with focused research and data-ingestion
profiles. The local host is the primary production runtime. Use a remote host
only when there is a concrete availability need; defer Kubernetes and other
orchestration layers until the operational requirements justify them.

## Consequences

Operations must target explicit Compose services and profiles because local
dev and production share Docker Desktop resources. Production changes should
avoid broad restarts. Remote host procedures remain contingency runbooks, not
the default deployment path.
