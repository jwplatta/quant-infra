---
status: unresolved
observed: 2026-10-19
tags: [tickrake, streaming, minio, publication-gap]
---

# Tickrake streaming event staging path

Observed 2026-10-19 while diagnosing missing futures Level One output.

Tickrake's production config sets `data_dir` to `~/.tickrake/data`, and Compose
bind-mounts the host's `~/.tickrake` at `/root/.tickrake` in the container.
Streaming event files are written to the configured `pending_events_dir`; when
it is not explicitly set, Tickrake uses `~/.tickrake/staging/pending_events`.
It uses the legacy `~/.tickrake/data/pending_events` only when that directory
already exists and contains files. An empty legacy directory does not select
that path.

The market streams job writes an active file such as
`~/.tickrake/staging/pending_events/futures_level_one.ndjson.tmp`. The `.tmp`
suffix marks the file currently being appended; Tickrake seals it to `.ndjson`
when the writer rotates or closes. Check this staging directory when looking
for recent Level One or order-book records, rather than only checking
`~/.tickrake/data/pending_events`.

## Publication gap

Tickrake's current `StagingPublisher` scans supported dataset directories under
`data_dir` (for example, `data/level_one/**/*.ndjson`) and skips `.tmp` files.
It does not scan `~/.tickrake/staging/pending_events`. Therefore, the streaming
event spool described above is not picked up by the current staging publisher;
publishing those sealed files needs a separate path or a Tickrake change.

Do not assume that successful Level One writes have been uploaded to MinIO just
because the staging publisher job is running. Verify the event file's location
and the publisher's scan results separately.
