# Repository Guidance

Read `README.md`, `CONTRIBUTING.md`, and `CHANGELOG.md` before making changes.
They define the current architecture, contribution workflow, and user-visible
history. Do not add agent attributions, generated-by lines, or co-author
trailers to commits, documentation, or pull requests.

## Repository layout

- `services/` contains service-specific Compose definitions and configuration.
  - `services/tickrake/` contains Tickrake jobs plus versioned dev/prod config.
  - `services/monitoring/` contains Grafana, Prometheus, Loki, Promtail, and
    monitoring configuration.
  - `services/docker-stats-exporter/` contains the host-side Docker Desktop
    metrics exporter and its launchd definition.
- `deploy/dev.yml` and `deploy/prod.yml` are environment-specific Compose
  overlays; do not put shared service definitions there.
- `envs/` contains ignored local environment files and tracked examples. Never
  commit credentials or copy user credential directories into the repository.
- `docs/plans/` holds implementation plans for multi-step changes.
- `docs/notes/` holds durable technical and operational notes.
- `docs/backlog/` holds actionable backlog items, one Markdown file per item.

## Makefile and environments

The `Makefile` composes the service files and environment overlay. Use it to
inspect or operate a profile:

- `make dev-*` uses the isolated `quant-infra-dev` project.
- `make prod-*` uses the live `quant-infra-prod` project.
- `make research-*` starts only Postgres and MLflow.
- `make data-ingestion-*` runs production collection without the full UI stack.

Treat production as live. Before any command that can recreate, restart, stop,
or broadly update services, identify the exact Compose targets. Prefer
targeted commands with `--no-deps` for monitoring-only work. Never restart,
stop, or recreate Tickrake jobs without the user's explicit approval.

## Documentation and planning

For multi-step or consequential work, write a concise plan in `docs/plans/`
before implementation. Record operational discoveries, runbooks, and design
decisions in `docs/notes/`. Keep both focused and current; do not create
placeholder documents.

Start new notes and plans with YAML front matter containing an ISO date, a
one-sentence description, and no more than two tags:

```yaml
---
date: YYYY-MM-DD
description: Brief summary of the document.
tags: [tag-one, tag-two]
---
```

Use the `project-backlog` skill for backlog work. Backlog items must follow its
YAML-frontmatter format, be actionable, and live in `docs/backlog/`. Set the
item source to the repository or workstream, not an agent identity.

## Skills

Use the relevant installed Skillex skill when it fits the task. In particular:

- `explain-diff` for reviewing or explaining a change set.
- `project-backlog` to create, search, or update backlog items.
- `python-code-quality` and `python-testing` for Python implementation work.
- `ruby-bundler` for Ruby dependency and Bundler work.

Use `skillex list` to discover shared skills and `skillex pull <skill> --agent
codex` to install an available skill when needed.

## Git and validation

Use Conventional Commits: `type(scope): summary`, for example
`feat(monitoring): add Docker stats exporter` or
`fix(tickrake): recover stale stream sessions`. Use imperative, concise
summaries. Do not add agent attributions or co-author trailers.

Preserve unrelated changes in a dirty worktree. For configuration and code
changes, run the smallest relevant validation plus `git diff --check`. Run
`make secrets-check` when the change could affect configuration, credentials,
or release readiness.
