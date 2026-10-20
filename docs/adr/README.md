# Architecture decision records

ADRs capture decisions that still shape the current platform. Each record uses
YAML front matter (`adr`, `title`, `status`, `date`, `tags`) followed by
`Context`, `Decision`, and `Consequences` sections. Superseded proposals and
dated deployment evidence belong in `docs/notes/` or Git history, not here.

## Accepted decisions

| ADR | Decision |
| --- | --- |
| [0001](0001-compose-single-host.md) | Docker Compose on a single host is the primary runtime. |
| [0002](0002-tickrake-production-postgres.md) | Production Tickrake state uses PostgreSQL; SQLite remains available for development. |
| [0003](0003-alloy-log-shipping.md) | Grafana Alloy ships logs to Loki; Promtail is fallback-only. |
| [0004](0004-host-docker-stats-exporter.md) | Docker Desktop metrics come from a read-only host exporter. |
| [0005](0005-minio-staging-tractatus-lakehouse.md) | Tickrake stages completed files to MinIO; Tractatus publishes to Glue/Iceberg and the MinIO cache. |
