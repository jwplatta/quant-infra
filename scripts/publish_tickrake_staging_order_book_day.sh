#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: publish_tickrake_staging_order_book_day.sh YYYY-MM-DD

Uploads that day's order book files to the tickrake-staging MinIO bucket.
Local source files are retained.

Environment overrides:
  TICKRAKE_CONFIG    Tickrake config (default: services/tickrake/config/prod/tickrake.yml)
  TICKRAKE_ENV_FILE  Environment file (default: envs/tickrake.local.env)
  TICKRAKE_CLI       Tickrake CLI executable (default: tickrake)

Database password:
  PGPASSWORD         Uses this if set; otherwise loads envs/secrets.env
EOF
}

fail() { printf 'error: %s\n' "$*" >&2; exit 2; }

if [[ ${1:-} == -h || ${1:-} == --help ]]; then usage; exit 0; fi
[[ $# -eq 1 ]] || { usage >&2; exit 2; }
sample_date=$1

if ! ruby -rdate -e 'd = Date.iso8601(ARGV.fetch(0)); abort unless d.iso8601 == ARGV.fetch(0)' "$sample_date" >/dev/null 2>&1; then
  fail "date must be a valid YYYY-MM-DD value"
fi
before_date=$(ruby -rdate -e 'puts Date.iso8601(ARGV.fetch(0)) + 1' "$sample_date")

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
config=${TICKRAKE_CONFIG:-"$repo_root/services/tickrake/config/prod/tickrake.yml"}
env_file=${TICKRAKE_ENV_FILE:-"$repo_root/envs/tickrake.local.env"}
tickrake_cli=${TICKRAKE_CLI:-tickrake}

[[ -f $config ]] || fail "Tickrake config not found: $config"
[[ -f $env_file ]] || fail "Tickrake env file not found: $env_file"

if [[ -z ${PGPASSWORD:-} && -f $repo_root/envs/secrets.env ]]; then
  set -a
  source "$repo_root/envs/secrets.env"
  set +a
fi
[[ -n ${PGPASSWORD:-} ]] || fail "set PGPASSWORD for the Tickrake PostgreSQL user"
command -v "$tickrake_cli" >/dev/null || fail "Tickrake CLI not found: $tickrake_cli"

printf 'Staging order_book for %s (exclusive end %s) to tickrake-staging; local sources are retained.\n' "$sample_date" "$before_date"
"$tickrake_cli" publish-staging \
  --config "$config" \
  --env-file "$env_file" \
  --dataset order_book \
  --after "$sample_date" \
  --before "$before_date" \
  --no-delete
