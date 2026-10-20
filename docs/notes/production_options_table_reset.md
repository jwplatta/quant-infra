---
status: historical
observed: 2026-10-20
tags: [tractatus, iceberg, production, reset]
---

# Production options table reset

The production `tractatus.options` Iceberg table was reset after verifying the
AWS account, table location, PostgreSQL ledger, and upload prefixes. The
production S3 bucket had versioning disabled, so purged objects could not be
restored from S3 versions.

The reset removed 713 objects from the `tractatus/options/` upload prefix and
19 table metadata objects, deleted 715 options ledger rows, and recreated
`tractatus.options` with `expiration_date` typed as `date`. The publisher image
was rebuilt from Tractatus commit `8d4b78e` with PyIceberg 0.12.0. Verification
found no remaining options Parquet objects or ledger rows; the scheduled
publisher was left stopped and no publish was run after the reset.

This is an execution record, not a reset procedure. Reconfirm account, bucket,
Glue location, PostgreSQL target, and publisher state before any future
production maintenance.
