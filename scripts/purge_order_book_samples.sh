#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: purge_order_book_samples.sh YYYY-MM-DD [options]

Purges order book samples for the specified date using the Tickrake CLI.

Options:
  -p, --provider NAME   Provider name (default: schwab)
  --remote              Purge from MinIO/S3 staging bucket (default if neither target is given)
  --local               Purge from local disk (~/.tickrake/data/order_book)
  --all                 Purge from both local disk and remote staging bucket
  --dry-run             Preview matching files/keys without deleting anything
  -h, --help            Show this message

Environment overrides:
  TICKRAKE_CONFIG       Tickrake config (default: services/tickrake/config/prod/tickrake.yml)
  TICKRAKE_ENV_FILE     Environment file (default: envs/tickrake.local.env)
  TICKRAKE_CLI          Tickrake CLI executable (default: tickrake)
  PGPASSWORD            PostgreSQL password (loaded from envs/secrets.env if unset)
EOF
}

fail() { printf 'error: %s\n' "$*" >&2; exit 2; }

sample_date=""
provider="schwab"
purge_remote=false
purge_local=false
dry_run=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    -p|--provider)
      [[ $# -ge 2 ]] || fail "missing argument for $1"
      provider="$2"
      shift 2
      ;;
    --remote)
      purge_remote=true
      shift
      ;;
    --local)
      purge_local=true
      shift
      ;;
    --all)
      purge_remote=true
      purge_local=true
      shift
      ;;
    --dry-run)
      dry_run=true
      shift
      ;;
    -*)
      fail "unknown option: $1"
      ;;
    *)
      if [[ -z "$sample_date" ]]; then
        sample_date="$1"
        shift
      else
        fail "unexpected argument: $1"
      fi
      ;;
  esac
done

[[ -n "$sample_date" ]] || { usage >&2; exit 2; }

if ! ruby -rdate -e 'd = Date.iso8601(ARGV.fetch(0)); abort unless d.iso8601 == ARGV.fetch(0)' "$sample_date" >/dev/null 2>&1; then
  fail "date must be a valid YYYY-MM-DD value"
fi

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
config=${TICKRAKE_CONFIG:-"$repo_root/services/tickrake/config/prod/tickrake.yml"}
env_file=${TICKRAKE_ENV_FILE:-"$repo_root/envs/tickrake.local.env"}
tickrake_cli=${TICKRAKE_CLI:-tickrake}

[[ -f "$config" ]] || fail "Tickrake config not found: $config"
[[ -f "$env_file" ]] || fail "Tickrake env file not found: $env_file"

if [[ -f "$repo_root/envs/secrets.env" ]]; then
  set -a
  source "$repo_root/envs/secrets.env"
  set +a
fi

if [[ -z "${PGPASSWORD:-}" && -n "${TICKRAKE_DB_PASSWORD:-}" ]]; then
  export PGPASSWORD="$TICKRAKE_DB_PASSWORD"
fi

[[ -n "${PGPASSWORD:-}" ]] || fail "set PGPASSWORD or define it in envs/secrets.env for the Tickrake PostgreSQL user"

command -v "$tickrake_cli" >/dev/null || fail "Tickrake CLI not found: $tickrake_cli"

# Default to remote purge if neither target was specified
if [[ "$purge_remote" == false && "$purge_local" == false ]]; then
  purge_remote=true
fi

cmd=(
  "$tickrake_cli"
  purge-staging
  --config "$config"
  --env-file "$env_file"
  --date "$sample_date"
  --dataset order_book
  --provider "$provider"
)

if [[ "$dry_run" == true ]]; then
  cmd+=(--dry-run)
fi

if [[ "$purge_remote" == true && "$purge_local" == true ]]; then
  cmd+=(--all)
elif [[ "$purge_local" == true ]]; then
  cmd+=(--local)
elif [[ "$purge_remote" == true ]]; then
  cmd+=(--remote)
fi

exec "${cmd[@]}"
