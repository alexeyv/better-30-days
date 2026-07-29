# better-30-days

A rewrite of the prompt layer of [mvanhorn/last30days-skill](https://github.com/mvanhorn/last30days-skill), an agent skill that researches any topic across Reddit, X, YouTube, TikTok, Hacker News, Polymarket, GitHub, and the web, ranked by real engagement.

The upstream Python engine is excellent and is vendored here unchanged (MIT, © Matt Van Horn). What's rewritten is everything the model reads:

| | upstream | this repo |
|---|---|---|
| SKILL.md | 2,255 lines | 116 lines |
| loaded per typical run | 2,255 lines | ~200 lines (SKILL.md + one reference file) |
| shell mechanics | ~300 lines of prompt asking the model to compose portable bash | `scripts/run.sh` (~100 lines of actual bash) |
| synthesis | in the main conversation, guarded by 11 "LAWs" restated at four tiers | a subagent with a fresh context and an 85-line contract |

## Why

The upstream SKILL.md documents its own failure mode: with the full file loaded, the hosting model repeatedly improvised — invented titles, dumped raw evidence, appended forbidden source lists (a documented 0/8 public regression). Each incident was patched with more prompt: repeated rules, positional anchors, forensic narratives. The file's length is the root cause of the failures the length exists to prevent.

This rewrite applies three moves:

1. **Progressive disclosure.** Mutually exclusive flows (setup, discovery, comparison, doctor, HTML export, hiring signals, library) each live in `references/*.md` and load only when routed to.
2. **Deterministic work goes to a script.** Interpreter resolution, config gates, and JSON-on-stdin handling live in `run.sh`. The model passes `--plan -` and pipes JSON; no mktemp/quoting folklore in the prompt.
3. **Synthesis runs in a clean context.** The engine's evidence goes to a file, never into the conversation. A subagent reads the 85-line output contract plus the evidence and returns the report. Nothing competes with the instructions, so they don't need to be shouted.

## Does it work?

Validated against the upstream engine, unmodified:

- Live run: fully compliant report on the first attempt.
- All seven of upstream's recorded eval fixtures (breaking event, comparison, emerging event, niche, CJK, person, tech product) replayed offline and synthesized: **7/7** on every output-contract check — engine version line verbatim, footer byte-identical, correct body shape per query type, no stray headers, no em-dashes, no evidence dumps, no trailing source lists.
- **54/54 (100%) citation grounding**: every linked URL in every report resolves to a URL present in the recorded fixture inputs. The fixtures use synthetic entities on `.test` domains, so a fabricated link could not be right by luck.
- Fixtures with no community comments or prediction markets degraded honestly and said so, instead of inventing quotes.

Engine-side eval metrics (grounding, recency, coherence, coverage, determinism) are unchanged by construction — the engine wasn't touched. Full notes in [NOTES.md](NOTES.md).

## Install / use

The skill keeps the upstream command name, so it acts as a drop-in replacement — don't install both.

Any Agent Skills host:

```
npx skills add alexeyv/better-30-days -g
```

Or point your harness's skills directory at `skills/last30days/`. Then:

```
/last30days <topic>
/last30days trending
/last30days A vs B
```

Subagent-capable harnesses get isolated synthesis; others fall back to inline synthesis with the same contract. Requires Python 3.12+ (run.sh will provision one via `uv` if available).

## Status

An experiment in prompt-layer engineering, built and validated in one session. The engine tracks upstream at v3.18.4; refresh `skills/last30days/scripts/` (except `run.sh`) from upstream to update. Not affiliated with or endorsed by the upstream project.

## License

MIT. Engine and original skill contract © Matt Van Horn; rewritten prompt layer © Alex Verkhovsky. See [LICENSE](LICENSE).
