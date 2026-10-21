# GEMINI.md — Catch That Critter (Gemini)

Same standing rules as `CLAUDE.md`. Short version:

0. Start with `docs/HANDOFF.md` (where things stand, how Chris works).
1. Read first, every session: `PLAN.md`, `CONVENTIONS.md`, `PROGRESS.md`, `DECISIONS.md`.
2. Run the tests before changing anything:
   `godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit`
3. Godot 4 (2D), statically typed GDScript, data in `data/*.json`, GUT tests in `tests/`.
4. Build one PLAN.md checklist step at a time on a branch; commit small; check it off; confirm with Chris before the next step.
5. Update `PROGRESS.md` before finishing.
6. Never change a confirmed decision (PLAN.md section 2) without Chris's approval; log changes in `DECISIONS.md`.
7. No secrets in the repo; no network calls, ads, analytics, or external links in the game. Saves stay local.
8. Kid-facing text: short, calm, encouraging; never say "wrong."
