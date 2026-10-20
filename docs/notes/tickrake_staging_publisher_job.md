---
status: current
date: 2026-10-18
tags: [tickrake, minio, operations]
---

# Tickrake staging publisher

The production and data-ingestion profiles run the Tickrake staging job on
weekdays at 16:05 America/Chicago. It publishes supported datasets to the
`minio_staging` datastore (`tickrake-staging`) and deletes a local file only
after that file uploads successfully. The job definition is
[staging_publisher.rb](../../services/tickrake/jobs/prod/staging_publisher.rb).

For one-off uploads, `tickrake publish-staging` accepts `--datastore`,
`--dataset`, `--batch-size`, and `--no-delete`. See the [pipeline ADR](../adr/0005-minio-staging-tractatus-lakehouse.md)
and [setup guide](../SETUP.md) for the downstream workflow.
