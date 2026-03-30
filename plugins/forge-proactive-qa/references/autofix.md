# Autofix Mode — Full Flow

## Step 0: Load pending work

1. Read all `{BITACORA_DIR}/*.md` files
2. Collect issues with `Estado: pendiente` or `Estado: fallido` (with < 3 attempts)
3. If no pending work → notify Telegram "Sin trabajos pendientes" → exit
4. Sort by severity (critica > alta > media > baja)

## Step 1: Fix one issue

For each pending issue (one at a time):

### 1a. Record start

Update the issue's Estado to `en-progreso`.

### 1b. Launch fixer agent

Agent tool, subagent_type: general-purpose:

```
Fix the following issue in the web app:

Issue ID: PWI-{id}
Route: {ruta}
Type: {tipo}
Description: {descripción}
Suggested fix: {corrección sugerida}

Rules:
- Never use cd, run everything from project root
- Follow project conventions in CLAUDE.md
- Do NOT commit, just make the code changes
- Do NOT change branch
- Write temp files to $TMPDIR, NEVER inside the project tree
- NEVER use rm to delete files. For cleanup use:
  bash ${CLAUDE_PLUGIN_ROOT}/scripts/cleanup-tmpdir.sh file1.ts file2.png
```

### 1c. Launch validator agent

Agent tool, subagent_type: Explore:

```
Validate that issue PWI-{id} has been fixed:

Route: {ruta}
Original problem: {descripción}
Expected: The problem should no longer be present

Steps:
1. Run: curl -s {FRONTEND_URL} to verify frontend is up
2. Write Playwright scripts to $TMPDIR (NEVER inside the project tree)
3. Use Bash to run the Playwright check on the specific route
4. Verify the original problem is resolved
5. Check for regressions (console errors, visual issues)
6. Run {LINT_CMD} to check no lint errors were introduced
7. Run {TEST_CMD} to check no tests broke
8. Clean up temp files using the cleanup script (NEVER use rm directly):
   bash ${CLAUDE_PLUGIN_ROOT}/scripts/cleanup-tmpdir.sh validate-pwi.spec.ts screenshot.png

IMPORTANT: NEVER use rm to delete files — it triggers permission prompts and breaks automation.
Always use: bash ${CLAUDE_PLUGIN_ROOT}/scripts/cleanup-tmpdir.sh <filenames>

Report: PASS or FAIL with details
```

## Step 2: Process result

### If validator says PASS

1. Update issue in the bitacora file:
   ```markdown
   - **Estado**: arreglado
   - **Historial de intentos**:
     - Intento 1 (YYYY-MM-DD HH:mm): PASS — Resumen de la solución aplicada
   ```

2. Commit:
   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/scripts/commit.sh "fix(proactive-qa): PWI-{id} — {título corto}" {archivos modificados}
   ```

3. Notify: Use type `fix-ok` following the dispatch rule in SKILL.md.

4. Move to next issue.

### If validator says FAIL

1. Increment attempt counter:
   ```markdown
   - **Intentos**: 2/3
   - **Historial de intentos**:
     - Intento 1 (YYYY-MM-DD HH:mm): FAIL — Descripción del fallo
   ```

2. **If attempts < 3**: Launch new fixer agent with original issue + validator's feedback about what went wrong.

3. **If attempts >= 3** (3-step commit-rollback-commit):

   a. Update status:
      ```markdown
      - **Estado**: fallido-revisar-humano
      ```

   b. **Commit 1 — Preserve failed code in history**:
      ```bash
      bash ${CLAUDE_PLUGIN_ROOT}/scripts/commit.sh "wip(proactive-qa): PWI-{id} — intento fallido (código preservado en history)" $(git diff --name-only) $(git ls-files --others --exclude-standard)
      ```

   c. **Rollback code only** (keep bitacora):
      ```bash
      git checkout HEAD~1 -- . ':!{BITACORA_DIR}'
      ```

   d. **Commit 2 — Clean commit with updated bitacora**:
      ```bash
      bash ${CLAUDE_PLUGIN_ROOT}/scripts/commit.sh "docs(proactive-qa): PWI-{id} marcado para revisión humana" {BITACORA_DIR}/
      ```

   e. Notify: Use type `fix-fail` following the dispatch rule in SKILL.md.

   f. Move to next issue.

## Step 3: Loop

Repeat steps 1-2 until all pending issues are processed or context limits are reached.

When done, notify with type `cycle-done` following the dispatch rule in SKILL.md.

Execute `/clear` to free context for next loop iteration.
