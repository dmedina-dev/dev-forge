#!/usr/bin/env bash
# Cleanup temporary explore files created by proactive-qa
# Safe to run anytime — only removes known temp patterns from $TMPDIR
trap 'exit 0' ERR

# Clean temp files in TMPDIR
for f in "${TMPDIR:-/private/tmp/claude}"/explore-*.spec.ts "${TMPDIR:-/private/tmp/claude}"/explore-*.ts "${TMPDIR:-/private/tmp/claude}"/screenshot-*.png; do
  [ -f "$f" ] && rm "$f" && echo "Removed: $f"
done

echo "Explore cleanup done"
