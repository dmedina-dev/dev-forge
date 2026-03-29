#!/usr/bin/env python3
# Curated from: anthropics/claude-code (plugins/hookify) — Author: Daisy Hollman (Anthropic)
"""Stop hook executor for hookify plugin."""

import os
import sys
import json

PLUGIN_ROOT = os.environ.get('CLAUDE_PLUGIN_ROOT')
if PLUGIN_ROOT:
    if PLUGIN_ROOT not in sys.path:
        sys.path.insert(0, PLUGIN_ROOT)

try:
    from core.config_loader import load_rules
    from core.rule_engine import RuleEngine
except ImportError as e:
    print(json.dumps({"systemMessage": f"Hookify import error: {e}"}))
    sys.exit(0)


def main():
    try:
        input_data = json.load(sys.stdin)
        rules = load_rules(event='stop')
        result = RuleEngine().evaluate_rules(rules, input_data)
        print(json.dumps(result))
    except Exception as e:
        print(json.dumps({"systemMessage": f"Hookify error: {e}"}))
    finally:
        sys.exit(0)


if __name__ == '__main__':
    main()
