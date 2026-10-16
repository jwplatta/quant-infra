# Quant Platform Architecture

Tickrake collects market and reference data, writes local Parquet datasets, and maintains collection/runtime state. Tractatus publishes eligible datasets to an AWS S3 lakehouse registered in Glue and managed with Iceberg, keeping a PostgreSQL ledger of publication state. Research and trading-support consumers read historical data through Tractatus. PostgreSQL is the active transactional backend in production; SQLite remains the Tickrake development default and is not the production datastore.

```mermaid
flowchart LR
    schwab["Schwab<br/>REST + streaming"]
    schwabrb["schwab_rb<br/>Ruby API client"]
    ibkr["IBKR<br/>market data"]
    otherSources["Other providers<br/>Alpha Vantage · FRED · BLS<br/>SimFin / news APIs where enabled"]
    tickrake["Tickrake<br/>collect · stream · compact"]
    localfs["Local files<br/>Parquet datasets + JSONL logs"]
    minio["MinIO<br/>dev intraday / published data"]
    tractatus["Tractatus<br/>publish + archive access"]
    lakehouse["AWS lakehouse<br/>S3 data · Iceberg tables<br/>Glue catalog"]

    research["Research<br/>backtests + models"]
    mlflow["MLflow<br/>experiments + artifacts"]
    trading["Streamlit<br/>Options Monitor"]

    postgres["PostgreSQL<br/>production state + ledger<br/>MLflow / Grafana metadata"]
    sqlite["SQLite<br/>development only"]
    alloy["Alloy"]
    loki["Loki<br/>logs"]
    prometheus["Prometheus<br/>metrics"]
    grafana["Grafana<br/>observability dashboards"]

    schwab --> schwabrb --> tickrake
    ibkr --> tickrake
    otherSources --> tickrake
    tickrake --> localfs
    tickrake --> postgres
    tickrake -. dev .-> sqlite
    tickrake -->|"intraday publisher"| minio
    localfs --> tractatus
    tractatus -->|"Parquet + Iceberg metadata"| lakehouse
    tractatus -->|"publication ledger"| postgres
    tractatus -. "historical data interface" .-> research
    tractatus -. "historical data interface" .-> trading
    minio -->|"intraday data"| trading
    research --> mlflow
    mlflow --> postgres
    localfs --> alloy --> loki
    loki --> grafana
    prometheus --> grafana
    grafana --> postgres

    classDef user fill:#fd79a8,stroke:#d66a8e,color:#fff
    classDef service fill:#4a9eff,stroke:#2d7cd6,color:#fff
    classDef data fill:#ff9f43,stroke:#d68c3a,color:#fff
    classDef dependency fill:#a55eea,stroke:#8e4ec6,color:#fff

    class research,trading,grafana user
    class tickrake,schwabrb,tractatus,mlflow,alloy,loki,prometheus service
    class postgres,sqlite,localfs,minio,lakehouse data
    class schwab,ibkr,otherSources dependency
```

## Notes

- Production Tickrake uses PostgreSQL. SQLite remains configured for the isolated
  development profile; the production SQLite database was imported during the
  PostgreSQL cutover and is no longer the active backend.
- Tickrake's local Parquet store is the publisher's input. Tractatus records
  publication state in PostgreSQL and publishes data to S3 with Iceberg table
  metadata in Glue. S3 is the durable historical lakehouse, not the Tractatus
  ledger.
- Each source is independent: Schwab connects to Tickrake through the
  `schwab_rb` gem; IBKR and other provider adapters connect separately. Tickrake
  jobs also collect fundamentals, economic events, earnings, and other
  reference data. Alpha Vantage, FRED/BLS, and SimFin availability depends on
  the configured job/provider. News APIs are not shown as an active Tickrake
  feed unless a job is configured for one.
- Tickrake has multiple output paths: local Parquet files feed the Tractatus
  catalog publisher, and the intraday publisher writes to MinIO. Tractatus
  publishes eligible local files to the AWS Iceberg lakehouse; Tickrake does
  not publish directly to that lakehouse.
- Alloy ships Tickrake and Tractatus JSONL log files to Loki. Prometheus scrapes
  infrastructure metrics, including Docker service health and host container
  statistics. Grafana dashboards query both.
- MLflow stores experiment metadata in PostgreSQL and artifacts in its
  persistent artifact volume. Tickrake and Tractatus logs and scraped datasets
  use local mounted filesystems before publication or log shipping.
- The Streamlit Options Monitor is currently enabled in the development
  profile and reads the MinIO intraday bucket. Historical access through
  Tractatus is the intended interface represented here; deployment-specific
  wiring should be verified before treating it as active production behavior.
