#!/usr/bin/env bash
# Publish one dataset and date through Tickrake and Tractatus.

publish_day() {
  set -euo pipefail
  umask 077
  local dataset=$1
  shift
  local sample_date=${1:-$(TZ=America/Chicago date +%F)}
  local log_dir=${PUBLISH_LOG_DIR:-/workspace/tmp/logs}
  local safe_date=$sample_date
  [[ $safe_date =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] || safe_date=invalid
  mkdir -p "$log_dir"
  local log_file="$log_dir/${dataset}_${safe_date}_$(date -u +%Y%m%dT%H%M%SZ).log"
  local current_step=setup completed=false step_output=''

  progress() { printf '[%s] %s\n' "$(date -u +%FT%TZ)" "$*" | tee -a "$log_file"; }
  fail() { progress "ERROR: $*" >&2; return 1; }
  on_exit() {
    local status=$?
    [[ -z $step_output ]] || rm -f "$step_output"
    if [[ $completed == true ]]; then
      progress "SUCCESS: $dataset $sample_date; remote staging purged, local files retained"
    elif (( status != 0 )); then
      progress "ERROR: $dataset $sample_date stopped at $current_step (exit $status); see $log_file"
    fi
  }
  trap on_exit EXIT

  [[ $# -le 1 ]] || fail 'expected zero or one YYYY-MM-DD date argument'
  [[ $sample_date =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] || fail "invalid date: $sample_date"
  [[ $(date -u -d "$sample_date" +%F 2>/dev/null) == "$sample_date" ]] || fail "invalid date: $sample_date"
  [[ $sample_date < $(date -u +%F) ]] || fail "UTC date $sample_date is still open; run after 00:00 UTC"

  local required
  for required in TICKRAKE_CONFIG ICEBERG_POSTGRES_URL MINIO_ENDPOINT \
    MINIO_ACCESS_KEY MINIO_SECRET_KEY MINIO_BUCKET MINIO_CACHE_BUCKET \
    MINIO_ICEBERG_BUCKET LEDGER_DATABASE_URL PGPASSWORD; do
    [[ -n ${!required:-} ]] || fail "missing $required; check envs/"
  done
  [[ -f $TICKRAKE_CONFIG ]] || fail "Tickrake config missing: $TICKRAKE_CONFIG"
  [[ -f $LEDGER_DATABASE_URL ]] || fail "Tractatus ledger missing: $LEDGER_DATABASE_URL"
  command -v tickrake >/dev/null || fail 'tickrake CLI unavailable'
  command -v tractatus >/dev/null || fail 'tractatus CLI unavailable'
  command -v sqlite3 >/dev/null || fail 'sqlite3 unavailable'

  local before_date
  before_date=$(date -u -d "$sample_date +1 day" +%F)
  progress "Starting $dataset for $sample_date; log: $log_file"

  run_step() {
    current_step=$1
    shift
    [[ -z $step_output ]] || rm -f "$step_output"
    step_output=$(mktemp "$log_dir/.publish-step.XXXXXX")
    progress "$current_step"
    "$@" 2>&1 | tee -a "$log_file" "$step_output"
  }

  local summary scanned uploaded count errors discovered_total=0 table
  run_step 'Publishing local files to tickrake-staging' \
    tickrake publish-staging --config "$TICKRAKE_CONFIG" --dataset "$dataset" \
    --after "$sample_date" --before "$before_date" --no-delete
  summary=$(grep '^Staging publish complete:' "$step_output" | tail -n 1 || true)
  [[ $summary =~ scanned[[:space:]]([0-9]+).*uploaded[[:space:]]([0-9]+) ]] || fail 'Tickrake did not report upload counts'
  scanned=${BASH_REMATCH[1]}
  uploaded=${BASH_REMATCH[2]}
  (( scanned > 0 && scanned == uploaded )) || fail "staging incomplete: scanned=$scanned uploaded=$uploaded"

  local tables=() table_filter=''
  case $dataset in
    options) tables=(options); table_filter="'options'" ;;
    level_one) tables=(level_one_equities level_one_futures); table_filter="'level_one_equities','level_one_futures'" ;;
    order_book) tables=(order_book); table_filter="'order_book'" ;;
  esac
  for table in "${tables[@]}"; do
    run_step "Discovering staged $table files" \
      tractatus catalog discover --table "$table" --after "$sample_date" --before "$before_date"
    count=$(sed -nE 's/^Discovered:[[:space:]]*([0-9]+).*$/\1/p' "$step_output" | tail -n 1)
    [[ -n $count ]] || fail "Tractatus did not report discovered files for $table"
    discovered_total=$((discovered_total + count))

    run_step "Publishing and caching $table" \
      tractatus catalog publish --table "$table" --after "$sample_date" --before "$before_date" --cache
    errors=$(sed -nE 's/^Errors:[[:space:]]*([0-9]+).*$/\1/p' "$step_output" | tail -n 1)
    [[ -n $errors ]] || fail "Tractatus did not report an error count for $table"
    (( errors == 0 )) || fail "Tractatus reported $errors publication error(s) for $table"
  done
  (( discovered_total == scanned )) || fail "staging/discovery mismatch: uploaded=$scanned discovered=$discovered_total"

  current_step='checking Tractatus ledger before remote purge'
  local counts total committed
  counts=$(sqlite3 -readonly -separator '|' "$LEDGER_DATABASE_URL" \
    "SELECT COUNT(*), COALESCE(SUM(CASE WHEN status='committed' AND error IS NULL
      AND committed_at IS NOT NULL AND cache_key IS NOT NULL AND cached_at IS NOT NULL
      THEN 1 ELSE 0 END),0) FROM catalog_files
      WHERE sample_date='$sample_date' AND table_name IN ($table_filter);")
  IFS='|' read -r total committed <<<"$counts"
  (( total == scanned && committed == scanned )) || fail "ledger incomplete: staged=$scanned ledger=$total committed_and_cached=$committed"
  progress "Ledger check passed: $committed committed and cached file(s); no errors"

  run_step 'Purging tickrake-staging for this data type and date only' \
    tickrake purge-staging --config "$TICKRAKE_CONFIG" --date "$sample_date" \
    --dataset "$dataset" --remote
  completed=true
  exit 0
}

publish_day "$@"
