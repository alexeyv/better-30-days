#!/usr/bin/env python3
# /// script
# requires-python = ">=3.12"
# ///
"""Wrapper for last30days.py. Invoked via run.sh (uv run). Handles:

- first-run gate, engine/save-dir resolution
- JSON args on stdin (`--plan -` etc.) -> tempfile
- research-run gate: requires --resolved (the targeting block shown to the
  user); cross-checks every targeted handle/repo/sub against it
- validates --plan and --competitors-plan JSON against the engine's schema
- exports LAST30DAYS_NATIVE_SEARCH=1 on research runs (host does web search;
  suppress the engine's lower-quality keyless web floor)
- prints link-style (from CLAUDECODE), a duration expectation, and a
  doctor-cache warning for degraded login-backed sources
"""
import json
import os
import re
import sys
import tempfile
import time

JSON_FLAGS = {"--plan", "--judgments", "--angles", "--competitors-plan"}
CHECK_FLAGS = {"--x-handle", "--github-user", "--github-repo", "--dedicated-subreddits"}
SUBCOMMANDS = {"first-run", "doctor", "queue", "library", "setup"}
UNGATED_FLAGS = {"--discover", "--drill", "--verify-freshness", "--diagnose", "--preflight"}
COMP_PLAN_FIELDS = {"x_handle", "x_related", "subreddits", "github_user",
                    "github_repos", "trustpilot_domain", "context"}
PLAN_INTENTS = {"breaking_news", "product", "comparison", "how_to", "opinion",
                "prediction", "factual", "concept"}
PLAN_FRESHNESS = {"strict_recent", "balanced_recent", "evergreen_ok"}
PLAN_CLUSTERS = {"story", "debate", "market", "workflow", "none"}
PLAN_SOURCES = {"reddit", "x", "youtube", "tiktok", "instagram", "hackernews",
                "polymarket"}

def die(msg: str, code: int = 2):
    sys.stderr.write(msg.rstrip() + "\n")
    sys.exit(code)

def read_stdin_tmp() -> str:
    fd, path = tempfile.mkstemp(prefix="last30days-json.", dir=os.environ.get("TMPDIR", "/tmp"))
    with os.fdopen(fd, "w") as f:
        f.write(sys.stdin.read())
    return path

def load_maybe_file(raw: str) -> str:
    if os.path.isfile(raw):
        with open(raw) as f:
            return f.read()
    return raw

def validate_competitors_plan(raw: str):
    try:
        plan = json.loads(load_maybe_file(raw))
    except Exception as e:
        die(f"ERROR: --competitors-plan is not valid JSON: {e}")
    if not isinstance(plan, dict):
        die("ERROR: --competitors-plan must be a JSON object of {entity: {targeting}}.")
    bad = {ent: sorted(set(v) - COMP_PLAN_FIELDS)
           for ent, v in plan.items()
           if isinstance(v, dict) and set(v) - COMP_PLAN_FIELDS}
    if bad:
        die(f"ERROR: unknown --competitors-plan fields {bad}. "
            f"Allowed per entity: {sorted(COMP_PLAN_FIELDS)}")

def validate_plan(raw: str):
    try:
        plan = json.loads(load_maybe_file(raw))
    except Exception as e:
        die(f"ERROR: --plan is not valid JSON: {e}")
    if not isinstance(plan, dict):
        die("ERROR: --plan must be a JSON object.")
    if plan.get("intent") not in PLAN_INTENTS:
        die(f"ERROR: --plan intent {plan.get('intent')!r} not in {sorted(PLAN_INTENTS)}")
    if plan.get("freshness_mode") not in PLAN_FRESHNESS:
        die(f"ERROR: --plan freshness_mode {plan.get('freshness_mode')!r} not in {sorted(PLAN_FRESHNESS)}")
    if plan.get("cluster_mode") not in PLAN_CLUSTERS:
        die(f"ERROR: --plan cluster_mode {plan.get('cluster_mode')!r} not in {sorted(PLAN_CLUSTERS)}")
    subs = plan.get("subqueries")
    if not isinstance(subs, list) or not subs:
        die("ERROR: --plan subqueries must be a non-empty list.")
    for i, sq in enumerate(subs):
        if not isinstance(sq, dict) or not sq.get("label") or not sq.get("search_query"):
            die(f"ERROR: --plan subquery {i} needs label and search_query.")
        srcs = sq.get("sources")
        if not isinstance(srcs, list) or not srcs or set(srcs) - PLAN_SOURCES:
            die(f"ERROR: --plan subquery {i} sources must be a subset of {sorted(PLAN_SOURCES)}.")
        w = sq.get("weight")
        if w is not None and not (isinstance(w, (int, float)) and 0 < w <= 1):
            die(f"ERROR: --plan subquery {i} weight must be in (0, 1].")

def doctor_cache_warning():
    path = os.path.expanduser("~/.config/last30days/doctor-cache.json")
    try:
        ttl = int(os.environ.get("LAST30DAYS_DOCTOR_TTL", "900"))
        if time.time() - os.path.getmtime(path) > ttl:
            return
        with open(path) as f:
            cache = json.load(f)
        for name, src in (cache.get("sources") or {}).items():
            if not isinstance(src, dict):
                continue
            state = str(src.get("state", "")).lower()
            if src.get("login_backed") or name in ("x", "reddit"):
                if "not_working" in state or "not working" in state or state == "failing":
                    sys.stderr.write(
                        f"warning: doctor cache reports {name} degraded ({state}); "
                        f"coverage will be partial - run doctor for fixes\n")
    except Exception:
        pass

