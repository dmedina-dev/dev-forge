# Decision Log Format

File location: `docs/decisions/YYYY-MM-DD-<flujo>-decisions.md`

The orchestrator creates this file at flow setup and appends entries throughout execution.

## Template

```markdown
# Decision Log — Flujo: <nombre>

## Wave 01: <nombre>

### D-01.1: <titulo corto>
- **Timestamp**: YYYY-MM-DD HH:MM
- **Task**: 1.2
- **Contexto**: <que ambiguedad o situacion requirio decision>
- **Opciones consideradas**:
  1. <opcion A> — pros/contras
  2. <opcion B> — pros/contras
- **Decision**: <elegida>
- **Razon**: <por que>
- **Riesgo**: <que podria estar mal>
- **Reversibilidad**: facil | media | dificil
- **Agente decisor**: <quien tomo la decision>

### Domain review wave-01 (Analyst, sin veto)
<hallazgos del Analyst post-wave>

---

## Wave 02: <nombre>
...
```

## Entry types

### Autonomous decision (D-NN.M)
Decisions made by the orchestrator or sub-agents without user input. Must include all fields above.

### Domain review (post-wave)
Summary from the Analyst agent after each wave. Observations only, no veto power. Documented for awareness.

### User decision (UD-NN.M)
Decisions requested from the user (BLOCKERs, failures). Same format but `Agente decisor: usuario`.

### Wave failure (F-NN)
Special entry when a wave fails irrecoverably. Includes:
- Failure point (task, step, cycle count)
- Error details
- State description (branch, commits, baseline status)
- User decision and rationale

## Naming convention

- `D-01.3` — autonomous decision #3 in wave 01
- `UD-02.1` — user decision #1 in wave 02
- `F-03` — wave 03 failure entry
