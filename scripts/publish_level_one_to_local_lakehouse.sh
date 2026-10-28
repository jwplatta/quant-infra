#!/usr/bin/env bash
# Discover, publish, and cache one day's level_one data from tickrake-staging MinIO
# to the local Iceberg lakehouse (PostgreSQL catalog + MinIO warehouse).
#
# Run the tickrake level_one staging command first if the date has not been staged yet.
#
# Usage:
#   bash publish_level_one_to_local_lakehouse.sh              # uses today's date
#   bash publish_level_one_to_local_lakehouse.sh 2026-10-25   # specific date
#
# Required environment variables:
#   MINIO_ACCESS_KEY        MinIO access key (for both tickrake-staging and tractatus-iceberg)
#   MINIO_SECRET_KEY        MinIO secret key
#   ICEBERG_POSTGRES_URL    PostgreSQL URL for the Iceberg SQL catalog
#                           e.g. postgresql+psycopg2://tractatus_user:tractatus@localhost:5432/tractatus
#
# Optional environment variables (defaults shown):
#   MINIO_ENDPOINT          MinIO endpoint (default: http://localhost:9000)
#   MINIO_BUCKET            Staging source bucket (default: tickrake-staging)
#   MINIO_ICEBERG_BUCKET    Iceberg warehouse bucket (default: tractatus-iceberg)
#   MINIO_CACHE_BUCKET      Cache output bucket (default: tractatus-lakehouse)
#   LEDGER_DATABASE_URL     Tractatus ledger DB (default: ~/.tractatus/catalog_ledger.db)
#                           Set to a postgresql:// URL to use the shared PostgreSQL ledger.
#   TRACTATUS_REPO          Path to tractatus repo root (default: ~/repos/tractatus)

set -euo pipefail

fail() { printf 'error: %s\n' "$*" >&2; exit 2; }

DATE="${1:-$(date +%Y-%m-%d)}"

# Validate date format
if ! python3 -c "import datetime; datetime.date.fromisoformat('$DATE')" 2>/dev/null; then
  fail "date must be a valid YYYY-MM-DD value, got: $DATE"
fi

NEXT_DATE=$(date -v+1d -j -f "%Y-%m-%d" "$DATE" +%Y-%m-%d 2>/dev/null \
  || date -d "$DATE + 1 day" +%Y-%m-%d)

export AWS_PROFILE=tickrake
export AWS_REGION=us-east-1
export ICEBERG_BUCKET=tractatus-lakehouse
export MINIO_ENDPOINT=http://localhost:9000
export MINIO_BUCKET=tickrake-staging
export MINIO_ACCESS_KEY=minioadmin
export MINIO_SECRET_KEY=minioadmin
export MINIO_CACHE_BUCKET=tractatus-lakehouse
export MINIO_ICEBERG_BUCKET=tractatus-iceberg
export ICEBERG_CATALOG_TYPE=sql
export ICEBERG_POSTGRES_URL=postgresql+psycopg2://tractatus_user:tractatus@localhost:5432/tractatus
export LEDGER_DATABASE_URL=/Users/jplatta/.tractatus/catalog_ledger.db
export TRACTATUS_REPO=/Users/jplatta/repos/tractatus

# Verify required env vars
[[ -n ${MINIO_ACCESS_KEY:-} ]]     || fail "set MINIO_ACCESS_KEY"
[[ -n ${MINIO_SECRET_KEY:-} ]]     || fail "set MINIO_SECRET_KEY"
[[ -n ${ICEBERG_POSTGRES_URL:-} ]] || fail "set ICEBERG_POSTGRES_URL"

TRACTATUS_REPO="${TRACTATUS_REPO:-$HOME/repos/tractatus}"
[[ -d $TRACTATUS_REPO ]] || fail "tractatus repo not found at $TRACTATUS_REPO (set TRACTATUS_REPO)"

echo "==> Discovering level_one_equities for $DATE..."
uv run --project "$TRACTATUS_REPO" tractatus catalog discover \
  --table level_one_equities \
  --after "$DATE" \
  --before "$NEXT_DATE"

echo "==> Publishing and caching level_one_equities for $DATE..."
uv run --project "$TRACTATUS_REPO" tractatus catalog publish \
  --table level_one_equities \
  --after "$DATE" \
  --before "$NEXT_DATE" \
  --cache

echo "==> Expiring old Iceberg snapshots for level_one_equities..."
uv run --project "$TRACTATUS_REPO" tractatus catalog expire-snapshots \
  --table level_one_equities

echo "==> Discovering level_one_futures for $DATE..."
uv run --project "$TRACTATUS_REPO" tractatus catalog discover \
  --table level_one_futures \
  --after "$DATE" \
  --before "$NEXT_DATE"

echo "==> Publishing and caching level_one_futures for $DATE..."
uv run --project "$TRACTATUS_REPO" tractatus catalog publish \
  --table level_one_futures \
  --after "$DATE" \
  --before "$NEXT_DATE" \
  --cache

echo "==> Expiring old Iceberg snapshots for level_one_futures..."
uv run --project "$TRACTATUS_REPO" tractatus catalog expire-snapshots \
  --table level_one_futures

echo "==> Done: level_one $DATE"
