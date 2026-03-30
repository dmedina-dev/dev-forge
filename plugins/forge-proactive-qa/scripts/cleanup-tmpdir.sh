#!/usr/bin/env bash
# Delete specific files from $TMPDIR by name (no paths allowed)
# Usage: bash cleanup-tmpdir.sh file1.ts file2.spec.ts screenshot.png
#
# Security: only deletes from $TMPDIR, rejects any input containing / or ..
trap 'exit 0' ERR

DIR="${TMPDIR:-/private/tmp/claude}"

if [ $# -eq 0 ]; then
  echo "Usage: bash cleanup-tmpdir.sh <filename> [filename2] ..."
  exit 0
fi

for name in "$@"; do
  # Reject paths — only bare filenames allowed
  if [[ "$name" == */* ]] || [[ "$name" == *..* ]]; then
    echo "SKIP: '$name' — only filenames allowed, no paths"
    continue
  fi

  target="$DIR/$name"
  if [ -f "$target" ]; then
    rm "$target"
    echo "Removed: $target"
  else
    echo "Not found: $target"
  fi
done
