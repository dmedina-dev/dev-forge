# Branching and Checkpoint Strategy

## Branch structure

```
main
 └── flow/<nombre-flujo>                    <- rama de flujo principal
      |
      ├── [tag: checkpoint-wave-00]         <- estado inicial (base)
      |
      ├── plan/<nombre>-wave-01             <- rama de wave (persiste)
      |    ├── commit: test(x): add failing
      |    ├── commit: feat(x): implement
      |    └── commit: refactor(x): cleanup
      |   ↓ merge --no-ff
      ├── [tag: checkpoint-wave-01]         <- checkpoint tras merge
      |
      ├── plan/<nombre>-wave-02             <- rama de wave (persiste)
      |    └── ...
      |   ↓ merge --no-ff
      ├── [tag: checkpoint-wave-02]
      |
      └── plan/<nombre>-wave-03             <- FALLA
           └── <commits parciales>
               (rama queda viva, tag NO se crea)
```

## Rules

1. **Flow branch** `flow/<nombre-flujo>` — created once from main at flow start
2. **Wave branches** `plan/<nombre-flujo>-wave-NN` — created from flow branch at current state
3. **Wave branches persist** after merge — never deleted, kept for forensic inspection
4. **Checkpoint tags** are annotated: `git tag -a checkpoint-wave-NN -m "Wave NN: <resumen>"`
5. **Merges** use `--no-ff` to preserve wave structure in git history
6. **Failed waves**: no tag created, no merge performed. Branch stays with partial commits.

## Checkpoint commands

```bash
# List all checkpoints
git tag -l "checkpoint-wave-*"

# View checkpoint details
git tag -v checkpoint-wave-01

# Diff between checkpoints
git diff checkpoint-wave-01 checkpoint-wave-02

# Diff between checkpoint and current state
git diff checkpoint-wave-02 HEAD

# View wave branch history
git log --oneline plan/<nombre>-wave-01
```

## Rollback commands (manual, user decides)

```bash
# Option A: Hard rollback to checkpoint
git checkout flow/<nombre-flujo>
git reset --hard checkpoint-wave-NN

# Option B: Inspect failed wave
git checkout plan/<nombre>-wave-NN
git log --oneline
git diff checkpoint-wave-<NN-1> plan/<nombre>-wave-NN

# Option C: Cherry-pick specific commits from failed wave
git checkout flow/<nombre-flujo>
git cherry-pick <commit-sha>
```

## Cleanup (after flow is merged to main)

```bash
# Delete wave branches (only after PR merged)
git branch -D plan/<nombre>-wave-*

# Delete checkpoint tags (optional, can keep for history)
git tag -d checkpoint-wave-*

# Delete flow branch
git branch -D flow/<nombre-flujo>
```

## PR creation

```bash
# From flow branch to main
gh pr create --base main --head flow/<nombre-flujo> \
  --title "<feature>" \
  --body "## Waves executed\n- Wave 01: ...\n- Wave 02: ...\n\n## Checkpoints\n..."
```
