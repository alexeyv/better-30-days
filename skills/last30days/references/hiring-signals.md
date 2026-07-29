# Hiring signals (--hiring-signals)

Reads a company's own job board as evidence of strategic focus. Strongest for early-stage companies; at big companies most roles are noise — say so when it applies.

Run: `"$RUN_SH" "{Company}" --emit=compact --hiring-signals` plus normal resolved flags. It searches the jobs source only, so skip the multi-source query plan (it would be discarded). If the user wants hiring signals *and* community sentiment in one run, add an explicit `--search=reddit,x,jobs`. During resolution, if you find the company's ATS board URL (jobs.ashbyhq.com/..., greenhouse, lever), note it — the engine's careers-page discovery will use it.

The output records which tier produced the data: `ats` (authoritative, the company's own board), `careers-jsonld` (structured page data), or `web` (aggregator fallback — noisy). Weight confidence accordingly and say when the run fell to `web`.

Report: engine first line, blank line, then `# {Company} - Hiring Signals` (this scoped title replaces `What I learned:`), then the synthesis, then the engine's `## Hiring Signals` evidence block, footer, invitation. All other synthesis.md rules hold.

Judging the postings:
- Weight novelty over count. Five engineers in the core area = scaling ("doubling down"). Two roles in a domain the company has never touched = a new bet — usually the bigger story. The `Strategic single-role signals` list (founding / first-of-function / new-geo roles) is not count-gated; judge its novelty yourself.
- Signal language only: "leaning into", "investing in", "increased focus". Evidence, then interpretation: "3 roles mention SOC 2 and procurement — an enterprise-readiness push", never "they will ship SSO next quarter".

In a standard (non-flagged) company run, mention hiring only if the engine surfaced a strong signal; otherwise omit the subject entirely.
