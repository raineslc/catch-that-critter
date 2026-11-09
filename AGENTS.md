# AGENTS.md — Catch That Critter (ChatGPT / Codex)

Same standing rules as `CLAUDE.md`. Short version:

0. Start with `docs/HANDOFF.md` (where things stand, how Chris works).
1. Read first, every session: `PLAN.md`, `CONVENTIONS.md`, `PROGRESS.md`, `DECISIONS.md`.
2. Run the tests before changing anything:
   `godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit`
   One file: add `-gtest=res://tests/test_<thing>.gd`; one test: also add `-gunit_test_name=<name>`.
3. Godot 4 (2D), statically typed GDScript, data in `data/*.json`, GUT tests in `tests/`.
4. GitHub `main` (`raineslc/catch-that-critter`) is the source of truth. Start every task by fetching and branching from the latest `origin/main`, never from an old local branch or leftover uncommitted edits. Changes reach `main` only through a PR with passing tests.
   Build one PLAN.md checklist step at a time on that branch; commit small; check it off; confirm with Chris before the next step.
5. Update `PROGRESS.md` before finishing.
6. Never change a confirmed decision (PLAN.md section 2) without Chris's approval; log changes in `DECISIONS.md`.
7. No secrets in the repo; no network calls, ads, analytics, or external links in the game. Saves stay local.
8. Kid-facing text: short, calm, encouraging; never say "wrong," "bad," or "fail."
9. Speech always goes through `Speech.say()`; never call `DisplayServer.tts_stop()` or interrupting `tts_speak` (froze Godot on Windows).
10. Random numbers come from a passed-in `RandomNumberGenerator`; art/sound is CC0 and listed in `assets/CREDITS.md`; map rules are in `CONVENTIONS.md`.

## Architecture (big picture)
- `GameState` (`scripts/game/game_state.gd`) is the only autoload: current profile, rescues, care visits, stars, decorations, area unlocks/travel (`travel_to`/`take_arrival`, via `data/maps/world.json`), playtest logging, and saving (`snapshot`/`_restore`, `finish_session` on F10 or window close).
- Pure `RefCounted` logic, unit-tested without scenes:
  - `scripts/problems/` — `ProblemFactory` reads `data/skills.json` and calls one generator per skill (counting, add/subtract, place value, multiply/divide, time/money, word problems) → `MathProblem`; `ChoiceBuilder` makes answer buttons.
  - `scripts/adaptive/` — `AdaptiveEngine` moves each skill's level from a rolling accuracy window (tuning in `data/adaptive.json`).
  - `scripts/progress/` — `profile_store.gd` (save files) and rewards; `scripts/chase/`, `scripts/care/` — state/catalog for the catch and care loops (`data/chase.json`, `data/care.json`, `data/animals.json`).
- Scenes: `scenes/main.tscn` (title/profiles) → `scenes/story/` intro → `scenes/world/rescue_center.tscn` hub with pens; habitat scenes (meadow, forest, desert, mountains, swamp) are built from ASCII maps by `scripts/world/habitat_map.gd` + `map_data.gd`. Critters wander (`wander_brain.gd`); walking up to one opens the chase screen (`scripts/chase/`) that asks problems; pens open the care screen (`scripts/care/`, includes spelling tasks).
- Scene scripts stay thin and call into the logic classes above.

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
