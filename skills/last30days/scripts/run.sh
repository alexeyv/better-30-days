#!/usr/bin/env bash
# Wrapper for scripts/last30days.py. Resolves the Python interpreter and save
# directory, and lets JSON arguments arrive on stdin: pass `-` as the value of
# --plan / --judgments / --angles / --competitors-plan and pipe the JSON in.
#
#   run.sh first-run                 -> prints "ok" or "first-run"
#   run.sh "topic" --emit=compact --plan - <<'EOF'
#   { ...plan json... }
#   EOF
#
# Engine location: sibling last30days.py by default; override with
# LAST30DAYS_ENGINE for development.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENGINE="${LAST30DAYS_ENGINE:-$SCRIPT_DIR/last30days.py}"

if [ "${1:-}" = "first-run" ]; then
  if grep -qs "SETUP_COMPLETE=true" "$HOME/.config/last30days/.env"; then
    echo ok
  else
    echo first-run
  fi
  exit 0
fi

if [ ! -f "$ENGINE" ]; then
  echo "ERROR: engine not found: $ENGINE (set LAST30DAYS_ENGINE)" >&2
  exit 1
fi

py_ok() {
  command -v "$1" >/dev/null 2>&1 || return 1
  "$1" -c 'import sys; raise SystemExit(0 if sys.version_info >= (3, 12) else 1)' 2>/dev/null
}

PY="${LAST30DAYS_PYTHON:-}"
if [ -z "$PY" ] || ! py_ok "$PY"; then
  PY=""
  for c in python3.14 python3.13 python3.12 python3 python; do
    if py_ok "$c"; then PY="$c"; break; fi
  done
fi
if [ -z "$PY" ] && command -v uv >/dev/null 2>&1; then
  PY="$(uv python find '>=3.12' 2>/dev/null || true)"
  if [ -z "$PY" ]; then
    echo "Installing managed CPython 3.12 via uv (~28MB, one-time)." >&2
    uv python install 3.12 >&2 || true
    PY="$(uv python find '>=3.12' 2>/dev/null || true)"
  fi
fi
if [ -z "$PY" ]; then
  echo "ERROR: last30days needs Python 3.12+. Install it (brew install python@3.12 / winget install Python.Python.3.12 / apt install python3.12) or set LAST30DAYS_PYTHON." >&2
  exit 1
fi

export LAST30DAYS_MEMORY_DIR="${LAST30DAYS_MEMORY_DIR:-$HOME/Documents/Last30Days}"
mkdir -p "$LAST30DAYS_MEMORY_DIR"

# Swap a `-` value on a JSON flag for a tempfile filled from stdin.
STDIN_TMP=""
cleanup() { [ -n "$STDIN_TMP" ] && rm -f "$STDIN_TMP"; }
trap cleanup EXIT

read_stdin_tmp() {
  STDIN_TMP="$(mktemp "${TMPDIR:-/tmp}/last30days-json.XXXXXX")"
  cat > "$STDIN_TMP"
}

args=()
expect_json=0
for a in "$@"; do
  if [ "$expect_json" = 1 ]; then
    expect_json=0
    if [ "$a" = "-" ]; then
      read_stdin_tmp
      args+=("$STDIN_TMP")
      continue
    fi
    args+=("$a")
    continue
  fi
  case "$a" in
    --plan|--judgments|--angles|--competitors-plan)
      expect_json=1
      args+=("$a")
      ;;
    --plan=-|--judgments=-|--angles=-|--competitors-plan=-)
      read_stdin_tmp
      args+=("${a%=-}" "$STDIN_TMP")
      ;;
    *)
      args+=("$a")
      ;;
  esac
done

exec "$PY" "$ENGINE" "${args[@]}"
