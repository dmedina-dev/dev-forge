# Operational notes — forge-proactive-qa

Consumer-side gotchas for running this plugin autonomously. SKILL.md has a
one-paragraph summary; this is the long form.

## Sandbox — temp file writes silently fail on macOS

**Symptom.** Explore mode appears to run but produces nothing: heredocs
writing Playwright specs to `$TMPDIR` return `rc=1`, `npx playwright test`
can't find the spec, no screenshots appear. All plugin scripts use
`trap 'exit 0' ERR`, so nothing aborts loudly — the loop just spins
producing empty results.

**Root cause.** Claude Code's Bash sandbox blocks writes to paths outside
the current project root. The skill mandates writing all temp scripts and
screenshots to `$TMPDIR` — on macOS that resolves to
`/var/folders/<xx>/<yyy>/T/`, which is outside the project and therefore
blocked. The fallback `/private/tmp/claude/` is blocked for the same reason.

**Diagnosis.**

```bash
echo test > "$TMPDIR/proactive-qa-probe"; echo "rc=$?"
cat "$TMPDIR/proactive-qa-probe"
```

If `rc=0` and the readback is `test`, the sandbox is NOT the problem.
If `rc=1` or the readback fails, you're being sandboxed.

**Fix A — sandbox allowlist (recommended).** Resolve your real temp dir
first (`echo "$TMPDIR"` — it is per-user and dynamic on macOS), then add
both it and the fallback to the project's `.claude/settings.local.json`.
If a `sandbox.filesystem.allowWrite` list already exists, **merge** —
don't replace:

```json
{
  "sandbox": {
    "filesystem": {
      "allowWrite": [
        "/var/folders/<xx>/<yyy>/T/",
        "/private/tmp/claude/"
      ]
    }
  }
}
```

Replace `/var/folders/<xx>/<yyy>/T/` with the output of `echo "$TMPDIR"`.

### Write surface

Everything the plugin writes outside the project root:

| Path | Written by | Purpose |
|---|---|---|
| `$TMPDIR/explore-*.spec.ts` | explore mode (skill + subagents) | Generated Playwright explore specs |
| `$TMPDIR/explore-*.ts` | explore mode | Helper scripts |
| `$TMPDIR/screenshot-*.png` | Playwright runs | Screenshots referenced in notifications |
| `/private/tmp/claude/` (same patterns) | all of the above | Fallback when `$TMPDIR` is unset |

Note: `cleanup-explore.sh` and `cleanup-tmpdir.sh` delete from the same
directory, so the allowlist entries above cover them too.

### Paths that do NOT need allowlisting

| Path | Why |
|---|---|
| `.proactive-qa-cycle` (project root, via `cycle-state.sh`) | Inside the project root — sandbox allows it |
| `{BITACORA_DIR}/*.md` | Inside the project root |
| `commit.sh` (git operations) | Operates on the project repo |
| `telegram-notify.sh` | Writes nothing — only **reads** `~/.claude/channels/telegram/.env` (and legacy `.env` fallbacks) and sends via curl |

**Fix B — project-local tmp dir.** If you can't edit the sandbox config
(shared settings, org policy), redirect temp files into the project root
so they're naturally inside the sandbox:

```bash
mkdir -p .proactive-qa-tmp
export TMPDIR="$PWD/.proactive-qa-tmp"
```

Add `.proactive-qa-tmp/` to `.gitignore` (temp files inside the tree
pollute the repo and can break lint if not ignored).

**Fix C — disable the sandbox for the session.** In
`.claude/settings.local.json`:

```json
{ "sandbox": { "enabled": false } }
```

Use only if you don't otherwise rely on the sandbox for safety.
