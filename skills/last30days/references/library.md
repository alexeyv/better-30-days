# Saved-research library and feed

`uv run --no-cache "$RUN_PY" library feed` builds a local `index.html` and Atom `feed.xml` from saved briefs — offline, no network. Relay the printed paths. That is the whole request unless the user explicitly asks to publish.

Publishing (`--publish`) uploads the library and briefs to ht-ml.app. Before running it: tell the user ht-ml.app pages are public by default and may be crawled or indexed, and offer password protection. On consent, add `--publish`; a password goes through `LAST30DAYS_PUBLISH_PASSWORD` in the environment, never as a visible flag. Relay the printed URL and local Atom path. `feed.xml` stays local — it becomes subscribable only if the user hosts the output directory somewhere static; the ht-ml.app URL is not an Atom subscription URL. Never add `--publish` because someone asked to "open" or "see" their feed.

Fresh research runs may include a `## From your library` block when prior runs overlap the topic — treat those as dated historical context, never as fresh evidence. `LAST30DAYS_LIBRARY_CONTEXT=off` disables the lookup.
