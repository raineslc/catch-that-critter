"""Summarize a Catch That Critter playtest log (.jsonl) into a short readable report.

Usage:
    python tools/summarize_playtest.py                 # newest log in the default folder
    python tools/summarize_playtest.py path/to/log.jsonl

Default folder (Windows): %APPDATA%\\Godot\\app_userdata\\Catch That Critter\\playtest
"""
import json
import os
import sys
from collections import defaultdict
from pathlib import Path

DEFAULT_DIR = Path(os.environ.get("APPDATA", "")) / "Godot" / "app_userdata" / "Catch That Critter" / "playtest"


def newest_log(folder: Path) -> Path:
    logs = sorted(folder.glob("playtest_*.jsonl"), key=lambda p: p.stat().st_mtime)
    if not logs:
        sys.exit(f"No playtest logs found in {folder}")
    return logs[-1]


def load(path: Path) -> list[dict]:
    events = []
    for line in path.read_text(encoding="utf-8-sig").splitlines():
        if line.strip():
            events.append(json.loads(line))
    return events


def summarize(events: list[dict]) -> str:
    out = []
    minutes = max((e["t"] for e in events), default=0) / 60
    answers = [e for e in events if e["event"] == "answer"]
    first = [e for e in answers if e["first_try"]]
    chases = [e for e in events if e["event"] == "chase_end"]
    caught = sum(1 for e in chases if e["caught"])
    escapes = sum(1 for e in events if e["event"] == "escaped")
    hints = sum(1 for e in events if e["event"] == "hint")
    out.append(f"Played {minutes:.1f} minutes: {len(chases)} chases, {caught} caught, {escapes} got away, {hints} hints.")
    if first:
        right = sum(1 for e in first if e["correct"])
        avg = sum(e["seconds"] for e in first) / len(first)
        out.append(f"First tries: {right}/{len(first)} right ({right * 100 // len(first)}%), average {avg:.1f}s per problem.")
    modes = sorted({e["mode"] for e in answers})
    if modes:
        out.append("Modes used: " + ", ".join(modes))

    out.append("")
    out.append("By level (first tries):")
    by_level = defaultdict(list)
    for e in first:
        by_level[e["level"]].append(e)
    for level in sorted(by_level):
        rows = by_level[level]
        right = sum(1 for e in rows if e["correct"])
        avg = sum(e["seconds"] for e in rows) / len(rows)
        out.append(f"  Level {level}: {right}/{len(rows)} right, avg {avg:.1f}s")

    changes = [e for e in events if e["event"] == "level_change"]
    if changes:
        out.append("")
        out.append("Level changes: " + ", ".join(f"{e['direction']} to {e['to']} at {e['t'] / 60:.1f} min" for e in changes))

    missed = [e for e in first if not e["correct"]]
    if missed:
        out.append("")
        out.append("Missed on the first try:")
        for e in missed[:15]:
            out.append(f"  {e['prompt']}  answered {e['choice']} (answer {e['answer']}), {e['seconds']}s")

    slow = sorted((e for e in first if e["correct"]), key=lambda e: -e["seconds"])[:5]
    if slow:
        out.append("")
        out.append("Slowest right answers:")
        for e in slow:
            out.append(f"  {e['prompt']}  {e['seconds']}s")
    return "\n".join(out)


def main() -> None:
    path = Path(sys.argv[1]) if len(sys.argv) > 1 else newest_log(DEFAULT_DIR)
    print(f"Log: {path}\n")
    print(summarize(load(path)))


if __name__ == "__main__":
    main()
