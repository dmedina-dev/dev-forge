#!/usr/bin/env python3
"""
show-pin — dump the full, untruncated content of one or all pins from a
ui-forge feedback round.

Intended for Claude to call when the truncated `[ui-forge:pin]` stdout lines
emitted by serve.py aren't enough (e.g. the `html:` snapshot was cut at 500
chars). A dedicated script gives users a stable, pre-approvable command path.

Usage (from project root — the one containing .ui-forge/):
    python3 <plugin-path>/skills/ui-forge/scripts/show-pin.py <screen-id> [options]

Options:
    --round N        Round number. Default: latest (via feedback/latest.json).
    --pin ID         Restrict to a single pin by id.
    --json           Emit machine-readable JSON instead of pretty text.
    --ids            Only list pin ids + types (one per line) — useful to
                     discover what's available before asking for details.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


def resolve_round_file(feedback_dir: Path, explicit_round: int | None) -> Path:
    if explicit_round is not None:
        path = feedback_dir / f"round-{explicit_round:02d}.json"
        if not path.exists():
            sys.exit(f"[show-pin] round {explicit_round} not found: {path}")
        return path

    latest = feedback_dir / "latest.json"
    if latest.exists():
        try:
            meta = json.loads(latest.read_text())
            candidate = feedback_dir / meta["file"]
            if candidate.exists():
                return candidate
        except Exception as e:
            print(f"[show-pin] latest.json unreadable ({e}), falling back", file=sys.stderr)

    rounds = sorted(feedback_dir.glob("round-*.json"))
    if not rounds:
        sys.exit(f"[show-pin] no rounds found in {feedback_dir}")
    return rounds[-1]


def render_pretty(file_path: Path, data: dict, pins: list) -> None:
    print(f"# {file_path}")
    print(
        f"screen={data.get('screen')} round={data.get('round')} "
        f"pins={data.get('pinCount')} new={data.get('newPinCount', 0)}"
    )
    for p in pins:
        print()
        print(f"## Pin #{p.get('id')} [{p.get('type')}] scenario={p.get('scenario')}")
        region = p.get("region")
        if region:
            print(
                f"  location:  region {region.get('w')}x{region.get('h')} "
                f"@ ({region.get('x')},{region.get('y')})"
            )
        else:
            print(f"  location:  point @ ({p.get('x')},{p.get('y')})")
        sent = p.get("sentInRound")
        print(f"  sent:      round {sent}" if sent else "  sent:      pending")
        print(f"  selector:  {p.get('selector', '')}")
        if p.get("comment"):
            print(f"  comment:   {p.get('comment')}")
        snap = p.get("snapshot") or {}
        if snap:
            print("  snapshot:")
            if snap.get("path") and snap.get("path") != p.get("selector"):
                print(f"    path:    {snap.get('path')}")
            print(f"    tag:     {snap.get('tag', '')}")
            classes = snap.get("classes") or []
            if classes:
                print(f"    classes: {', '.join(classes)}")
            bbox = snap.get("bbox") or {}
            if bbox:
                print(
                    f"    bbox:    {bbox.get('w')}x{bbox.get('h')} "
                    f"@ ({bbox.get('x')},{bbox.get('y')})"
                )
            if snap.get("text"):
                print(f"    text:    {snap.get('text')}")
            if snap.get("html"):
                print("    html:")
                for line in snap.get("html").splitlines():
                    print(f"      {line}")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Show full pin(s) from a ui-forge feedback round",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument("screen", help="Screen ID (kebab-case)")
    parser.add_argument("--round", type=int, help="Round number (default: latest)")
    parser.add_argument("--pin", type=int, help="Pin ID to filter")
    parser.add_argument("--json", action="store_true", help="Emit JSON instead of pretty text")
    parser.add_argument(
        "--ids",
        action="store_true",
        help="Only print pin ids (id type scenario) — useful for discovery",
    )
    args = parser.parse_args()

    feedback_dir = Path.cwd() / ".ui-forge" / "screens" / args.screen / "feedback"
    if not feedback_dir.is_dir():
        sys.exit(
            f"[show-pin] no feedback directory for screen {args.screen!r} "
            f"(looked in {feedback_dir})"
        )

    file_path = resolve_round_file(feedback_dir, args.round)
    data = json.loads(file_path.read_text())

    pins = data.get("pins", [])
    if args.pin is not None:
        pins = [p for p in pins if p.get("id") == args.pin]
        if not pins:
            sys.exit(f"[show-pin] pin id {args.pin} not in {file_path}")

    if args.ids:
        for p in pins:
            print(f"{p.get('id')}\t{p.get('type')}\t{p.get('scenario')}")
        return

    if args.json:
        if args.pin is not None:
            print(json.dumps(pins, indent=2))
        else:
            rest = {k: v for k, v in data.items() if k != "pins"}
            print(json.dumps({**rest, "pins": pins}, indent=2))
        return

    render_pretty(file_path, data, pins)


if __name__ == "__main__":
    main()
