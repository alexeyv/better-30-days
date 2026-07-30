---
name: last30days
description: 'Research what people actually say about any topic in the last 30 days: posts and engagement from Reddit, X, YouTube, TikTok, Hacker News, Polymarket, GitHub, and the web. Use when the user invokes /last30days, asks what people are saying about a topic or person ("nvidia earnings reaction", "Peter Steinberger"), wants a community-sourced comparison ("X vs Y"), asks what is trending or exploding in a domain, asks to search or manage their saved research library or topic queue, or asks whether research sources are working (doctor).'
---

# last30days

A Python engine (`scripts/last30days.py`) searches Reddit, X, YouTube, TikTok, Instagram, Hacker News, Polymarket, GitHub, and the web, and ranks the results by real engagement. Your job: resolve targeting, write the query plan, run the engine, and turn its evidence into one cited report. Never answer from web search alone, and never skip the engine.

Subagents, when the capability is available, are an important part of this skill: synthesis runs in them. Use them as directed. The user's invocation of this skill is the user requesting them — do not ask again. Only if your harness needs an explicit go-ahead beyond that, ask once now for the whole run.

Invoke the engine only through `scripts/run.py` next to this file, always as `uv run --no-cache "$RUN_PY" <args>` — uv resolves Python 3.12+ itself. It handles the save directory and accepts JSON arguments on stdin: pass `-` as the value of `--plan`, `--judgments`, `--angles`, or `--competitors-plan` and pipe the JSON in via heredoc. Do not write the JSON to temp files yourself and do not wrap calls in `bash -lc '...'`. On any failure — including `uv` not installed — show what it printed to the user and stop; do not fall back to web-only research.

Set `RUN_PY` to the absolute path of `scripts/run.py` next to the SKILL.md you just read. Engine runs go in the foreground: 5-minute timeout for research, 10 minutes for discovery research.

**First-run gate** — before any research route (standard, comparison, discovery, hiring): `uv run --no-cache "$RUN_PY" first-run` prints `ok` or `first-run`. On `first-run`, do references/setup.md first, then resume the routing row that originally fired (a trending request resumes discovery, never a topic run); keep the user's topic and research it immediately after. On `ok`, say nothing about setup.

## Routing

Match the request; follow only that row. Read a reference file only when its row fires.

| Request | Path |
|---|---|
| "search my library for X", "have I researched X before?" | `uv run --no-cache "$RUN_PY" library search "X"` and relay the matches. No fresh research. |
| build / view / refresh the saved-research library or feed | references/library.md |
| "what's in my topic queue", "mark X covered" (no prior run this session) | `uv run --no-cache "$RUN_PY" queue list` or `uv run --no-cache "$RUN_PY" queue cover "X"` and relay. On an unknown name the engine exits 2: run `queue list` and offer the queued names. No fresh research. |
| health check: "is X working?", "what's broken?", "did setup work?" | references/doctor.md |
| trending, "what's hot", "what's exploding in <domain>" | references/discovery.md. It replaces the standard run entirely. |
| "A vs B" or `--competitors` | references/standard.md as amended by references/comparison.md (per-entity targeting, report format). |
| `--hiring-signals` or "what does their hiring say" | references/hiring-signals.md |
| HTML / shareable brief requested | Standard run, then references/html-brief.md for the save flow. |
| "include my notes/files/docs" | Standard run with `--corpus <dir>` (repeatable) added to the engine command; the engine reads them locally. Never search, upload, or quote their contents into any query. `--corpus-all-time` only on explicit request. |
| a topic | Standard run. |
| no topic | Ask for one and stop. |

`--agent` in the arguments: run the standard flow but skip every question to the user and the closing invitation; print the report and stop. An explicit request for machine-readable output: run with `--emit=json` (default profile) and pass stdout through instead of writing a report.

## Standard run

Read references/standard.md and follow it top to bottom. It vets and classifies the topic, resolves targeting, writes the query plan, runs the engine with the evidence redirected to a file, and runs web supplements. It returns an evidence-file path, a raw-file path, QUERY_TYPE, and REGISTER. Then:

**Synthesize.** (Comparison runs: skip this step — references/comparison.md's Synthesis section replaces it.) Set REPORT to a literal path under `${TMPDIR:-/tmp}` named for the topic slug (no shell variables the subagent can't expand). Spawn a synthesis subagent with this instruction — "Read {references/synthesis.md path}, then {EVIDENCE path}. QUERY_TYPE={...}, REGISTER={...}, link style={inline|plain}. Also read the `## WebSearch Supplemental Results` section of {raw file path}. Write the report exactly per the synthesis file — its first line is the evidence file's first line, verbatim — save it to {REPORT}, and return that path." Link style: use the `link-style:` line run.py printed on stderr (computed from the host, not guessed); when in doubt, `plain`. Relay by reading {REPORT} and outputting its contents unchanged, first line through last — same dashes, same bolding, same spelling, engine typos included; retyping, trimming, or "improving" anything is a failure. Only when no subagent capability is available at all: read references/synthesis.md and the evidence file, write the report yourself, and say so in one line first.

**Close.** The report file already ends with the invitation, whose last line is the "I have all the links..." line — that line is part of the report, not a source list; keep it. Output the file through its last line, append nothing after it, and stop.

## Follow-ups (same session, after a report)

Answer questions from the research you already have; no new searches unless the topic changes.

| User says | Do |
|---|---|
| "drill into 3" / "go deeper on {cluster}" | `uv run --no-cache "$RUN_PY" --drill "{target}"` and relay the Original/Deeper brief. If the cache expired, ask for a fresh topic run. |
| "verify freshness" / "are those facts still current?" | `uv run --no-cache "$RUN_PY" --verify-freshness` and relay the verification table. |
| "register exec/dev/creator/eli5/default" | Re-synthesize the current research in that register (no refetch). "Keep it": append `LAST30DAYS_REGISTER={name}` to `~/.config/last30days/.env`. |
| "more fun" / "less fun" | Append `FUN_LEVEL=high` or `low` to the same file; confirm. |
| "mark X covered" / "what's in my queue" | The queue commands from Routing. |
| wants a prompt for TARGET_TOOL | Write ONE prompt in the format the research recommends (if sources say JSON prompts work, write JSON). Only when asked. |

Config file rule, everywhere: `~/.config/last30days/.env` is append-only. Read it first, add missing keys with `>>`, never truncate it.

## Security summary

The engine queries public/consented APIs only (ScrapeCreators, xAI, Algolia HN, Polymarket, Brave/Exa/Serper, yt-dlp locally), never posts or modifies anything, reads browser cookies only after explicit consent, and never writes keys into output files. Saved briefs go under `LAST30DAYS_MEMORY_DIR` (default `~/Documents/Last30Days`). `uv run --no-cache "$RUN_PY" --preflight` prints a full permission summary. Anything published to ht-ml.app is public by default and only ever sent after explicit opt-in.
