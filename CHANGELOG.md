# Changelog

All notable changes to this project are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and this project uses [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- Consolidated date-scoped Tickrake staging, Tractatus lakehouse publishing,
  and remote-only staging cleanup into one shared one-off container script for
  options, Level One, and order book.
- Added the `schwab_extended_hours_option_symbols` Tickrake universe from the candidate extended-hours ticker list.
- Added per-dataset raw, MinIO staging/cache, Iceberg Parquet, and raw-to-Parquet metrics to Collection Stats.
- Added a read-only MinIO inventory exporter for the existing Tickrake staging and Tractatus lakehouse buckets.

- Expanded production equity, stock-option, and ETF-option symbol lists and added index option roots.

- Daily Schwab fundamentals collection at 15:00 America/Chicago, covering all tracked S&P 500 constituents, production equity and ETF universes, and the imported dividend watchlist.

- Host-side Docker stats exporter for Docker Desktop container metrics with
  Docker Compose service labels.
- Economic Events Grafana dashboard with source, category, row-count, scrape,
  duration, and error views.
- Data Operations Grafana dashboard for metadata and intraday publication.
- Consolidated `market_streams` Tickrake job that multiplexes equity Level 1,
  equity order-book, and SPX/futures chart subscriptions over one Schwab
  WebSocket connection.

### Changed

- Simplified the Makefile to production lifecycle, targeted service start/stop,
  utilities, and one-off publication commands; retired dev, research, and
  data-ingestion Compose profiles. Production starts Grafana and excludes MLflow.
- The one-off Tractatus publication path uses the local PostgreSQL Iceberg
  catalog, the MinIO `tractatus-iceberg` bucket, and the
  `tractatus-lakehouse` cache. The publication ledger is SQLite.
- Container memory dashboards now use Docker CLI-style working-set usage, and Market Data Streams shows collected events and bytes written for Level 1, order book, and chart data with fixed colors.
- Configured Tractatus cache publication to use the existing `tractatus-lakehouse` MinIO bucket and updated Data Operations to show Tractatus publisher activity.
- Removed the redundant Errors panel from Collection Stats; error views remain on the operational dashboards.
- Removed the Tickrake `events_ingestor` and `historical_publisher` jobs from Compose.
- Removed Tickrake option compaction jobs, the one-off compaction wrapper, and their Compose service.

- Renamed the Tickrake 0–4 DTE options job and Compose service to `0-4dte_options`.

- Rebuilt production Tickrake jobs from the S3-upload-disabled release and
  removed the S3 manifest reconciler service.

- Replaced the normal Promtail log-shipping service with Grafana Alloy.
- Production Tickrake jobs now use the shared PostgreSQL `tickrake` database;
  SQLite remains the default backend for development.
- Container Stats dashboard now queries named Docker stats metrics instead of
  anonymous cAdvisor cgroup paths.
- Removed redundant cAdvisor service and Prometheus scrape; the host Docker
  stats exporter is the container-metrics source.
- Streaming dashboard now focuses on the consolidated `market_streams` job and
  separates its logical market-data subscriptions.
- Moved Tickrake production and development configuration and universes into
  versioned, read-only repository mounts.
