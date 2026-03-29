# Forge-Keeper Trigger Evaluation Results

## Summary

3 iterations testing forge-keeper's semantic trigger detection.

| Iteration | Description Version | Recall | Specificity | F1 | Notes |
|-----------|-------------------|--------|-------------|-----|-------|
| 1 | v1 (broad) | 11% | 100% | 0.20 | Wrong CWD + max-turns 1 |
| 2 | v1 (broad) | 100% | 0% | 0.72 | Fixed CWD + max-turns 5 — triggers everything |
| 3 | v2 (with exclusions) | 0% | 100% | 0.00 | Over-corrected — triggers nothing |

## Key Findings

1. **`claude -p` is single-shot** — can't test semantic triggers that depend on accumulated conversation context
2. **Description v1 (broad)** has perfect recall but zero precision — triggers on any development request
3. **Description v2 (exclusions)** has perfect precision but zero recall — exclusion list dominates
4. **CWD matters** — testing in dev-forge repo confuses Claude because referenced files don't exist
5. **max-turns matters** — `--max-turns 1` cuts off tool invocations before responses generate

## Conclusion

Semantic trigger calibration requires multi-turn conversational testing in real projects, not single-shot `claude -p` evaluation. The v2 description with exclusion criteria is conceptually correct but needs validation through actual usage in projects like stock-manager.

## Next Steps

- Test manually in real projects with `--plugin-dir`
- Use skill-creator `run_loop.py` for keyword-level description optimization
- Iterate on description based on real-world feedback
