# Wave Plan Format

Plans produced by `writing-plans` (Superpowers) must follow this structure to be accepted by the executor.

## Required structure

```markdown
# Plan: <nombre-flujo>

## Metadata
- Goal: <objetivo global>
- Architecture: <decisiones arquitectonicas>
- Tech Stack: <stack>
- Waves: <count>

## Wave 01: <nombre>
**Objetivo**: <que produce esta wave>
**Depends-on**: [] | [wave-00]
**Baseline-tests**: `<comando que debe pasar ANTES de iniciar>`

### Task 1.1: <nombre>
- Files: <paths exactos>
- Steps:
  1. [RED] Escribir test: <path/to/test>
  2. [VERIFY-RED] Ejecutar `<cmd>` -> esperado: "FAIL: <mensaje>"
  3. [GREEN] Implementar: <path/to/code>
  4. [VERIFY-GREEN] Ejecutar `<cmd>` -> esperado: "PASS"
  5. [COMMIT] `<type>(<scope>): <msg>`

### Task 1.2: ...

## Wave 02: <nombre>
**Depends-on**: [wave-01]
...
```

## Validation rules

### Metadata (required)
- `Goal`: one sentence, actionable
- `Architecture`: key decisions (patterns, layers, boundaries)
- `Tech Stack`: languages, frameworks, versions
- `Waves`: integer matching actual wave count

### Per wave (required)
- `Objetivo`: what this wave produces (testable outcome)
- `Depends-on`: array of wave IDs or empty array for first wave
- `Baseline-tests`: command that must PASS before wave starts (validates prior state)

### Per task (required)
- `Files`: exact paths, no wildcards, no "similar to X"
- `Steps`: must include all 5 phases:
  - `[RED]` — write failing test with exact file path
  - `[VERIFY-RED]` — run command, expected output includes FAIL
  - `[GREEN]` — implement with exact file path and complete code
  - `[VERIFY-GREEN]` — run command, expected output includes PASS
  - `[COMMIT]` — conventional commit message with type and scope
- Code must be complete (no "// TODO", no "similar to above", no ellipsis)
- Commands must include expected output (exact or pattern)

## Common rejection reasons

1. **Generic paths**: "src/components/MyComponent.tsx" without verifying the path exists
2. **Incomplete code**: "implement similar logic" instead of actual code
3. **Missing VERIFY steps**: going straight from RED to GREEN
4. **No baseline-tests**: wave depends on prior state but doesn't verify it
5. **Circular depends-on**: wave-02 depends on wave-03 which depends on wave-02
6. **Missing metadata**: no Goal, Architecture, or Tech Stack
