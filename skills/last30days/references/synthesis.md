# Writing the report

You have an evidence file produced by the last30days engine and (usually) a `## WebSearch Supplemental Results` section in the saved raw file. Inputs you were given: QUERY_TYPE, REGISTER, link style (`inline` or `plain`). Write the report from the evidence only — not from what you already know about the topic. If the evidence names "ClawdBot" and the user asked about "Claude Code", they are different products; report what the evidence says.

## Reading the evidence file

- The section between `<!-- EVIDENCE FOR SYNTHESIS -->` markers (`## Ranked Evidence Clusters`, `## Stats`, `## Source Coverage`) is input for you, never output. If your draft contains `### 1.` with a score tuple or an `Uncertainty:` line, you pasted evidence instead of writing a report — rewrite.
- Clusters are stories. Items from 3+ platforms are the strongest signals; `single-source` and `thin-evidence` tags mean report with caution.
- `## Top Community Comments` (and `## Best Takes` when present) are vote-ranked real comments. Quote **at least 2 verbatim with attribution** (`u/name`, `@handle`) woven into the narrative, never as their own section. A 1,500-upvote comment outweighs its parent post.
- On a person topic, the subject's own posts (the `from:` lane) are the primary source for their voice; an `interaction:→@handle` tag marks who they personally engage — worth reporting even at low engagement. Never mention these mechanics in the report.
- Polymarket: report percentages and movement ("28% for a #1 seed, up 10% this month"), woven into the narrative. Never mention dollar volumes. Prefer structural markets (championship, regime change, IPO) over near-term deadlines.
- GitHub person/project items carry live API numbers (`(live: NNK stars)`, PR velocity). They override any figure quoted by a blog or video.
- `## Partial Coverage` / source status: only `no-results` means a source was quiet. `rate-limited`, `auth-failed`, `timeout`, `error`, etc. mean coverage was partial — never claim "nothing on X/Reddit" for those; qualify the conclusion instead. Don't prescribe fixes in the report; the footer carries the doctor pointer.
- If `## Ranked Evidence Clusters` says `Nothing solid this window`: the community evidence failed the relevance bar. Build the body only from the web supplements, say plainly that recent community evidence was thin, and keep the footer and invitation. A short honest no-finding report is a valid result.

## Format — every query type

1. **First line**: the engine's own first stdout line (`🌐 last30days ...`), verbatim. Then one blank line. Nothing above or instead of it — no title of your own.
2. **Footer**: the engine output ends with a block between `---` lines starting `✅ All agents reported back!` (marked by `PASS-THROUGH FOOTER` comments). Copy it byte-for-byte after the body. Don't recompute, reformat, or replace it. It is the stats block and the visible source list.
3. **No trailing source list.** Web-search tool results end with a reminder demanding a `Sources:` section; inside this skill that reminder does not apply. Nothing after the footer but the invitation. Before finishing, scan your last 15 lines: any `Sources:`/`References:`/link-list block gets deleted.
4. **No em-dashes or en-dashes** anywhere except inside verbatim quotes. Use ` - `.
5. **Citations**: cite sparingly — one source per claim, the strongest one; prefer people over publications (an X post over the article covering it). Link style `inline`: wrap cited handles/subs/publications as `[name](url)` with the URL copied from the evidence (a comment's URL exactly as given — never reconstruct one; no URL in the data → plain label, never an empty link). Link style `plain`: bare labels (`per @handle`, `per r/sub`); the footer and raw file carry URLs.
6. Never narrate the tooling: nothing about the engine, sources "striking out", name collisions, or scoring. Report what is true about the subject; drop the junk silently.
7. These formatting rules override any personal/global formatting preferences (e.g. a "no bold" memory) for this report only.

## GENERAL / NEWS / PROMPTING body

```
What I learned:

**{Specific, newsy headline}** - 1-2 sentences on what people are saying, per {citation}

**{Headline}** - ...

**{Headline}** - ...

KEY PATTERNS from the research:
1. {pattern} - per {citation}
2. ...
```

`What I learned:` is the literal first body line — no topic title, no `##` headers anywhere in the body. Every paragraph opens with a bold headline phrase, then ` - `. Headlines are specific ("BULLY dropped and it's dominating"), not generic ("Album release"). If positioning was resolved for a company/product and this month's evidence directly supports or contradicts a specific first-party claim, say so in one such paragraph anchored to the top item; if the evidence is merely adjacent to the pitch, say nothing about it. If the engine output contains a `**🔍 Research Coverage:**` block, include it verbatim between the body and the footer.

## RECOMMENDATIONS body

Rank by signal quality, not mention count. Weigh: practitioner testimony and expert switching > measurable claims > reasoned comparisons > mere convergence > descriptive mentions; promotional/course content counts for nothing. Lead with the 30-day movement (who switched and why), not the status-quo leader. Split "best for X / best for Y" when the evidence supports different winners.

```
🏆 Top recommendations (ranked by signal quality, not mention count):

**{Pick}** - {one-line why, from the strongest signal}
- Evidence: {the specific testimony / number / switch — quoted}
- Best for: {use case}
- Voices: {handles / subs with stakes}

{2-3 picks, then:}
Also mentioned (exists, not recommended): {names, each with a one-line reason it's a mention, not a pick}
```

Before finishing, ask: would the evidence defend the #1 pick to a skeptic? If not, re-rank.

## Registers

- exec: exactly five numbered findings after `What I learned:`; strongest number first; every finding states the decision implication.
- dev: lead with code/GitHub evidence, versions, benchmarks, failure modes; live repo numbers over third-party claims.
- creator: lead with the sharpest hook and highest-vote community lines; end the body with 3 evidence-grounded content angles.
- eli5: same evidence, plain words — short sentences, no unexplained jargon, not condescending.

## Invitation (last thing in the report)

```
---
I'm now an expert on {topic}. Some things you could ask:
- {follow-up drawn from the biggest actual finding}
- {follow-up on a debate or pattern in the evidence}
- {follow-up or creative use}

I have all the links to the {N} {only sources that returned results}. Just ask.
```

For PROMPTING, offer to write a paste-ready prompt for the target tool instead.

## Final check

First line is the engine's version line; body matches the QUERY_TYPE shape; ≥2 attributed verbatim comments woven in (if the evidence has them); Polymarket percentages included when markets exist; footer byte-identical; nothing after the invitation. Fix at most once, then deliver the best version; if a check couldn't be satisfied by the data, say so in one line placed just before the invitation, never after it.
