#!/usr/bin/env bash
# Start one publication script in a short-lived container; no Compose service.
set -euo pipefail
umask 077

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
mkdir -p "$repo_root/tmp/logs"
dataset=${1:-}
case $dataset in
  options|level_one|order_book) shift ;;
  *) echo 'usage: run-one-off.sh options|level_one|order_book [YYYY-MM-DD]' | tee -a "$repo_root/tmp/logs/container_invalid.log" >&2; exit 2 ;;
esac
[[ $# -le 1 ]] || { echo 'expected at most one date' | tee -a "$repo_root/tmp/logs/container_invalid.log" >&2; exit 2; }

log_file="$repo_root/tmp/logs/container_${dataset}_$(date -u +%Y%m%dT%H%M%SZ).log"
trap 'status=$?; if (( status != 0 )); then printf "container run failed for %s (exit %s); inspect %s\n" "$dataset" "$status" "$log_file" | tee -a "$log_file" >&2; fi' EXIT
# These are shell-compatible env files. Source without printing their contents;
# Docker's --env-file would pass literal quote characters in quoted secrets.
set -a
source "$repo_root/envs/secrets.env"
source "$repo_root/envs/tickrake.env"
source "$repo_root/envs/prod.env"
source "$repo_root/envs/publish-day.env"
set +a

docker run --rm --network quant-infra-prod_default \
  -e TZ -e TICKRAKE_CONFIG -e TICKRAKE_DATA_DIR -e TICKRAKE_HOME \
  -e TICKRAKE_DB_ADAPTER -e TICKRAKE_DB_HOST -e TICKRAKE_DB_PORT \
  -e TICKRAKE_DB_NAME -e TICKRAKE_DB_USER -e PGPASSWORD \
  -e MINIO_ENDPOINT -e MINIO_BUCKET -e MINIO_CACHE_BUCKET \
  -e MINIO_ICEBERG_BUCKET -e MINIO_ACCESS_KEY -e MINIO_SECRET_KEY \
  -e ICEBERG_CATALOG_TYPE -e ICEBERG_POSTGRES_URL \
  -e LEDGER_DATABASE_URL -e PUBLISH_LOG_DIR -e AWS_REGION \
  --mount "type=bind,src=$repo_root/services/publish-lakehouse,dst=/publish-lakehouse,readonly" \
  --mount "type=bind,src=$repo_root/services/tickrake/config/prod,dst=/config,readonly" \
  --mount "type=bind,src=$HOME/.tickrake/data,dst=/root/.tickrake/data,readonly" \
  --mount "type=bind,src=$HOME/.tractatus,dst=/root/.tractatus" \
  --mount "type=bind,src=$repo_root/tmp/logs,dst=/workspace/tmp/logs" \
  quant-infra-publish-day:latest \
  /publish-lakehouse/publish-day.sh "$dataset" "$@" 2>&1 | tee -a "$log_file"
