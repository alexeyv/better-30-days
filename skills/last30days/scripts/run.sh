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
cleanup() { if [ -n "$STDIN_TMP" ]; then rm -f "$STDIN_TMP"; fi; }
trap cleanup EXIT

read_stdin_tmp() {
  STDIN_TMP="$(mktemp "${TMPDIR:-/tmp}/last30days-json.XXXXXX")"
  cat > "$STDIN_TMP"
}

# Research runs (--plan / --competitors-plan / --hiring-signals) are gated on
# --resolved: the Resolved-targeting block the model showed the user. Every
# --x-handle / --github-user / --github-repo / --dedicated-subreddits value
# must appear in that block, so no handle reaches the engine without a shown,
# web-confirmed resolution. --resolved is consumed here, echoed to stderr, and
# never forwarded to the engine.
args=()
expect_json=""   # JSON-taking flag waiting for its value
pending=""       # gate-tracked flag waiting for its value
RESOLVED=""
GATED=0
COMP_PLAN=""
CHECK_VALS=()

note_json() { # flag value(path or inline JSON)
  case "$1" in
    --plan|--competitors-plan) GATED=1 ;;
  esac
  if [ "$1" = "--competitors-plan" ]; then COMP_PLAN="$2"; fi
}

add_check() { # flag value
  if [ "$1" = "--dedicated-subreddits" ]; then
    IFS=',' read -r -a _subs <<EOF
$2
EOF
    for _s in "${_subs[@]}"; do CHECK_VALS+=("$1=$_s"); done
  else
    CHECK_VALS+=("$1=$2")
  fi
}

for a in "$@"; do
  if [ -n "$expect_json" ]; then
    flag="$expect_json"; expect_json=""
    if [ "$a" = "-" ]; then read_stdin_tmp; a="$STDIN_TMP"; fi
    note_json "$flag" "$a"
    args+=("$a")
    continue
  fi
  if [ -n "$pending" ]; then
    flag="$pending"; pending=""
    if [ "$flag" = "--resolved" ]; then RESOLVED="$a"; continue; fi
    add_check "$flag" "$a"
    args+=("$flag" "$a")
    continue
  fi
  case "$a" in
    --plan|--judgments|--angles|--competitors-plan)
      expect_json="$a"
      args+=("$a")
      ;;
    --plan=-|--judgments=-|--angles=-|--competitors-plan=-)
      read_stdin_tmp
      note_json "${a%=-}" "$STDIN_TMP"
      args+=("${a%=-}" "$STDIN_TMP")
      ;;
    --plan=*|--competitors-plan=*)
      note_json "${a%%=*}" "${a#*=}"
      args+=("$a")
      ;;
    --hiring-signals)
      GATED=1
      args+=("$a")
      ;;
    --auto-resolve)
      echo "ERROR: --auto-resolve is not supported. Resolve targeting with your web-search tool (standard.md step 3) and pass --resolved." >&2
      exit 2
      ;;
    --resolved)
      pending="$a"
      ;;
    --resolved=*)
      RESOLVED="${a#*=}"
      ;;
    --x-handle|--github-user|--github-repo|--dedicated-subreddits)
      pending="$a"
      ;;
    --x-handle=*|--github-user=*|--github-repo=*|--dedicated-subreddits=*)
      add_check "${a%%=*}" "${a#*=}"
      args+=("$a")
      ;;
    *)
      args+=("$a")
      ;;
  esac
done

if [ "$GATED" = 1 ] && [ -z "$RESOLVED" ]; then
  cat >&2 <<'MSG'
ERROR: research runs require --resolved.
Show the user a `Resolved:` block first (one line per platform; each critical
handle/repo with a fragment saying how it was confirmed this turn — if nothing
was targeted, a block saying so), then re-run with:
  --resolved='<that exact block>'
MSG
  exit 2
fi

if [ "$GATED" = 1 ]; then
  for _pair in ${CHECK_VALS[@]+"${CHECK_VALS[@]}"}; do
    _flag="${_pair%%=*}"; _val="${_pair#*=}"
    if ! printf '%s' "$RESOLVED" | grep -qiF -- "$_val"; then
      echo "ERROR: $_flag=$_val does not appear in the --resolved block. Every targeted handle/repo/sub must be listed there with how it was confirmed; if you could not confirm it, drop the flag." >&2
      exit 2
    fi
  done
fi

if [ -n "$COMP_PLAN" ]; then
  "$PY" - "$COMP_PLAN" <<'PYEOF' || exit 2
import json, os, sys
raw = sys.argv[1]
if os.path.isfile(raw):
    with open(raw) as f:
        raw = f.read()
try:
    plan = json.loads(raw)
except Exception as e:
    sys.stderr.write(f"ERROR: --competitors-plan is not valid JSON: {e}\n")
    raise SystemExit(2)
allowed = {"x_handle", "x_related", "subreddits", "github_user",
           "github_repos", "trustpilot_domain", "context"}
bad = {ent: sorted(set(v) - allowed)
       for ent, v in plan.items()
       if isinstance(v, dict) and set(v) - allowed}
if bad:
    sys.stderr.write(
        f"ERROR: unknown --competitors-plan fields {bad}. "
        f"Allowed per entity: {sorted(allowed)}\n")
    raise SystemExit(2)
PYEOF
fi

if [ -n "$RESOLVED" ]; then
  printf 'targeting resolved:\n%s\n' "$RESOLVED" >&2
fi

exec "$PY" "$ENGINE" "${args[@]}"
