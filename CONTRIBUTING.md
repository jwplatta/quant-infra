# Contributing

## Before changing the repository

Read `README.md`, `AGENTS.md`, and `CHANGELOG.md`. Preserve unrelated
worktree changes and keep credentials out of tracked files.

For a multi-step or consequential change, write a short plan in `docs/plans/`.
Record durable operational findings in `docs/notes/`. Add actionable future
work to `docs/backlog/` using the `project-backlog` format.

## Development workflow

Use the Makefile as the Compose entrypoint. `dev` and `prod` are separate
Compose projects, but both use the same Docker Desktop host resources. Do not
bring up the entire dev stack merely to validate a small change.

Production is live. Use targeted commands and verify the exact service list
before stopping, restarting, recreating, or broadly updating anything. Do not
restart Tickrake jobs without explicit approval.

## Validation

Run the smallest relevant checks for the change. At minimum, run:

```sh
git diff --check
```

Run `make secrets-check` when a change affects configuration, environment
handling, credentials, or release readiness.

## Commits

Use Conventional Commits:

```text
type(scope): concise imperative summary
```

Examples:

```text
feat(monitoring): add Docker stats exporter
fix(streaming): detect stale Schwab sessions
docs(contributing): describe production safeguards
```

Do not include agent attributions, generated-by lines, or co-author trailers.
