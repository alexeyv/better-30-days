# Standard research run

Produces an evidence file and a saved raw file, then hands back to SKILL.md's synthesis step.

**1. Vet the topic.** Some phrasings retrieve garbage; fix them before spending five minutes of engine time:
- Demographic shopping ("gift for a 42 year old man"): ask one narrowing question (hobbies / relationship / budget). If declined, drop the age and scope to gift subreddits (GiftIdeas, BuyItForLife, AskMen, plus hobby subs).
- A number that collides with unrelated content ("the 100", "42"): drop it from the search query unless it names the thing (GPT-4 keeps it).
- Tutorial phrasing ("how to use Docker"): reframe to how people title posts ("Docker workflows tips").
- A bare generic noun ("sneakers", "coffee"): ask which facet before running.
- Non-Latin-script topic: add `--web-backend brave`; expect little from Reddit/HN/GitHub and say so in the report.

**2. Classify.** QUERY_TYPE = COMPARISON (contains " vs "/" versus "), RECOMMENDATIONS ("best X", "top X", "what X should I use"), NEWS ("what's happening with", "latest on"), PROMPTING ("X prompts", "prompting for X"), else GENERAL. Note TARGET_TOOL if named ("mockups **for Midjourney**") — don't ask for one before research. REGISTER = an explicit `--register` value, else `LAST30DAYS_REGISTER` from config, else default. Then tell the user in one line what you're doing, naming only sources the engine reports available (`"$RUN_SH" --diagnose` prints JSON; use its `available_sources`): `/last30days - searching {sources} for what people are saying about {topic}.`

**3. Resolve targeting.** (If this session has no web-search tool: skip steps 3-4, add `--auto-resolve` to the engine command, and go to step 5.) Use 2-4 batched web searches plus what you already know; verify accounts are the entity's own, not fan/parody accounts, and never guess a handle you couldn't verify.
- **X**: primary handle; the founder's handle for a company topic or the company's for a person topic; 1-2 commentator/media handles that cover the space. → `--x-handle`, `--x-related` (related are searched at lower weight).
- **GitHub**: person who ships code → `--github-user` (scopes search to their PRs, repos, releases). Product/project → `--github-repo owner/repo`. On a person topic, X handle without GitHub user is a half-done resolution.
- **Reddit**: 3-5 subreddits. Subs dedicated to the entity itself → `--dedicated-subreddits` (pulled in full, no relevance filter); mixed communities → `--subreddits`. For a product in a recognizable category, include 2-3 cross-product category subs (image-gen tools get StableDiffusion/midjourney/aiArt; coding agents get ChatGPTCoding/LocalLLaMA) — technique discussion lives there, not only in the brand's own sub. Cap 10 total.
- **TikTok/Instagram**: infer hashtags and creator handles from what you know (`--tiktok-hashtags`, `--tiktok-creators`, `--ig-creators`); don't search for a CEO's TikTok.
- **YouTube**: infer 2-3 content queries (reviews / reactions / interviews) for the plan.
- **Trustpilot** (company/brand topics where review evidence helps): the company's domain, not its name → `--trustpilot-domain` (also activates the source).
- **Positioning** (company/product topics only, never people or ownerless things): fetch the current first-party pitch (homepage tagline, pricing page). Used in synthesis; never quote positioning from memory.
- One search for current news context — it improves the plan below.

Omit any flag you couldn't resolve. Then show a short `Resolved:` block listing what you found (one line per platform, skip empty ones).

**4. Plan.** Write the query plan yourself — you are the planner; no API key is involved. 1-4 subqueries:

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

**5. Run the engine** (foreground, 5-minute timeout), saving stdout to a file so the evidence goes to the synthesis step, not the conversation:

```bash
EVIDENCE="${TMPDIR:-/tmp}/last30days-evidence-$$.md"
"$RUN_SH" "TOPIC" --emit=compact --save-suffix=v3 \
  --x-handle=... --subreddits=... [other resolved flags] \
  --plan - > "$EVIDENCE" <<'EOF'
{ ...your plan json... }
EOF
```

Pass `--days=N`, `--quick`, `--deep`, `--register=...` through when the user asked for them. stderr shows progress and the `[last30days] Saved output to {path}` line — note that saved raw-file path. Exit 3 means the engine asked a clarifying question on stderr: relay it and re-run with the answer folded into the topic.

**6. Web supplements.** Run 2-3 web searches for what the social engine misses — news context, critic/long-form reactions, and one claim worth corroborating (for RECOMMENDATIONS: "best {topic}" roundups; for PROMPTING: technique posts). Exclude reddit.com and x.com. Then append to the saved raw file a `## WebSearch Supplemental Results` section, one bullet per source that informed the report: `- **{Publisher}** ({domain}) - {1-2 sentence takeaway}`. No URLs in the bullets.

Done. Return to SKILL.md's Synthesize step with: the EVIDENCE path, the raw-file path, QUERY_TYPE, and REGISTER.
