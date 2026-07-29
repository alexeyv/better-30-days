# Doctor (source health)

`"$RUN_SH" doctor` audits every source into four states — WORKING (verified), TURNED ON - UNVERIFIED (configured, no run evidence), NOT WORKING (configured but failing), COULD BE ON (available, unconfigured) — plus CLI health and backup/comment sub-lanes, with a fix prescription per problem. Relay the audit and prescriptions.

Variants:
- `doctor --postmortem` — reads the last run's report and says what actually broke per source. Use right after a run that returned fewer results than expected.
- `doctor --probe` — bounded live test of free/keyless sources (never spends credits). A plain `doctor` auto-probes when there's no recent run.
- `doctor --cached --json` — the cached report (TTL ~15 min) for one file-read's cost. Check it before research that depends on login-backed sources (X cookies, Reddit backfill); run live `doctor` only if the cache is stale or shows a degraded login-backed source.
- `--diagnose` — JSON of resolved providers and `available_sources`; the authoritative list of what's active (credentials resolve from env, config, and Keychain at runtime — never infer availability by reading `.env` yourself).
