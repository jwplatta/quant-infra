# Quant Platform Architecture Diagram

The current production stack collects with Tickrake and publishes selected
dates manually through a short-lived Tickrake/Tractatus container. The
historical lakehouse is local: MinIO stores Iceberg data and PostgreSQL is
the Iceberg SQL catalog. Tractatus keeps publication state in a separate
SQLite ledger.

```mermaid
flowchart LR
    sources[Schwab and other providers] --> tickrake[Tickrake collection jobs]
    tickrake --> raw[Host data files]
    tickrake --> pgstate[PostgreSQL Tickrake state]
    tickrake --> intraday[MinIO tickrake-intraday]

    subgraph manual[Manual date and dataset publication]
        stage[Tickrake publish-staging] --> discover[Tractatus discover]
        discover --> publish[Tractatus publish with cache]
        publish --> verify[CLI and ledger checks]
        verify --> purge[Tickrake remote purge]
    end

    raw --> stage
    stage --> staging[MinIO tickrake-staging]
    staging --> discover
    publish --> iceberg[MinIO tractatus-iceberg]
    publish --> catalog[PostgreSQL Iceberg catalog]
    publish --> ledger[SQLite catalog_ledger.db]
    publish --> cache[MinIO tractatus-lakehouse]
    ledger --> verify
    purge -. removes selected date and dataset .-> staging

    intraday --> options[Options Monitor separate deployment]
    cache --> options
    iceberg --> readers[Research data readers]
    catalog --> readers

    tickrake --> logs[JSONL logs]
    publish --> logs
    logs --> alloy[Alloy]
    alloy --> loki[Loki]
    exporter[MinIO and host Docker metrics exporters] --> prometheus[Prometheus]
    loki --> grafana[Grafana]
    prometheus --> grafana
```

`make prod-up` runs collection, storage, and monitoring. It does not start
Options Monitor, MLflow, or a scheduled lakehouse publisher. The manual
publication container joins the production Docker network and keeps local
Tickrake source files after remote staging is purged. The [setup guide](SETUP.md)
and [publication runbook](notes/one-off-daily-publication.md) have the current
commands and safety checks.
