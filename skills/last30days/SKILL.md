---
name: last30days
version: "4.0.0"
description: "Research what people actually say about any topic in the last 30 days. Pulls posts and engagement from Reddit, X, YouTube, TikTok, Hacker News, Polymarket, GitHub, and the web. Includes a doctor health check to diagnose broken or missing sources."
argument-hint: 'last30days nvidia earnings reaction | last30days AI video tools | last30days what users want in react'
allowed-tools: Bash, Read, Write, AskUserQuestion, WebSearch
homepage: https://github.com/alexeyv/better-30-days
repository: https://github.com/alexeyv/better-30-days
license: MIT
user-invocable: true
---

# last30days

A Python engine (`scripts/last30days.py`) searches Reddit, X, YouTube, TikTok, Instagram, Hacker News, Polymarket, GitHub, and the web, and ranks the results by real engagement. Your job: resolve targeting, write the query plan, run the engine, and turn its evidence into one cited report. The engine is the research; never answer from web search alone, and never skip it.

Invoke the engine only through `scripts/run.sh` (a sibling of this file's `scripts/` directory). It resolves Python 3.12+ (installing via uv when needed) and the save directory, and accepts JSON arguments on stdin: pass `-` as the value of `--plan`, `--judgments`, `--angles`, or `--competitors-plan` and pipe the JSON in via heredoc. Do not build tempfile plumbing yourself and do not wrap calls in `bash -lc '...'`. If run.sh exits with a Python-version error, show its message to the user and stop; do not fall back to web-only research.

Set `RUN_SH` to the absolute path of `scripts/run.sh` next to the SKILL.md you just read. Engine runs go in the foreground: 5-minute timeout for research, 10 minutes for discovery research.

## Routing

Match the request; follow only that row. Read a reference file only when its row fires.

| Request | Path |
|---|---|
| "search my library for X", "have I researched X before?" | `"$RUN_SH" library search "X"` and relay the matches. No fresh research. |
| build / view / refresh the saved-research library or feed | references/library.md |
| "what's in my topic queue", "mark X covered" (no prior run this session) | `"$RUN_SH" queue list` or `"$RUN_SH" queue cover "X"` and relay. On an unknown name the engine exits 2: run `queue list` and offer the queued names. No fresh research. |
| health check: "is X working?", "what's broken?", "did setup work?" | references/doctor.md |
| trending, "what's hot", "what's exploding in <domain>" | references/discovery.md. Nothing from the standard run applies. |
| "A vs B" or `--competitors` | Standard run + references/comparison.md (per-entity targeting, report format). |
| `--hiring-signals` or "what does their hiring say" | references/hiring-signals.md |
| HTML / shareable brief requested | Standard run, then references/html-brief.md for the save flow. |
| a topic | Standard run. |
| no topic | Ask for one and stop. |

`--agent` in the arguments: run the standard flow but skip every question to the user and the closing invitation; print the report and stop. An explicit request for machine-readable output: run with `--emit=json` (default profile) and pass stdout through instead of writing a report.

## Standard run

**1. First-run gate.** `"$RUN_SH" first-run` prints `ok` or `first-run`. On `first-run`, do references/setup.md before any research; keep the user's topic and research it immediately after. On `ok`, say nothing about setup.

**2. Vet the topic.** Some phrasings retrieve garbage; fix them before spending five minutes of engine time:
- Demographic shopping ("gift for a 42 year old man"): ask one narrowing question (hobbies / relationship / budget). If declined, drop the age and scope to gift subreddits (GiftIdeas, BuyItForLife, AskMen, plus hobby subs).
- A number that collides with unrelated content ("the 100", "42"): drop it from the search query unless it names the thing (GPT-4 keeps it).
- Tutorial phrasing ("how to use Docker"): reframe to how people title posts ("Docker workflows tips").
- A bare generic noun ("sneakers", "coffee"): ask which facet before running.
- Non-Latin-script topic: add `--web-backend brave`; expect little from Reddit/HN/GitHub and say so in the report.

**3. Classify.** QUERY_TYPE = COMPARISON (contains " vs "/" versus "), RECOMMENDATIONS ("best X", "top X", "what X should I use"), NEWS ("what's happening with", "latest on"), PROMPTING ("X prompts", "prompting for X"), else GENERAL. Note TARGET_TOOL if named ("mockups **for Midjourney**") — don't ask for one before research. REGISTER = an explicit `--register` value, else `LAST30DAYS_REGISTER` from config, else default. Then tell the user in one line what you're doing, naming only sources the engine reports available (`"$RUN_SH" --diagnose` prints JSON; use its `available_sources`): `/last30days - searching {sources} for what people are saying about {topic}.`

**4. Resolve targeting.** (If this session has no web-search tool: skip steps 4-5, add `--auto-resolve` to the engine command, and go to step 6.) Use 2-4 batched web searches plus what you already know; verify accounts are the entity's own, not fan/parody accounts, and never guess a handle you couldn't verify.
- **X**: primary handle; the founder's handle for a company topic or the company's for a person topic; 1-2 commentator/media handles that cover the space. → `--x-handle`, `--x-related` (related are searched at lower weight).
- **GitHub**: person who ships code → `--github-user` (scopes search to their PRs, repos, releases). Product/project → `--github-repo owner/repo`. On a person topic, X handle without GitHub user is a half-done resolution.
- **Reddit**: 3-5 subreddits. Subs dedicated to the entity itself → `--dedicated-subreddits` (pulled in full, no relevance filter); mixed communities → `--subreddits`. For a product in a recognizable category, include 2-3 cross-product category subs (image-gen tools get StableDiffusion/midjourney/aiArt; coding agents get ChatGPTCoding/LocalLLaMA) — technique discussion lives there, not only in the brand's own sub. Cap 10 total.
- **TikTok/Instagram**: infer hashtags and creator handles from what you know (`--tiktok-hashtags`, `--tiktok-creators`, `--ig-creators`); don't search for a CEO's TikTok.
- **YouTube**: infer 2-3 content queries (reviews / reactions / interviews) for the plan.
- **Trustpilot** (company/brand topics where review evidence helps): the company's domain, not its name → `--trustpilot-domain` (also activates the source).
- **Positioning** (company/product topics only, never people or ownerless things): fetch the current first-party pitch (homepage tagline, pricing page). Used in synthesis; never quote positioning from memory.
- One search for current news context — it improves the plan below.

Omit any flag you couldn't resolve. Then show a short `Resolved:` block listing what you found (one line per platform, skip empty ones).

**5. Plan.** Write the query plan yourself — you are the planner; no API key is involved. 1-4 subqueries:

```json
{
  "intent": "breaking_news|product|comparison|how_to|opinion|prediction|factual|concept",
  "freshness_mode": "strict_recent|balanced_recent|evergreen_ok",
  "cluster_mode": "story|debate|market|workflow|none",
  "subqueries": [
    {"label": "primary", "search_query": "...", "ranking_query": "...?",
     "sources": ["reddit","x","youtube","tiktok","instagram","hackernews","polymarket"], "weight": 1.0}
  ]
}
```

Rules: the primary subquery includes all seven sources above; secondary subqueries (weight 0.6-0.8) may target fewer. `search_query` is keyword-shaped like a post title; `ranking_query` is a question. No dates, months, or words like "news"/"recent" in search queries. If the name collides with anything else (common word, other public figures), anchor **every** subquery with the disambiguator you resolved ("kevin rose digg founder", not "kevin rose"). breaking_news/prediction → strict_recent; concept/how_to → evergreen_ok; else balanced_recent.

**6. Run the engine** (foreground, 5-minute timeout), saving stdout to a file so the evidence goes to the synthesis step, not the conversation:

```bash
EVIDENCE="${TMPDIR:-/tmp}/last30days-evidence-$$.md"
"$RUN_SH" "TOPIC" --emit=compact --save-suffix=v3 \
  --x-handle=... --subreddits=... [other resolved flags] \
  --plan - > "$EVIDENCE" <<'EOF'
{ ...your plan json... }
EOF
```

Pass `--days=N`, `--quick`, `--deep`, `--register=...` through when the user asked for them. stderr shows progress and the `[last30days] Saved output to {path}` line — note that saved raw-file path. Exit 3 means the engine asked a clarifying question on stderr: relay it and re-run with the answer folded into the topic.

**7. Web supplements.** Run 2-3 web searches for what the social engine misses — news context, critic/long-form reactions, and one claim worth corroborating (for RECOMMENDATIONS: "best {topic}" roundups; for PROMPTING: technique posts). Exclude reddit.com and x.com. Then append to the saved raw file a `## WebSearch Supplemental Results` section, one bullet per source that informed the report: `- **{Publisher}** ({domain}) - {1-2 sentence takeaway}`. No URLs in the bullets.

**8. Synthesize.** If this harness can spawn subagents: spawn one with this instruction — "Read {references/synthesis.md path}, then {EVIDENCE path}. QUERY_TYPE={...}, REGISTER={...}, link style={inline|plain}. Also read the `## WebSearch Supplemental Results` section of {raw file path}. Write the report exactly per the synthesis file and return only the report text." Link style is `inline` when your interface renders markdown links as clickable labels with the URL hidden, `plain` when it prints URLs in full. Relay the returned report verbatim — do not edit, trim, or add to it. If you cannot spawn subagents, read references/synthesis.md and the evidence file and write the report yourself.

**9. Close.** After the report, add the invitation from synthesis.md (2-3 follow-up suggestions drawn from actual findings), then stop and wait. Nothing after the invitation — no source list of any kind.

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
