# Explore Mode — Full Flow

## Step 1: Load memory

Read all files in `{BITACORA_DIR}` to know what routes and areas have been explored. Build a mental map of coverage gaps.

## Step 2: Plan exploration

Choose routes/areas NOT yet covered. Prioritize:
- Routes never visited
- Routes visited long ago (>1 week)
- Routes where previous issues were found (regression check)

### Route discovery

If no route inventory exists yet, discover routes from:
1. The project's router configuration (e.g., `src/routes/`, `app/`, `pages/`)
2. CLAUDE.md or project documentation
3. Sitemap if available
4. Manual exploration from the main navigation

### Rotation strategy

The checklist (`explore-checklist.md`) has verification categories. Don't try all in every session — rotate focus:

- **Every session**: Categories 1-3 (basic loading, console, layout) — fast, catch regressions
- **Rotate per session**: Pick 2-3 additional categories (e.g., session 1 = dark mode + edge cases, session 2 = inline editing + forms)
- **Log which categories were checked** in the explore file header so the next session picks different ones
- **Prioritize categories not checked recently** (>3 sessions ago)

## Step 3: Launch Playwright exploration

Use Bash to run Playwright scripts that:
- Navigate to each target route
- Check for console errors (`page.on('console')` + `page.on('pageerror')`)
- Take screenshots of each page
- Verify key elements render (no blank pages, no broken layouts)
- Test basic interactions (click buttons, open dropdowns, submit forms)
- Check responsive behavior (desktop + mobile viewport)
- Look for visual issues (overflow, cut-off text, overlapping elements)

### Playwright script pattern

```bash
# Write temp script to TMPDIR, NEVER inside the project tree
cat > "$TMPDIR/explore-session.spec.ts" << 'SCRIPT'
import { test } from '@playwright/test'
// ... exploration code ...
SCRIPT

# Run it
npx playwright test --config {PLAYWRIGHT_CONFIG} "$TMPDIR/explore-session.spec.ts"

# Screenshots also go to TMPDIR
npx playwright screenshot --browser chromium {FRONTEND_URL}/dashboard "$TMPDIR/screenshot-dashboard.png"
```

Use authenticated storage state from `{AUTH_STATE}` for pages that require login.

## Step 4: Log findings

Create a timestamped file in `{BITACORA_DIR}` using the bitacora format from SKILL.md.

## Step 5: Notify

Follow the notification dispatch rule in SKILL.md (channel-first with fallback). Use type `explore`.

In channel mode, attach screenshots from `$TMPDIR/screenshot-*.png`.

## Step 6: Cleanup and exit

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/cleanup-explore.sh
```

Then execute `/clear` to free context. The bitacora files are the persistent memory — the next session re-reads them.

---

## Server Recovery

If servers are down during health check:

1. Stop stale processes: `{DEV_SERVER_STOP}`
2. Restart: `{DEV_SERVER_START} & sleep 10`
3. Check again with curl
4. **If came up** — continue normally
5. **If still down** (compilation error):
   - Capture build output: `{DEV_SERVER_START} 2>&1 | tail -30`
   - Log as critical issue in bitacora (type `funcionamiento`, severity `critica`)
   - Commit bitacora + notify Telegram
   - `/clear` and exit — next autofix cycle picks up the critical issue
