# Collection Stats storage-volume panels

## Objective

Add selected-time-range byte metrics to Collection Stats for option-chain CSV
collection volume, net compacted option-Parquet storage added, and their
compression ratio.

## Contract

- `fetch_success`, `data_type="options"`, `byte_count`: finalized raw option
  snapshot CSV bytes.
- `parquet_written`, `data_type="options"`, `compaction_output="true"`,
  `storage_byte_delta`: net bytes added by finalized option compaction output.
- The ratio is raw CSV bytes divided by net compacted-Parquet bytes over the
  same selected Grafana range.

## Implementation

1. Add three Loki stat panels below the existing count and by-symbol views.
2. Use Grafana's `$__range` macro and byte display units; leave existing event
   count panels unchanged.
3. Make missing compaction data explicit rather than displaying a fabricated
   zero or ratio.
4. Validate JSON, grid layout, Loki query syntax against available log fields,
   and the live provisioned dashboard API.

## Operational note

The production compaction job definition archives Parquet to `s3_archive`, but
it is not currently a registered Compose service. Until it next runs through
its normal scheduler or an approved one-shot, the compaction and ratio panels
are expected to have no data.
