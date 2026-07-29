# First-run setup

Runs once, ever. ~30 seconds. The engine's `setup` command does only mechanical work (cookie reads, CLI installs, GitHub device auth) and cannot prompt — every consent below happens in the conversation, before the command runs. If your harness has a structured-question tool, use it for each choice; otherwise ask in chat and wait for the answer.

Config file: `~/.config/last30days/.env`. Append-only, always: read first, add missing keys with `>>`, create with `mkdir -p ~/.config/last30days && touch ...` if absent, never truncate.

**1. Welcome + mode.** Ask, including the pitch in the question itself:

> Welcome to /last30days! I research any topic across Reddit, X, YouTube, TikTok, Digg, arXiv, Techmeme, HN, Polymarket & more - pulling what people actually said in the last 30 days. How would you like to set up?
> - **Auto setup (~30s)**: scan browser cookies for X + install yt-dlp (YouTube), Digg, arXiv, Techmeme. Reddit/HN/Polymarket/GitHub/Web work with no setup.
> - **Manual setup**: show each source and credential to configure by hand.
> - **Skip for now**: just the free no-setup sources.

(On hosts without a modal question tool, first run `"$RUN_SH" --welcome` and show its stdout verbatim, then ask.)

- **Skip** → append `SETUP_COMPLETE=true` to the config file (so this never re-fires) and go to step 5.
- **Manual** → show the manual guide (step 4), then step 5.
- **Auto** → step 2.

**2. Cookie consent (Auto).** If `BROWSER_CONSENT=true` is already in the config file, run `"$RUN_SH" setup --allow-browser-cookies` without asking. Otherwise ask: reading x.com cookies is the only part needing an OK — Chrome first (one-time macOS Keychain prompt; click Always Allow), then Firefox/Safari; cookies are read live, never written to disk. Options:
- Yes → `"$RUN_SH" setup --allow-browser-cookies`; append `BROWSER_CONSENT=true` after.
- No, CLIs only → `FROM_BROWSER=off "$RUN_SH" setup`
- xAI key instead → take the key, append `XAI_API_KEY=...`, then `FROM_BROWSER=off "$RUN_SH" setup`

Report what setup found and installed, including whether the Digg CLI landed on PATH (active) or off-PATH (installed, not yet active). If stderr shows `Permission denied reading Cookies.binarycookies` on macOS: only the Safari fallback needs Full Disk Access — if their x.com login is in Chrome they don't need it; otherwise System Settings → Privacy & Security → Full Disk Access → enable the terminal, then offer one retry.

**3. ScrapeCreators offer (every first run).** Adds TikTok + Instagram (posts and top comments) and YouTube comments; also backfills Reddit search when the free path returns nothing, and backs up YouTube transcripts when yt-dlp is throttled. 10,000 free calls, no card; the GitHub signup grants more free calls than the web form. Ask; options:
- **GitHub signup** → run `"$RUN_SH" setup --github-start` in the foreground (returns in ~2s). If `status=="already_registered"`: say their existing key is active; stop. Otherwise immediately show the `user_code` from the output: it's on their clipboard, paste it on the GitHub page that opened. Then run `"$RUN_SH" setup --github-poll` (5-min timeout) and read the **last** JSON line:
  - `success` + `persisted: true` → confirm active. (Key is masked; never ask for or echo a raw key.)
  - `success` + `persisted: false` → signup worked but saving failed; have them add `SCRAPECREATORS_API_KEY=...` manually.
  - `error: "Authorized but failed to fetch API key"` → GitHub auth was fine; their account is probably already linked. Have them paste the key from scrapecreators.com, or skip.
  - timeout/other error → offer retry or the web signup.
- **Web signup** → open https://scrapecreators.com, take the pasted key, append it.
- **Has a key** → append it.
- **Skip** → continue; free sources still work.

**3b. Source width (only if a key was saved).** Comments are default, never opt-in. Ask: recommended (TikTok + Instagram + all comments) or everything (also Threads + Pinterest, more credits)?
- recommended → append `INCLUDE_SOURCES=tiktok,instagram,youtube_comments,tiktok_comments,instagram_comments`
- everything → same list plus `,threads,pinterest`

**4. Manual guide** (Manual choice, or on request). Show as text:
- X (most important, pick one): `FROM_BROWSER=auto` (free, live cookie read) | `XAI_API_KEY` (api.x.ai) | `XQUIK_API_KEY` | `AUTH_TOKEN` + `CT0` pasted from browser devtools.
- Reddit: free out of the box (RSS + shreddit, real scores and comments). Optional `SCRAPECREATORS_API_KEY` backfill.
- YouTube: `brew install yt-dlp` (or pip).
- Digg: `npx @mvanhorn/printing-press-library install digg --cli-only` (needs `digg-pp-cli` on PATH).
- GitHub: automatic when `gh` is installed and authed.
- TikTok/Instagram/comments: `SCRAPECREATORS_API_KEY` + `INCLUDE_SOURCES=tiktok,instagram`.
- Optional: `PERPLEXITY_API_KEY`, `BSKY_HANDLE`+`BSKY_APP_PASSWORD`, `BRAVE_API_KEY`/`EXA_API_KEY`, `XIAOHONGSHU_API_BASE`.
Finish by appending `SETUP_COMPLETE=true`.

**5. Done.** Ensure `SETUP_COMPLETE=true` is in the config file. If the user already gave a topic, research it now. If not, offer example first topics (a tech comparison, a person in the news, a sport, a niche) or their own.
