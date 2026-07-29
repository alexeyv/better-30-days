# last30days — re-engineering sketch: progressive disclosure + subagents

*Dive note, 2026-07-29. Hypothesis under discussion: the ~2,255-line SKILL.md can be
~10x smaller and considerably better. Conclusion from reading the current design: yes —
the length is the root cause of the failures the length exists to prevent (their own
v3.0.8 note admits the model couldn't reach the output contract at line 1094; the fix
was hoisting + repetition, i.e. more length). Target: re-engineer for progressive
disclosure and subagent isolation.*

## Diagnosis (what the 2,255 lines are)

| Category | ~Lines | Problem |
|---|---|---|
| Mutually exclusive branches (setup wizard, discovery, comparison, doctor, HTML brief, agent mode, hiring signals) | ~1,100 | A query hits exactly one; all eight load every time |
| Shell mechanics + portability folklore (SKILL_DIR resolution ×2, mktemp/`noclobber`/BSD essays ×2, uv fallback, STEP 0 stale-clone check) | ~300 | Deterministic logic asked of a probabilistic engine |
| War stories / changelog-in-prompt (0/8 regression forensics, dated test runs, line-number archaeology) | ~250 | Audience is contributors; belongs in `docs/solutions/` |
| Defensive repetition (LAW 1 "reinforced at four tiers", badge restated, anti-improvisation preface) | ~200 | Arms race against attention dilution caused by the file's own length |
| Actually-needed core (invoke, intent parsing, resolution, plan, synthesis contract) | ~400 | Keep, compress |

## Target architecture

### 1. Always-loaded SKILL.md → ~150–200 lines
- Frontmatter (unchanged — this is all any host loads pre-trigger).
- 15-line output contract summary (badge + compressed LAWs as rules, zero history).
- Intent router: classify query → GENERAL / COMPARISON / DISCOVERY / SETUP / DOCTOR /
  HTML / HIRING → `Read references/<branch>.md` for the one branch that applies.
- Core path: preflight → resolution → plan → `scripts/run.sh` → synthesize (or dispatch
  synthesis subagent, below).

### 2. Shell mechanics → `scripts/run.sh` wrapper (~50 lines of bash)
Resolves SKILL_DIR, performs the stale-clone self-check deterministically, writes the
plan tmpfile (mktemp dance, apostrophe-safe), invokes the engine, streams the envelope.
The model calls one script with args. Deletes ~300 prompt lines and is *more* reliable
than a model transcribing portability folklore. (STEP 0 stops being a prompt at all.)

### 3. Branches → `references/*.md`, loaded just-in-time
`setup.md` (first run only — currently ~185 always-loaded lines for a once-per-install
event), `discovery.md`, `comparison.md`, `doctor.md`, `html-brief.md`, `hiring.md`.
The project already has the mechanism (`references/save-html-brief.md` exists — exactly
one file); this generalizes it. War stories move to `docs/solutions/`, which already
exists and is the right home.

### 4. Synthesis → a subagent (the key move)
Current design: synthesis happens in the main context, competing with the whole session
— which is precisely where instruction-following degrades, hence the LAWs, the badge
anchor, the hoisting. Target design:

- Main agent runs `run.sh`, gets the evidence envelope **into a file, not into context**.
- Dispatches a synthesis subagent whose entire prompt = the ~60-line synthesis contract
  + the envelope path. Fresh context, nothing to dilute it, nothing to improvise against.
- Subagent returns the finished brief; main agent relays it. "Relay the subagent's
  report" is natural model behavior — unlike "pass through script output verbatim,"
  which took four tiers of LAW reinforcement and still went 0/8 on v3.0.6.

Side benefits:
- 30–50k tokens of raw evidence never enter the main conversation at all — the user's
  session stays clean after the skill finishes.
- The engine's #727 mechanism (synthesis contract echoed at the top of its own stdout —
  just-in-time, adjacent to data, immune to file-length attrition) becomes the *only*
  place output rules live. Single source of truth, enforced at the seam.
- Comparison mode fan-out: one research subagent per entity, envelopes merged by a
  final synthesis subagent — parallel, and no entity's evidence crowds out another's.

### 5. Discovery protocol → natural subagent fit
The v3.18.0 three-leg host-judged protocol (nominate → host judges → finalize) already
persists handoff checkpoints to disk. Legs map to subagents directly: the judge leg is
a subagent given only the fenced judging digest. The checkpoint files (identity-bound,
TTL-bound) already solve the state-passing problem — the design anticipated this
without generalizing it. LAW 11 ("YOU ARE THE JUDGE") extended: *a* host model is the
judge; it needn't be the one holding the user's conversation.

## Caveats
- **Subagent availability varies by harness.** No standard Agent Skills primitive for
  dispatch. Mitigation: capability-detect; the inline path (current behavior, but with
  the slim file + JIT contract) is the fallback. Claude Code, Codex, Cursor, Copilot —
  the major hosts — all have some task/subagent facility.
- **File-hop reliability.** The LCD argument for front-loading ("some host might not
  follow a `Read references/x.md` hop") is weak: the current design already depends on
  faithful top-to-bottom execution of a 2,255-line program, a strictly harder ask, and
  empirically fails at it.
- **Don't rewrite from scratch.** Hundreds of lines encode real platform behavior and
  named regressions. This is a distillation/refactor of the existing contract, with
  `docs/solutions/` absorbing the history — not a fresh start.

## Cheap validating experiment
Take one recorded eval fixture (`tests/eval/fixtures/person/`), run the engine to get
the envelope, hand it to a fresh-context model with only the ~60-line synthesis
contract, and compare the brief against the full-pipeline + full-SKILL.md output.
Directly tests both claims (compliance and quality) for the cost of one run.

## Validation (2026-07-29, this session)

Rewrite implemented at `rewrite/` (SKILL.md 116 lines; ~200 lines loaded on a
standard run vs 2,255). Validated against the untouched clone via
`LAST30DAYS_ENGINE`:

- run.sh: interpreter resolution, first-run gate, `--diagnose`, JSON-on-stdin
  (`--plan -` with apostrophes in ranking strings) all work; the mktemp/
  noclobber/heredoc prompt folklore is fully replaced by ~100 lines of bash.
- Live run (`Claude Code`, `--quick`): evidence captured to file, never enters
  the main conversation; synthesis subagent (fresh context, 85-line contract)
  produced a fully compliant report on the first try.
- Seven-fixture matrix: replayed all `tests/eval/fixtures/*` offline through
  the harness's own replay machinery, rendered compact evidence, and ran one
  synthesis subagent per archetype. 7/7 pass on: first line verbatim, footer
  byte-identical, body shape per query type, no stray headers, no em-dashes,
  no evidence dumps, no trailing Sources, ends at invitation. URL grounding
  54/54 (100%) - zero fabricated links against synthetic fixture URLs the
  model could not have known. The person fixture (no comments, no markets)
  degraded honestly and disclosed it.
- One contract bug found and fixed: the "say which check the data couldn't
  satisfy" instruction conflicted with "nothing after the invitation"; the
  note is now pinned to just before the invitation.

Engine-side eval metrics (grounding/recency/coherence/coverage/determinism)
are computed below the prompt layer and are unchanged by construction.
