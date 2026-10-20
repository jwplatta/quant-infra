---
type: chore
tags: [monitoring, docker, prometheus]
title: Remove redundant cAdvisor monitoring path
description: Retire cAdvisor after the host Docker stats exporter is the validated source for container metrics.
created: 2026-09-21
updated: 2026-10-20
status: complete
priority: medium
source: quant-infra
---

# Summary

cAdvisor and its Prometheus scrape target were removed after validating the
host Docker stats exporter against the container-stats dashboard. The accepted
design is recorded in
[`ADR 0004`](../adr/0004-host-docker-stats-exporter.md).
