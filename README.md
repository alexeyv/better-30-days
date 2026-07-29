# better-30-days

`/last30days` — research any topic through what people actually said about it in the last 30 days: Reddit threads with real upvote counts, X posts, YouTube transcripts, TikTok, Hacker News, Polymarket odds, GitHub activity, and the web, ranked by engagement and synthesized into one cited brief.

This is a fork of [mvanhorn/last30days-skill](https://github.com/mvanhorn/last30days-skill). **The research engine is the original, vendored unchanged** (v3.18.4, MIT, © Matt Van Horn). What's different is the instruction layer your agent reads — rewritten to be about 10x smaller. If you're looking for the original project, its docs, or its community, go to the link above. If you want the same tool with a much lighter footprint in your agent's context, you're in the right place.

## What you get

Same commands, same engine, same output format:

```
/last30days Peter Steinberger          # person: their posts, PRs, what people say about them
/last30days nvidia earnings reaction   # topic across all sources
/last30days OpenClaw vs Hermes         # side-by-side comparison
/last30days trending                   # what's accelerating right now
/last30days what's exploding in AI agents
```

Zero-config sources out of the box (Reddit with comments, HN, Polymarket, GitHub, web). A first-run setup takes ~30 seconds and unlocks X, YouTube, TikTok, and more. Same optional keys, same `~/.config/last30days/.env`, same saved briefs in `~/Documents/Last30Days` — configs from the original carry over as-is.

## How this fork differs

The original loads a 2,255-line instruction file into your agent's context on every single run. This fork loads about 200:

| | original | this fork |
|---|---|---|
| instructions loaded per run | 2,255 lines, all flows every time | 116-line core + only the file for your flow (setup, trending, comparison, ...) |
| shell plumbing | the agent assembles portable bash from instructions | one `run.sh` script does it deterministically |
| report writing | in your main conversation, competing with everything else in it | in a separate agent with a clean context (falls back to inline on hosts without subagents) |
| raw evidence | passes through your conversation | goes to a file; only the finished report reaches you |

Practical effects: less of your context window spent on the tool, faster starts, your conversation stays clean after a run, and the report format is more reliably followed — the original's format rules exist because agents kept breaking them under a 2,255-line load; a small contract in a clean context doesn't need enforcing.

Tested against the original's own recorded eval fixtures (all seven topic archetypes, replayed offline through its eval harness): 7/7 compliant reports, and 100% of citations grounded in the actual retrieved evidence — no invented links. Details in [NOTES.md](NOTES.md).

## Install

Works on any [Agent Skills](https://agentskills.io) host that can run bash and Python 3.12+ (Claude Code, Codex, Cursor, Copilot, Gemini CLI, ...):

```
npx skills add alexeyv/better-30-days -g
```

Or copy `skills/last30days/` into your harness's skills directory. The command name is `/last30days`, same as the original — it's a drop-in replacement, so **install one or the other, not both**.

Run it once and the setup wizard offers the optional unlocks (browser-cookie X auth, yt-dlp for YouTube, a free ScrapeCreators key for TikTok/Instagram). Everything is opt-in and consent-asked; `run.sh --preflight` prints exactly what the tool reads and writes.

## When to use the original instead

- You want the marketplace auto-update channel, the MCP server, or the newest engine features the moment they ship — this fork tracks upstream manually (currently v3.18.4).
- You want upstream support and issue triage. This fork is an independent experiment, not affiliated with or endorsed by the original project. Engine bugs belong upstream; instruction-layer issues belong here.

## License

MIT. Engine and original skill © [Matt Van Horn](https://github.com/mvanhorn); rewritten instruction layer © Alex Verkhovsky. See [LICENSE](LICENSE).
