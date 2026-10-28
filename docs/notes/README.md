# Notes index

Use [the architecture overview](../architecture.md) and
[setup guide](../SETUP.md) for the current local runtime. This directory holds
operational runbooks, unresolved findings, research inputs, and historical
deployment records. Older ADRs may describe earlier deployment choices.

## Retained notes

| Note | Status and purpose |
| --- | --- |
| [liquid_weekly_options_universe.md](liquid_weekly_options_universe.md) | Research candidate universe; refresh listing and liquidity evidence before promoting symbols. |
| [schwab_ext_hrs_options.md](schwab_ext_hrs_options.md) | Candidate extended-hours symbol group; its schedule is separate from the one-off publication workflow. |
| [tickrake_streaming_staging_path.md](tickrake_streaming_staging_path.md) | Unresolved publication gap for the pending-events spool. |
| [ec2_production_scrapers.md](ec2_production_scrapers.md) | Historical EC2 contingency summary; local Compose remains primary. |
| [tickrake_postgres_cutover_20261014.md](tickrake_postgres_cutover_20261014.md) | Cutover evidence and imported row counts. See ADR 0002. |
| [production_options_table_reset.md](production_options_table_reset.md) | Historical evidence for the production options Iceberg table reset. |
| [docker_stats_exporter.md](docker_stats_exporter.md) | Host exporter operations. See ADR 0004 for the design decision. |
| [one-off-daily-publication.md](one-off-daily-publication.md) | One-off Tickrake staging, Tractatus publication, and remote purge. |
| [tickrake_configuration_refactor.md](tickrake_configuration_refactor.md) | Historical migration guide for ERB/ENV configuration and object datastore targets; verify current config before applying its steps. |

## Superseded drafts

The former generic Docker, observability, repository-layout, and staging CLI
drafts were removed after their current decisions were captured in ADRs and
their remaining operational guidance was found in README/SETUP or the notes
listed above.
