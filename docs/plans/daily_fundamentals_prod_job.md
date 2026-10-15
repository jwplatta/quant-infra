# Daily fundamentals production job

## Plan

1. Review Tickrake PR #108 and confirm the merged job DSL and Parquet contract.
2. Define a production fundamentals universe from the full S&P 500, tracked equity and ETF universes, and the provided dividend watchlist; schedule it at 15:00 in `America/Chicago`.
3. Add the job to the production/data-ingestion Compose profiles and document the change.
4. Validate configuration and Compose rendering without starting or restarting production services.
