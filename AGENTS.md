# AGENTS.md — Catch That Critter (ChatGPT / Codex)

Same standing rules as `CLAUDE.md`. Short version:

0. Start with `docs/HANDOFF.md` (where things stand, how Chris works).
1. Read first, every session: `PLAN.md`, `CONVENTIONS.md`, `PROGRESS.md`, `DECISIONS.md`.
2. Run the tests before changing anything:
   `godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit`
3. Godot 4 (2D), statically typed GDScript, data in `data/*.json`, GUT tests in `tests/`.
4. GitHub `main` (`raineslc/catch-that-critter`) is the source of truth. Start every task by fetching and branching from the latest `origin/main`, never from an old local branch or leftover uncommitted edits. Changes reach `main` only through a PR with passing tests.
   Build one PLAN.md checklist step at a time on that branch; commit small; check it off; confirm with Chris before the next step.
5. Update `PROGRESS.md` before finishing.
6. Never change a confirmed decision (PLAN.md section 2) without Chris's approval; log changes in `DECISIONS.md`.
7. No secrets in the repo; no network calls, ads, analytics, or external links in the game. Saves stay local.
8. Kid-facing text: short, calm, encouraging; never say "wrong."

## Review guidelines
Codex reviews every pull request on GitHub. Flag only real problems, most serious first:
- Bugs that would break the game for a 7-year-old: crashes, freezes, soft-locks (no way to leave a screen), lost or corrupted saves.
- Never call `DisplayServer.tts_stop()` or interrupting `tts_speak` (froze Godot on Windows); all speech goes through `Speech.say()`.
- No network calls, analytics, ads, external links, or secrets. Saves stay local, and tests must never touch a real player's save.
- New logic ships with GUT tests; tuning numbers live in `data/*.json` or named constants, not magic numbers.
- GDScript is statically typed; game logic stays out of scene scripts so it can be unit-tested.
- Kid-facing text is short, calm, and encouraging; never "wrong," "bad," or "fail."
- New art or sound is CC0 (or compatible) and listed in `assets/CREDITS.md`.
- A change to a confirmed decision (PLAN.md section 2) needs a DECISIONS.md entry with Chris's approval.
Skip style nitpicks the tests and existing code already settle.
