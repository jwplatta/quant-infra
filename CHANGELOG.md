# Changelog

All notable changes to this project are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and this project uses [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- Host-side Docker stats exporter for Docker Desktop container metrics with
  Docker Compose service labels.
- DSL-defined one-shot option-sample compaction and archive job for one
  explicit date.
- Economic Events Grafana dashboard with source, category, row-count, scrape,
  duration, and error views.
- Data Operations Grafana dashboard for metadata, reconciliation, intraday
  publication, event ingestion, and compaction activity.
- Consolidated `market_streams` Tickrake job that multiplexes equity Level 1,
  equity order-book, and SPX/futures chart subscriptions over one Schwab
  WebSocket connection.

### Changed

- Container Stats dashboard now queries named Docker stats metrics instead of
  anonymous cAdvisor cgroup paths.
- Removed redundant cAdvisor service and Prometheus scrape; the host Docker
  stats exporter is the container-metrics source.
- Streaming dashboard now focuses on the consolidated `market_streams` job and
  separates its logical market-data subscriptions.
- Added `research` and `data-ingestion` Compose profiles for focused research
  services and collection-only production operation.
- Moved Tickrake production and development configuration and universes into
  versioned, read-only repository mounts.
- Limited Options Monitor to the development profile and moved the production
  MLflow host port to `5005`.
