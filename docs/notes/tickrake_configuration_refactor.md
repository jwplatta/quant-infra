# Tickrake Configuration Refactor & Quant-Infra Migration Plan

## Context & Overview

The Tickrake gem has modernized its configuration model (PR #134 on `tickrake`):
1. **Automatic `.env` loading**: Tickrake automatically loads environment variables via `Dotenv.load` from:
   - `--env-file PATH` CLI override
   - `ENV["TICKRAKE_ENV_FILE"]`
   - `./.env` (current working directory)
   - `~/.tickrake/.env`
2. **ERB templating in YAML**: All YAML files (including universes) evaluate `<%= ENV.fetch(...) %>`.
3. **Rails ActiveRecord Database Conventions**:
   - Uses `adapter: sqlite3` or `adapter: postgresql` and `database:` under `database:`.
   - Deprecated and removed: root `sqlite_path:` and the term `backend:`.
4. **Top-Level Datastore Targets**:
   - Replaced generic `datastores:` and obsolete `s3_archive` with top-level `staging_target:` and `intraday_target:`.
   - Removed `--datastore` CLI option across `publish-staging` and `purge-staging`.
5. **Renamed Storage Client**:
   - `Tickrake::Storage::S3Archive` renamed to `Tickrake::Storage::ObjectStoreClient`.
   - DSL `intraday_publish` and `staging_publish` blocks no longer require `datastore` definitions; they bind directly to the top-level targets.

This note outlines all components in `quant-infra` that need updates to adopt the new configuration paradigm.

---

## 1. Environment Files (`envs/`)

All environment variables used by Tickrake in containers and host scripts should be centralized and unified in `envs/`.

### `envs/tickrake.env`
Populate `envs/tickrake.env` with shared runtime and target defaults:
```bash
# Database Configuration
TICKRAKE_DB_ADAPTER=postgresql
TICKRAKE_DB_HOST=postgres
TICKRAKE_DB_PORT=5432
TICKRAKE_DB_NAME=tickrake
TICKRAKE_DB_USER=tickrake_user

# Target Object Datastores
MINIO_ENDPOINT=http://minio:9000
TICKRAKE_STAGING_BUCKET=tickrake-staging
TICKRAKE_INTRADAY_BUCKET=tickrake-intraday
STAGING_DATASTORE_TYPE=s3_compatible
INTRADAY_DATASTORE_TYPE=s3_compatible

# MinIO / S3 Credentials (non-sensitive defaults, secrets in secrets.env)
MINIO_ACCESS_KEY=minioadmin
MINIO_SECRET_KEY=minioadmin

# Filesystem Buffers
TICKRAKE_HOME=/root/.tickrake
TICKRAKE_DATA_DIR=/root/.tickrake/data
```

### `envs/secrets.env` / `envs/secrets.example.env`
Ensure credentials required for Postgres authentication are documented:
- `PGPASSWORD` (or `TICKRAKE_DB_PASSWORD`)
- `MINIO_ACCESS_KEY` / `MINIO_SECRET_KEY` (if overridden from defaults)

---

## 2. Docker Compose (`services/tickrake/compose.yml`)

Update `compose.yml` to include `envs/tickrake.env` in `env_file`:

```yaml
x-tickrake: &tickrake-base
  image: tickrake:latest
  env_file:
    - envs/secrets.env
    - envs/tickrake.env
    - envs/${ENV}.env
  volumes:
    - ./services/tickrake/jobs:/jobs:ro
    - ./services/tickrake/config/${ENV}:/config:ro
    - ~/.schwab_rb:/root/.schwab_rb
    - ~/.aws:/root/.aws:ro
  restart: unless-stopped
```

---

## 3. Configuration YAMLs (`services/tickrake/config/`)

### A. Production Config (`services/tickrake/config/prod/tickrake.yml`)
Replace static/deprecated keys with ERB and Rails conventions:
```yaml
timezone: America/Chicago

database:
  adapter: <%= ENV.fetch('TICKRAKE_DB_ADAPTER', 'postgresql') %>
  host: <%= ENV.fetch('TICKRAKE_DB_HOST', 'postgres') %>
  port: <%= ENV.fetch('TICKRAKE_DB_PORT', 5432) %>
  database: <%= ENV.fetch('TICKRAKE_DB_NAME', 'tickrake') %>
  user: <%= ENV.fetch('TICKRAKE_DB_USER', 'tickrake_user') %>
  password: <%= ENV.fetch('PGPASSWORD', ENV.fetch('TICKRAKE_DB_PASSWORD', '')) %>

staging_target:
  type: <%= ENV.fetch('STAGING_DATASTORE_TYPE', 's3_compatible') %>
  endpoint: <%= ENV.fetch('MINIO_ENDPOINT', 'http://minio:9000') %>
  bucket: <%= ENV.fetch('TICKRAKE_STAGING_BUCKET', 'tickrake-staging') %>
  access_key_id: <%= ENV.fetch('MINIO_ACCESS_KEY', 'minioadmin') %>
  secret_access_key: <%= ENV.fetch('MINIO_SECRET_KEY', 'minioadmin') %>

intraday_target:
  type: <%= ENV.fetch('INTRADAY_DATASTORE_TYPE', 's3_compatible') %>
  endpoint: <%= ENV.fetch('MINIO_ENDPOINT', 'http://minio:9000') %>
  bucket: <%= ENV.fetch('TICKRAKE_INTRADAY_BUCKET', 'tickrake-intraday') %>
  access_key_id: <%= ENV.fetch('MINIO_ACCESS_KEY', 'minioadmin') %>
  secret_access_key: <%= ENV.fetch('MINIO_SECRET_KEY', 'minioadmin') %>

storage:
  data_dir: <%= ENV.fetch('TICKRAKE_DATA_DIR', '~/.tickrake/data') %>

default_provider: ibkr-paper
providers:
  # ... provider settings ...
```
- Remove root `sqlite_path:`.
- Remove legacy `datastores:` and `s3_archive:`.

### B. Local Host Publishing Config (`services/tickrake/config/local-publish.yml`)
Can be simplified or made identical to `prod/tickrake.yml` because host-side `.env` files can point `TICKRAKE_DB_HOST=127.0.0.1` and `MINIO_ENDPOINT=http://localhost:9000`.

---

## 4. Tickrake DSL Jobs (`services/tickrake/jobs/prod/`)

### `intraday_publisher.rb`
Remove `datastore :minio_intraday` (it now automatically binds to `config.intraday_target`):
```ruby
Tickrake.job "intraday_publisher" do
  schedule do
    every 60.seconds
    weekdays from: "06:30", to: "15:15"
  end

  intraday_publish do
    clear_at "00:00"
  end
end
```

### `staging_publisher.rb`
Remove `datastore :minio_staging`:
```ruby
Tickrake.job "staging_publisher" do
  schedule do
    at "16:05"
    weekdays
  end

  staging_publish do
    datasets :all
    delete_after_upload true
  end
end
```

---

## 5. Host Scripts (`scripts/`)

Because the `--datastore` CLI option has been removed in Tickrake CLI, all publishing and purging scripts must remove `--datastore minio_staging` when invoking `tickrake publish-staging` or `tickrake purge-staging`.

### A. Existing Scripts to Update:
1. `scripts/publish_tickrake_staging_options_day.sh`:
   - Remove `--datastore minio_staging` from CLI invocation.
   - Pass `--env-file` or rely on automatic `.env` loading.
2. `scripts/publish_tickrake_staging_order_book_day.sh`:
   - Remove `--datastore minio_staging` from CLI invocation.
3. `scripts/purge_option_samples.sh`:
   - Remove `--datastore minio_staging`.
4. `scripts/purge_order_book_samples.sh`:
   - Remove `--datastore minio_staging`.

### B. New Script Required: Level One Staging Publisher
Create `scripts/publish_tickrake_staging_level_one_day.sh`:
- Operates identically to `publish_tickrake_staging_options_day.sh` and `publish_tickrake_staging_order_book_day.sh`.
- Targets dataset `--dataset level_one`.
- Retains local files with `--no-delete`.
- Accepts date parameter `YYYY-MM-DD` and verifies ISO8601 format.

---

## 6. Implementation Checklist

- [ ] Populate `envs/tickrake.env` with database and target datastore variables.
- [ ] Add `envs/tickrake.env` to `services/tickrake/compose.yml`.
- [ ] Modernize `services/tickrake/config/prod/tickrake.yml` with ERB, `adapter: postgresql`, and `staging_target:` / `intraday_target:`.
- [ ] Update DSL files `services/tickrake/jobs/prod/staging_publisher.rb` and `intraday_publisher.rb`.
- [ ] Strip `--datastore minio_staging` from options/order-book publish & purge scripts.
- [ ] Add `scripts/publish_tickrake_staging_level_one_day.sh`.
- [ ] Add matching `scripts/purge_level_one_samples.sh` for symmetry.
