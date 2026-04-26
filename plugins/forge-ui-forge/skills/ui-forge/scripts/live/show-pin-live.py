#!/usr/bin/env python3
"""
show-pin-live — dump untruncated pin content from a ui-forge LIVE-mode round.

Same shape as show-pin.py but reads from .ui-forge/live/<session-id>/round-NN.json
instead of .ui-forge/screens/<screen-id>/feedback/round-NN.json.

Usage (from project root):
    python3 <plugin-path>/skills/ui-forge/scripts/live/show-pin-live.py <session-id> [options]

Options:
    --round N              Round number. Default: latest (via latest.json).
    --pin ID               Restrict to a single pin by id.
    --json                 Emit machine-readable JSON instead of pretty text.
    --ids                  Only list pin ids + types (one per line).
    --list-sessions        List all session-ids under .ui-forge/live/ with their
                           latest round and timestamp; ignores other args.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


def list_sessions(live_dir: Path) -> None:
    if not live_dir.is_dir():
        sys.exit(f"[show-pin-live] no live directory at {live_dir}")
    sessions = sorted(d for d in live_dir.iterdir() if d.is_dir())
    if not sessions:
        print(f"[show-pin-live] no sessions under {live_dir}")
        return
    for sess in sessions:
        latest = sess / "latest.json"
        info = ""
        if latest.exists():
            try:
                meta = json.loads(latest.read_text())
                info = (
                    f"  round={meta.get('round')} "
                    f"host={meta.get('host')} "
                    f"path={meta.get('path')} "
                    f"received={meta.get('receivedAt')}"
                )
            except Exception:
                info = "  (unreadable latest.json)"
        else:
            rounds = sorted(sess.glob("round-*.json"))
            info = f"  rounds={len(rounds)}"
        print(f"{sess.name}{info}")


def resolve_round_file(session_dir: Path, explicit_round: int | None) -> Path:
    if explicit_round is not None:
        path = session_dir / f"round-{explicit_round:02d}.json"
        if not path.exists():
            sys.exit(f"[show-pin-live] round {explicit_round} not found: {path}")
        return path

    latest = session_dir / "latest.json"
    if latest.exists():
        try:
            meta = json.loads(latest.read_text())
            candidate = session_dir / meta["file"]
            if candidate.exists():
                return candidate
        except Exception as e:
            print(f"[show-pin-live] latest.json unreadable ({e}), falling back", file=sys.stderr)

    rounds = sorted(session_dir.glob("round-*.json"))
    if not rounds:
        sys.exit(f"[show-pin-live] no rounds in {session_dir}")
    return rounds[-1]


def render_pretty(file_path: Path, data: dict, pins: list) -> None:
    print(f"# {file_path}")
    print(
        f"session={data.get('sessionId')} round={data.get('round')} "
        f"host={data.get('host')} path={data.get('path')} "
        f"pins={data.get('pinCount')} new={data.get('newPinCount', 0)}"
    )
    for p in pins:
        print()
        print(f"## Pin #{p.get('id')} [{p.get('type')}]")
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
        description="Show full pin(s) from a ui-forge live-mode session round",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument("session", nargs="?", help="Session id (directory under .ui-forge/live/)")
    parser.add_argument("--round", type=int, help="Round number (default: latest)")
    parser.add_argument("--pin", type=int, help="Pin ID to filter")
    parser.add_argument("--json", action="store_true", help="Emit JSON instead of pretty text")
    parser.add_argument(
        "--ids",
        action="store_true",
        help="Only print pin ids (id type) — useful for discovery",
    )
    parser.add_argument(
        "--list-sessions",
        action="store_true",
        help="List all live-mode session ids with their latest round metadata.",
    )
    args = parser.parse_args()

    live_dir = Path.cwd() / ".ui-forge" / "live"

    if args.list_sessions:
        list_sessions(live_dir)
        return

    if not args.session:
        sys.exit("[show-pin-live] missing session id (use --list-sessions to see available ones)")

    session_dir = live_dir / args.session
    if not session_dir.is_dir():
        sys.exit(
            f"[show-pin-live] no session {args.session!r} under {live_dir}"
        )

    file_path = resolve_round_file(session_dir, args.round)
    data = json.loads(file_path.read_text())

    pins = data.get("pins", [])
    if args.pin is not None:
        pins = [p for p in pins if p.get("id") == args.pin]
        if not pins:
            sys.exit(f"[show-pin-live] pin id {args.pin} not in {file_path}")

    if args.ids:
        for p in pins:
            print(f"{p.get('id')}\t{p.get('type')}")
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
