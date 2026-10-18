# Remove Tickrake events ingestor and historical publisher

## Plan

- Remove both jobs from shared Tickrake Compose services and production overrides.
- Remove their job definition files and update active service documentation.
- Validate production and data-ingestion Compose configuration and check the diff.
- Do not stop or recreate any running Tickrake containers as part of this change.
