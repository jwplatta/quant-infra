# Notes index

Architecture decisions that remain in force live in [docs/adr](../adr/README.md).
This directory is for operational evidence, unresolved findings, research inputs, and historical deployment records.

## Retained notes

| Note | Status and purpose |
| --- | --- |
| [liquid_weekly_options_universe.md](liquid_weekly_options_universe.md) | Research candidate universe; refresh listing and liquidity evidence before promoting symbols. |
| [schwab_ext_hrs_options.md](schwab_ext_hrs_options.md) | Candidate extended-hours symbol group referenced by the collection backlog. |
| [tickrake_streaming_staging_path.md](tickrake_streaming_staging_path.md) | Unresolved publication gap for the pending-events spool. |
| [ec2_production_scrapers.md](ec2_production_scrapers.md) | Historical EC2 contingency summary; local Compose remains primary. |
| [tickrake_postgres_cutover_20261014.md](tickrake_postgres_cutover_20261014.md) | Cutover evidence and imported row counts. See ADR 0002. |
| [docker_stats_exporter.md](docker_stats_exporter.md) | Host exporter operations. See ADR 0004 for the design decision. |
| [tickrake_staging_publisher_job.md](tickrake_staging_publisher_job.md) | Staging schedule and CLI operations. See ADR 0005. |

## Superseded drafts

The former generic Docker, observability, repository-layout, and staging CLI
drafts were removed after their current decisions were captured in ADRs and
their remaining operational guidance was found in README/SETUP or the notes
listed above.
