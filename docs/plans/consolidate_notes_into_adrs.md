# Consolidate durable notes into ADRs

## Objective

Reduce `docs/notes/` to concise operational and research notes, and record
accepted architecture decisions in a new `docs/adr/` directory with searchable
YAML front matter.

## Scope and approach

1. Compare every note with current Compose files, service configuration,
   README/SETUP guidance, and backlog references.
2. Create ADRs only for decisions still reflected by the current system.
3. Retain unresolved findings, incidents, current research notes, and useful
   runbooks; shorten them and mark status/date where applicable.
4. Remove superseded drafts and stale generic notes only after confirming they
   have no unique current references or decisions.
5. Add an ADR index and document the ADR front-matter convention.

## Validation

Check every note filename reference, inspect the final diff, and run
`git diff --check`. Documentation changes do not require service operations.

## Outcome

Completed 2026-10-20. Added five accepted ADRs, shortened current operational
notes, marked research and unresolved notes with status front matter,
summarized the historical EC2 contingency, and removed superseded
drafts whose decisions are now recorded in ADRs or current setup documentation.
The architecture and setup guides were rewritten from the current Compose
configuration, and MinIO initialization now creates the Tractatus cache bucket.
The Alloy cutover, SQLite I/O incident, and redundant Tractatus publisher
operations note were removed at the user's direction. Local Markdown links,
YAML front matter, Compose configuration, secret scanning, and
`git diff --check` passed.
