# CLAUDE.md — Catch That Critter

Standing rules for Claude Code (AGENTS.md and GEMINI.md should say the same thing).

## Read first, every session
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
- Kid-facing text: short, calm, encouraging; never say "wrong."

## Workflow (Chris's process)
- Build **one checklist step from PLAN.md at a time**: say which step, build only it, run it, fix errors, commit with a clear message, check it off in PLAN.md, update PROGRESS.md, then **confirm with Chris before the next step**.
- Work on a feature branch; merge only when tests pass.
- If scope changes, update PLAN.md first and log it in DECISIONS.md.
- Never change a confirmed decision (PLAN.md section 2) without Chris's approval.
- Explain code in plain language when Chris asks.
- Be honest if something is too complex; suggest simpler options.

## Security & privacy
- **No hardcoded secrets.** Use environment variables; list names in `.env.example`; keep `.env` in `.gitignore`.
- No network calls, analytics, ads, or external links in the game. All saves stay local.

## How to run & test
- Run: open the project in Godot 4.7.2 and press F5 (main scene: `scenes/main.tscn` title → any key → `scenes/world/meadow.tscn`). Move with arrows/WASD or click.
- Tests: `godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit` (exit code 1 on failure).
  - On Chris's Windows PC Godot came from winget and isn't on PATH as `godot`; use `Godot_v4.7.2-stable_win64_console.exe` from `%LOCALAPPDATA%\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_*\`.
  - After a fresh clone, run `godot --headless --import` once first.
- Playtest mode: add `-- --playtest` after the Godot args (settings in `data/playtest.json`). Logs go to `%APPDATA%\Godot\app_userdata\Catch That Critter\playtest\`; summarize with `python tools/summarize_playtest.py [log.jsonl]`. The desktop shortcut runs `tools/playtest_launch.cmd` inside the frozen playtest worktree at `C:\Users\raine\CatchACritter-playtest` (current tag in `docs/playtest_1.md`) — don't develop there. The launcher also saves Godot's verbose log as `godot_<timestamp>.log` in the same playtest folder. Freezes show up as `freeze` events (with the last steps) in the playtest log.
- Debug math screen (grown-ups only): open `scenes/debug/problem_tester.tscn` in Godot and press F6, or run `godot --path . res://scenes/debug/problem_tester.tscn`.
- `GameState` is an autoload: scripts that use it don't compile under `godot -s some_script.gd` (bare script mode). For throwaway screenshot helpers, run them as a scene from a git-ignored `.tmp_shots/` folder instead.
- CI: `.github/workflows/tests.yml` runs the same command on every push to `main` and every pull request.
- Web build: Godot export preset "Web" → `build/web/`. Desktop: "Windows Desktop" / "macOS" presets → `build/`.
- Update these commands here if they change.
