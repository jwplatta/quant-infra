# Collection Stats storage-volume dashboard

## Objective

Show raw data volume, staging and Tractatus cache inventory, Iceberg Parquet
bytes added, and the raw-to-Parquet ratio by dataset in Grafana Collection
Stats.

## Dashboard grid

Rows: Totals, Options, Level One, Order Book, Candles, Fundamentals, and
Economic Events. Columns: Raw Written, Staging Cache, Written to Parquet,
Tractatus Cache, and Ratio of Raw Written to Parquet.

Render one stat panel for each of the 35 row-column combinations. Default the
dashboard to the last 24 hours for flow metrics. Show cache columns as the
latest inventory snapshot, scanning immediately at exporter startup and then
every 24 hours; retry a failed scan every five minutes.

Aggregate the Tractatus tables into these rows. In particular, Level One sums
`level_one_equities` and `level_one_futures`; other rows map to their matching
table names. Keep the table-to-row mapping explicit in the dashboard queries.

## Metric sources

- Raw Written: sum Tickrake structured log byte fields over the selected time
  range. Use the existing `byte_count` events for options, market streams,
  candles, fundamentals, and economic events. Market-stream Level One data
  combines equity and futures event types when emitted separately.
- Staging Cache and Tractatus Cache: a read-only exporter in
  `services/monitoring/` lists objects at startup and every 24 hours in the existing
  `tickrake-staging` and `tractatus-lakehouse` MinIO buckets. It exports object
  bytes by dataset prefix; it does not scan `~/.tickrake/data` or modify bucket
  contents. Aggregate both Level One table prefixes into the Level One row.
- Written to Parquet: sum `parquet_bytes_added` from Tractatus `file_committed`
  events, mapping the `table` field to dashboard rows. Aggregate the two Level
  One tables.
- Ratio: for the selected time range, divide summed `source_bytes` by summed
  `parquet_bytes_added` from the same Tractatus `file_committed` events. The
  separate Raw Written column uses Tickrake logs and may include files that
  have not yet been committed.

Tractatus JSONL logs are already collected by Alloy and sent to Loki. Configure
the Tractatus publisher to use the existing `tractatus-lakehouse` bucket. Do
not create, clear, overwrite, or republish its contents as part of this work.

## Implementation and validation

1. Replace obsolete Collection Stats byte panels that still describe removed
   compaction and `events_ingestor` flows with 35 one-value stat panels in the
   seven-row, five-column storage grid.
2. Add the read-only MinIO inventory exporter and Prometheus scrape target under
   the monitoring service definitions.
3. Configure the Tractatus publisher's cache bucket as `tractatus-lakehouse`.
4. Update Data Operations panels that still refer to removed ingestion jobs;
   leave Market Streams and Options dashboards unchanged. Keep error views on
   their existing dashboards and omit them from Collection Stats.
5. Validate dashboard JSON, Compose configuration, exporter metric labels and
   query expressions, and run `git diff --check`. Do not restart Tickrake jobs
   as part of deployment.

## Assumptions

- The existing `tickrake-staging` and `tractatus-lakehouse` buckets contain
  dataset prefixes consistent with Tickrake dataset names and Tractatus table
  names.
- `file_committed` events with `source_bytes` and `parquet_bytes_added` are
  available in Tractatus JSONL logs after the merged Tractatus change.
- Ratio is shown only when the paired committed-file metrics are present and
  the Parquet byte denominator is nonzero.
