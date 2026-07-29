# Shareable HTML brief

Applies only when the user asked for HTML — an argument like `--emit=html`/`--html`, or phrasing like "shareable brief", "export as HTML", "for Slack/Notion". Never save HTML unasked.

Two modes:
- **HTML as the deliverable** ("give it to me in HTML"): draft the synthesis, render the HTML, and hand off the file — don't paste the full report to chat too.
- **Report plus HTML copy**: emit the normal chat report first, then render the same text to HTML in the same turn.

Flow:

1. Write the synthesis body **verbatim** to a temp file — the `What I learned:` (or comparison) body and KEY PATTERNS only; no engine first line, no footer (the engine adds both when rendering). Same text, same citations as the chat report; do not paraphrase.

2. Render, passing the same scope flags as the research run (`--plan`, `--hiring-signals`, resolved handles/subs — they keep the footer aligned; on a same-topic follow-up the engine reuses its cached report instead of refetching):

```bash
SLUG="{topic lowercased, non-alphanumerics to hyphens}"
HTML_PATH="$LAST30DAYS_MEMORY_DIR/$SLUG-brief.html"
[ -f "$HTML_PATH" ] && HTML_PATH="$LAST30DAYS_MEMORY_DIR/$SLUG-brief-$(date +%F).html"   # don't overwrite an earlier brief
"$RUN_SH" "{TOPIC}" --emit=html --synthesis-file "$SYNTHESIS_FILE" {scope flags} > "$HTML_PATH"
```

3. Hand off: give the absolute path; open it locally if the host can and the user wants to view it now. Do not add warnings, debug headers, or safety notes to the file.

4. Hosted sharing only on explicit request: `--publish-html` uploads to ht-ml.app — public by default, may be indexed; offer password protection first (`LAST30DAYS_PUBLISH_PASSWORD` in the environment, never a visible flag). Relay the printed URL. Never publish by default, and never block creating the local file on the hosting decision.
