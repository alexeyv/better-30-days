# Comparison runs ("A vs B", --competitors)

The engine researches each entity in parallel with its own targeting. Your job: resolve targeting for **every** entity, not just the first.

`--competitors` (no names given): find 2 peers via web search ("{topic} alternatives"), or N peers for `--competitors=N`, then proceed as a normal vs-run with the names you found.

## Targeting

Resolve the standard.md step-3 stack (X handle, founder handle, GitHub repo, subreddits, and — for companies — Trustpilot domain and positioning) for each entity, batching searches across entities ("A B C founders twitter handles" — 3 searches cover 12 lookups). Show a `Resolved (comparison):` block with one line per entity; a dash-filled line means you skipped that entity — fix it before running.

Entity A (first in the vs-string) takes the normal outer flags. Every other entity's targeting goes in a `--competitors-plan` JSON keyed by entity name (the engine does not read entity A from the plan, so A's Trustpilot domain must be the outer flag):

```bash
EVIDENCE="${TMPDIR:-/tmp}/last30days-evidence-$$.md"
"$RUN_SH" "A vs B vs C" --emit=compact --save-suffix=v3 \
  --x-handle={A_handle} --subreddits={A_subs} [other A flags] \
  --competitors-plan - > "$EVIDENCE" <<'EOF'
{
  "B": {"x_handle": "...", "subreddits": ["..."], "github_user": "...", "trustpilot_domain": "...", "context": "one-line disambiguator"},
  "C": {"x_handle": "...", "subreddits": ["..."], "context": "..."}
}
EOF
```

No `--plan` on comparison runs. `--competitors-list="A,B,C"` exists as a names-only fallback but produces visibly thinner peer data — use the plan. Up to 7 entities total; the engine warns on stderr about any it drops.

Then run 2-3 web supplements for the rivalry itself ("A vs B comparison {year}", "A vs B which is better") and append them to the raw files. Comparison runs save one raw file per entity — the stderr line `[last30days] Comparison artifact set: main=...; peers=...` lists them; append the supplements section to each.

## Report format

Hand the synthesis (subagent or inline) references/synthesis.md **plus this section**. Comparison replaces the GENERAL body shape entirely — no `What I learned:`, no KEY PATTERNS. All other synthesis.md rules hold (engine first line, footer verbatim, no trailing sources, comments woven in, citation style). These `##` headers — and only these — are required:

```
{engine's first line}

# {A} vs {B} [vs {C}]: What the Community Says (/Last30Days)

## Quick Verdict
One paragraph: competitors or layers of a stack? who leads, who challenges? Comparable scale numbers inline. End on one quotable community line.

## {Entity}            (one section per entity)
**Community Sentiment:** {Positive/Mixed/...} ({N}+ mentions across {sources})
{Optional single sentence when this month's evidence directly supports or contradicts the entity's fetched pitch — anchored to a real item; otherwise nothing.}
**Strengths (what people love)** - 3 bullets, each cited
**Weaknesses (common complaints)** - 2 bullets, each cited

## Head-to-Head
The engine emits an empty table scaffold (rows: What it is, GitHub stars, Philosophy, ... Best for, Install). Fill each cell with 5-15 words; "N/A" where an axis doesn't apply. Ground "What it is" in each entity's fetched current pitch, never memory. Prefer live GitHub numbers.

## The Bottom Line
**Choose {Entity} if** {use case / tradeoff} — one supporting cited sentence. One per entity.

## The emerging stack
One paragraph naming the combination pattern the community is converging on, cited. If none: "No emerging stack pattern has crystallized in the research window yet."

{footer verbatim}

I've compared {A} vs {B} using the latest community data. Some things you could ask:
- Deep dive into {entity} alone with /last30days {entity}
- {follow-up on a specific claim or table row}
```

Weight long-form blog comparisons from the web supplements equally with social data here — a thorough comparison article beats fifty one-line tweets. A cluster of independent replies all recommending the same thing is the strongest endorsement signal; say so when you see one.
