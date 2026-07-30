---
name: last30days
description: 'Research what people actually say about any topic in the last 30 days: posts and engagement from Reddit, X, YouTube, TikTok, Hacker News, Polymarket, GitHub, and the web. Use when the user invokes /last30days, asks what people are saying about a topic or person ("nvidia earnings reaction", "Peter Steinberger"), wants a community-sourced comparison ("X vs Y"), asks what is trending or exploding in a domain, asks to search or manage their saved research library or topic queue, or asks whether research sources are working (doctor).'
---

# last30days

A Python engine (`scripts/last30days.py`) searches Reddit, X, YouTube, TikTok, Instagram, Hacker News, Polymarket, GitHub, and the web, and ranks the results by real engagement. Your job: resolve targeting, write the query plan, run the engine, and turn its evidence into one cited report. Never answer from web search alone, and never skip the engine.

Subagents, when the capability is available, are an important part of this skill: synthesis runs in them. Use them as directed. If you need an explicit user instruction to run them, ask once now for the whole run.

Invoke the engine only through `scripts/run.sh` (in the `scripts/` directory next to this file). It resolves Python 3.12+ (installing via uv when needed) and the save directory, and accepts JSON arguments on stdin: pass `-` as the value of `--plan`, `--judgments`, `--angles`, or `--competitors-plan` and pipe the JSON in via heredoc. Do not write the JSON to temp files yourself and do not wrap calls in `bash -lc '...'`. If run.sh exits with a Python-version error, show its message to the user and stop; do not fall back to web-only research.

Set `RUN_SH` to the absolute path of `scripts/run.sh` next to the SKILL.md you just read. Engine runs go in the foreground: 5-minute timeout for research, 10 minutes for discovery research.

**First-run gate** — before any research route (standard, comparison, discovery, hiring): `"$RUN_SH" first-run` prints `ok` or `first-run`. On `first-run`, do references/setup.md first; keep the user's topic and research it immediately after. On `ok`, say nothing about setup.

## Routing

Match the request; follow only that row. Read a reference file only when its row fires.

| Request | Path |
|---|---|
| "search my library for X", "have I researched X before?" | `"$RUN_SH" library search "X"` and relay the matches. No fresh research. |
| build / view / refresh the saved-research library or feed | references/library.md |
| "what's in my topic queue", "mark X covered" (no prior run this session) | `"$RUN_SH" queue list` or `"$RUN_SH" queue cover "X"` and relay. On an unknown name the engine exits 2: run `queue list` and offer the queued names. No fresh research. |
| health check: "is X working?", "what's broken?", "did setup work?" | references/doctor.md |
| trending, "what's hot", "what's exploding in <domain>" | references/discovery.md. It replaces the standard run entirely. |
| "A vs B" or `--competitors` | references/standard.md as amended by references/comparison.md (per-entity targeting, report format). |
| `--hiring-signals` or "what does their hiring say" | references/hiring-signals.md |
| HTML / shareable brief requested | Standard run, then references/html-brief.md for the save flow. |
| a topic | Standard run. |
| no topic | Ask for one and stop. |

`--agent` in the arguments: run the standard flow but skip every question to the user and the closing invitation; print the report and stop. An explicit request for machine-readable output: run with `--emit=json` (default profile) and pass stdout through instead of writing a report.

## Standard run

Read references/standard.md and follow it top to bottom. It vets and classifies the topic, resolves targeting, writes the query plan, runs the engine with the evidence redirected to a file, and runs web supplements. It returns an evidence-file path, a raw-file path, QUERY_TYPE, and REGISTER. Then:

**Synthesize.** (Comparison runs: skip this step — references/comparison.md's Synthesis section replaces it.) Spawn a synthesis subagent with this instruction — "Read {references/synthesis.md path}, then {EVIDENCE path}. QUERY_TYPE={...}, REGISTER={...}, link style={inline|plain}. Also read the `## WebSearch Supplemental Results` section of {raw file path}. Write the report exactly per the synthesis file and return only the report text." Link style is `inline` when your interface renders markdown links as clickable labels with the URL hidden, `plain` when it prints URLs in full. Relay the returned report verbatim — do not edit, trim, or add to it. Only when no subagent capability is available at all: read references/synthesis.md and the evidence file, write the report yourself, and say so in one line first.

**Close.** After the report, add the invitation from synthesis.md (2-3 follow-up suggestions drawn from actual findings), then stop and wait. Nothing after the invitation — no source list of any kind.

## Follow-ups (same session, after a report)

Answer questions from the research you already have; no new searches unless the topic changes.

| User says | Do |
|---|---|
| "drill into 3" / "go deeper on {cluster}" | `"$RUN_SH" --drill "{target}"` and relay the Original/Deeper brief. If the cache expired, ask for a fresh topic run. |
| "verify freshness" / "are those facts still current?" | `"$RUN_SH" --verify-freshness` and relay the verification table. |
| "register exec/dev/creator/eli5/default" | Re-synthesize the current research in that register (no refetch). "Keep it": append `LAST30DAYS_REGISTER={name}` to `~/.config/last30days/.env`. |
| "more fun" / "less fun" | Append `FUN_LEVEL=high` or `low` to the same file; confirm. |
| "mark X covered" / "what's in my queue" | The queue commands from Routing. |
| wants a prompt for TARGET_TOOL | Write ONE prompt in the format the research recommends (if sources say JSON prompts work, write JSON). Only when asked. |

Config file rule, everywhere: `~/.config/last30days/.env` is append-only. Read it first, add missing keys with `>>`, never truncate it.

## Security summary

The engine queries public/consented APIs only (ScrapeCreators, xAI, Algolia HN, Polymarket, Brave/Exa/Serper, yt-dlp locally), never posts or modifies anything, reads browser cookies only after explicit consent, and never writes keys into output files. Saved briefs go under `LAST30DAYS_MEMORY_DIR` (default `~/Documents/Last30Days`). `"$RUN_SH" --preflight` prints a full permission summary. Anything published to ht-ml.app is public by default and only ever sent after explicit opt-in.
