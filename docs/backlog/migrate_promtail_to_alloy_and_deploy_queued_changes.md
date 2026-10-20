---
type: chore
tags: [monitoring, alloy, promtail, production-rollout]
title: Migrate Promtail to Alloy with the queued production rollout
description: Replace Promtail with Alloy and deploy the queued production changes and expanded collection universes after the market close.
created: 2026-10-14
updated: 2026-10-20
status: complete
priority: high
source: quant-infra
---

# Summary

Grafana Alloy replaced Promtail as the production shipper for Tickrake and
Tractatus JSONL logs. The production rollout verified new Loki records with
the expected labels and JSON timestamps, and confirmed the expanded futures
universe collected `/HG` data. The durable shipping decision is in
[`ADR 0003`](../adr/0003-alloy-log-shipping.md); the current pipeline is in
`services/monitoring/alloy/`.