def main():
    argv = sys.argv[1:]
    if argv and argv[0] == "first-run":
        env_path = os.path.expanduser("~/.config/last30days/.env")
        try:
            with open(env_path) as f:
                done = "SETUP_COMPLETE=true" in f.read()
        except OSError:
            done = False
        print("ok" if done else "first-run")
        return 0

    engine = os.environ.get("LAST30DAYS_ENGINE") or os.path.join(
        os.path.dirname(os.path.abspath(__file__)), "last30days.py")
    if not os.path.isfile(engine):
        die(f"ERROR: engine not found: {engine} (set LAST30DAYS_ENGINE)", 1)

    memory_dir = os.environ.get("LAST30DAYS_MEMORY_DIR") or os.path.expanduser("~/Documents/Last30Days")
    os.environ["LAST30DAYS_MEMORY_DIR"] = memory_dir
    os.makedirs(memory_dir, exist_ok=True)

    args: list[str] = []
    resolved = ""
    gated = False
    comp_plan_raw = plan_raw = None
    check_vals: list[tuple[str, str]] = []
    positional_topic = None
    ungated_flag_seen = False
    subcommand = argv[0] in SUBCOMMANDS if argv else False

    def note_json(flag: str, value: str):
        nonlocal gated, comp_plan_raw, plan_raw
        if flag == "--plan":
            gated, plan_raw = True, value
        elif flag == "--competitors-plan":
            gated, comp_plan_raw = True, value

    def add_check(flag: str, value: str):
        if flag == "--dedicated-subreddits":
            check_vals.extend((flag, v) for v in value.split(",") if v)
        else:
            check_vals.append((flag, value))

    expect_json = pending = None
    for a in argv:
        if expect_json:
            flag, expect_json = expect_json, None
            if a == "-":
                a = read_stdin_tmp()
            note_json(flag, a)
            args.append(a)
        elif pending:
            flag, pending = pending, None
            if flag == "--resolved":
                resolved = a
            elif flag == "--drill":
                args.extend([flag, a])
            else:
                add_check(flag, a)
                args.extend([flag, a])
        elif a in JSON_FLAGS:
            expect_json = a
            args.append(a)
        elif any(a == f + "=-" for f in JSON_FLAGS):
            flag = a[:-2]
            path = read_stdin_tmp()
            note_json(flag, path)
            args.extend([flag, path])
        elif any(a.startswith(f + "=") for f in JSON_FLAGS):
            flag, _, val = a.partition("=")
            note_json(flag, val)
            args.append(a)
        elif a == "--hiring-signals":
            gated = True
            args.append(a)
        elif a == "--auto-resolve":
            die("ERROR: --auto-resolve is not supported. Resolve targeting with "
                "your web-search tool (standard.md step 3) and pass --resolved.")
        elif a == "--resolved":
            pending = a
        elif a.startswith("--resolved="):
            resolved = a.partition("=")[2]
        elif a == "--drill":
            pending = a
            ungated_flag_seen = True
        elif a in CHECK_FLAGS:
            pending = a
        elif any(a.startswith(f + "=") for f in CHECK_FLAGS):
            flag, _, val = a.partition("=")
            add_check(flag, val)
            args.append(a)
        elif a in UNGATED_FLAGS or a.startswith("--drill="):
            ungated_flag_seen = True
            args.append(a)
        elif not a.startswith("-") and positional_topic is None and not subcommand:
            positional_topic = a
            args.append(a)
        else:
            args.append(a)

    if positional_topic and not subcommand and not ungated_flag_seen:
        gated = True

    if gated:
        if not resolved:
            die("ERROR: research runs require --resolved.\n"
                "Show the user a `Resolved:` block first (one line per platform; "
                "each critical handle/repo with a fragment saying how it was "
                "confirmed this turn - if nothing was targeted, a block saying "
                "so), then re-run with:\n  --resolved='<that exact block>'")
        low = resolved.lower()
        for flag, val in check_vals:
            if val.lower() not in low:
                die(f"ERROR: {flag}={val} does not appear in the --resolved block. "
                    f"Every targeted handle/repo/sub must be listed there with how "
                    f"it was confirmed; if you could not confirm it, drop the flag.")
        if plan_raw is None and comp_plan_raw is None and "--hiring-signals" not in argv:
            die("ERROR: a research run needs a --plan (see standard.md step 4).")

    if comp_plan_raw is not None:
        validate_competitors_plan(comp_plan_raw)
    if plan_raw is not None:
        validate_plan(plan_raw)

    if gated:
        os.environ["LAST30DAYS_NATIVE_SEARCH"] = "1"
        link = "inline" if os.environ.get("CLAUDECODE") else "plain"
        sys.stderr.write(f"link-style: {link}\n")
        sys.stderr.write("research typically takes 2-8 minutes (niche topics take longer)\n")
        doctor_cache_warning()
        if resolved:
            sys.stderr.write(f"targeting resolved:\n{resolved}\n")

    os.execv(sys.executable, [sys.executable, engine, *args])

if __name__ == "__main__":
    sys.exit(main())
