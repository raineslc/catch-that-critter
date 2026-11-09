# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Catch That Critter: a 2D top-down math and reading game for kids. Standing rules for Claude Code (AGENTS.md and GEMINI.md should say the same thing).

## Read first, every session
0. `docs/HANDOFF.md` — short summary of where things stand and how Chris works.
1. `PLAN.md` — master plan. **Approved by Chris on 2026-10-20.**
2. `CONVENTIONS.md`, `PROGRESS.md`, `DECISIONS.md`.
3. Run the tests before changing anything.

## Stack
- Godot **4.7.2** stable (pinned in `CONVENTIONS.md`), **2D top-down**.
- GDScript only, with static typing (`var count: int`).
- Game data in JSON under `data/`.
- Tests: GUT in `tests/`. CI: GitHub Actions.

## Style
- snake_case for files, functions, variables; PascalCase for class_name and nodes.
- One responsibility per script; keep math/adaptive/save logic free of scene code so it's unit-testable.
- No magic numbers for game tuning; put them in JSON or constants.
- Kid-facing text: short, calm, encouraging; never say "wrong," "bad," or "fail." Every instruction is also spoken. One planned exception: the predator "chomp" (PLAN 3.15).
- Random numbers come from a passed-in `RandomNumberGenerator` so tests can seed them.
- Speech: always `Speech.say()` (`scripts/tts/speech.gd`). **Never** call `DisplayServer.tts_stop()` or interrupting `tts_speak` — it froze Godot on Windows; a test enforces this.
- Art/sound: one pixel-art style. The Ninja Adventure pack (CC0) plus art made for this project (drawn in code or with an AI art tool); real animal photos on fact cards must be public domain or CC0. Every file and tool is listed in `assets/CREDITS.md`. Ask Chris before downloading anything. Character/nature node origins sit at their feet for y-sorting.
- Maps: rules for `data/maps/*.txt`/`*.json` and `world.json` gates are in `CONVENTIONS.md` and checked by tests.
- Branch names: `phase<N>/<short-name>` (later fix work uses `fixes/<name>`).

## Architecture (big picture)
- `GameState` (`scripts/game/game_state.gd`) is the only autoload: current profile, rescues, care visits, stars, decorations, area unlocks/travel (`travel_to`/`take_arrival`, via `data/maps/world.json`), playtest logging, and saving (`snapshot`/`_restore`, `finish_session` on F10 or window close).
- Pure `RefCounted` logic, unit-tested without scenes:
  - `scripts/problems/` — `ProblemFactory` reads `data/skills.json` and calls one generator per skill (counting, add/subtract, place value, multiply/divide, time/money, word problems) → `MathProblem`; `ChoiceBuilder` makes answer buttons.
  - `scripts/adaptive/` — `AdaptiveEngine` moves each skill's level from a rolling accuracy window (tuning in `data/adaptive.json`).
  - `scripts/progress/` — `profile_store.gd` (save files) and rewards; `scripts/chase/`, `scripts/care/` — state/catalog for the catch and care loops (`data/chase.json`, `data/care.json`, `data/animals.json`).
- Scenes: `scenes/main.tscn` (title/profiles) → `scenes/story/` intro → `scenes/world/rescue_center.tscn` hub with pens; habitat scenes (meadow, forest, desert, mountains, swamp) are built from ASCII maps by `scripts/world/habitat_map.gd` + `map_data.gd`. Critters wander (`wander_brain.gd`); walking up to one opens the chase screen (`scripts/chase/`) that asks problems; pens open the care screen (`scripts/care/`, includes spelling tasks).
- Scene scripts stay thin and call into the logic classes above.

## Workflow (Chris's process)
- Build **one checklist step from PLAN.md at a time**: say which step, build only it, run it, fix errors, commit with a clear message, check it off in PLAN.md, update PROGRESS.md, then **confirm with Chris before the next step**.
- GitHub `main` (`raineslc/catch-that-critter`) is the source of truth. Start every task by fetching and branching from the latest `origin/main`, never from an old local branch or leftover uncommitted edits.
- Work on a feature branch; merge only when tests pass.
- If scope changes, update PLAN.md first and log it in DECISIONS.md.
- Never change a confirmed decision (PLAN.md section 2) without Chris's approval.
- Explain code in plain language when Chris asks.
- Be honest if something is too complex; suggest simpler options.

## Security & privacy
- **No hardcoded secrets.** Use environment variables; list names in `.env.example`; keep `.env` in `.gitignore`.
- No network calls, analytics, ads, or external links in the game. All saves stay local.

## How to run & test
- Run: open the project in Godot 4.7.2 and press F5 (main scene: `scenes/main.tscn` title → pick a profile button (a new one makes its ranger first) → storm intro → `scenes/world/rescue_center.tscn`; the west gate leads to the Meadow; walk up to a pen with rescued animals to care for them). Move with arrows/WASD or click.
- Tests: `godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit` (exit code 1 on failure).
  - One file: `-gtest=res://tests/test_adaptive_engine.gd`; one test inside it: add `-gunit_test_name=<test_func_name>`.
  - Tests are `tests/test_<thing>.gd`, one per script under test (GUT 9.7.1, vendored in `addons/gut/`, config in `.gutconfig.json`).
  - On Chris's Windows PC Godot came from winget and isn't on PATH as `godot`; use `Godot_v4.7.2-stable_win64_console.exe` from `%LOCALAPPDATA%\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_*\`.
  - After a fresh clone, run `godot --headless --import` once first.
- Playtest mode: add `-- --playtest` after the Godot args (settings in `data/playtest.json`). Logs go to `%APPDATA%\Godot\app_userdata\Catch That Critter\playtest\`; summarize with `python tools/summarize_playtest.py [log.jsonl]`. The desktop shortcut runs `tools/playtest_launch.cmd` inside the frozen playtest worktree at `C:\Users\raine\CatchACritter-playtest` (current tag in `docs/playtest_1.md`) — don't develop there. The launcher also saves Godot's verbose log as `godot_<timestamp>.log` in the same playtest folder. Freezes show up as `freeze` events (with the last steps) in the playtest log.
- Debug math screen (grown-ups only): open `scenes/debug/problem_tester.tscn` in Godot and press F6, or run `godot --path . res://scenes/debug/problem_tester.tscn`.
- Full-loop Playtest 2: run `tools/playtest_2_launch.cmd` from this checkout, or add `-- --playtest-full`. Follow `docs/playtest_2.md`; it starts with mixed addition/subtraction within 20 and saves separately from normal play.
- Normal game with the local answer log on (how the 7-year-old plays now): run `tools/play.cmd`, or add `-- --log`. Summarize with `python tools/summarize_playtest.py`.
- Local saves: `user://profiles/default.json` (first profile, Henrito) and `user://profiles/ranger_2.json` (second profile, Loganator) for normal play, set in `data/profiles.json`; `user://profiles/playtest_2.json` for Playtest 2. Save & rest (F10 in the hub) or closing the window completes session mastery. Failed saves keep the session open. Use `-- --no-save` for disposable scene helpers; GUT script mode and `--no-save` disable profile access (the title shows no profile buttons). Never delete a player's save as part of tests.
- `GameState` is an autoload: scripts that use it don't compile under `godot -s some_script.gd` (bare script mode). For throwaway screenshot helpers, run them as a scene from a git-ignored `.tmp_shots/` folder instead.
- CI: `.github/workflows/tests.yml` runs the same command on every push to `main` and every pull request.
- Web build: Godot export preset "Web" → `build/web/`. Desktop: "Windows Desktop" / "macOS" presets → `build/`.
- Update these commands here if they change.
