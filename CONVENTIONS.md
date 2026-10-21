# CONVENTIONS.md — Catch That Critter

Shared rules for every AI assistant (Claude, ChatGPT/Codex, Gemini) and for Chris.

## Engine & language
- Godot 4 (2D). **Pinned version: Godot 4.7.2 stable** (standard build, not .NET/mono) — every assistant and CI uses exactly this version.
- Test framework: **GUT 9.7.1** (the GUT line for Godot 4.7), vendored in `addons/gut/`.
- Renderer: Compatibility (works on web and older PCs). Viewport 1280×720, stretch mode `canvas_items`, nearest-neighbor texture filter for pixel art.
- GDScript only, statically typed: `var count: int = 0`, `func add(a: int, b: int) -> int:`.
- Tabs for indentation (Godot default).

## Naming
- Files, folders, functions, variables, signals: `snake_case` (`problem_generator.gd`, `func make_problem()`).
- `class_name` and scene node names: `PascalCase` (`class_name AdditionGenerator`, node `Ranger`).
- Constants: `UPPER_SNAKE_CASE`.
- Private helpers start with `_`.

## Structure
- One responsibility per script.
- Math, adaptive difficulty, and save logic live in plain scripts (`RefCounted`), not in scenes, so they can be unit-tested without a running game.
- Game tuning values (speeds, thresholds, timers) go in `data/*.json` or named constants — no magic numbers.
- Random numbers come from a passed-in `RandomNumberGenerator` so tests can use a fixed seed.

## Data files (`data/`)
- JSON, 2-space indent, `snake_case` keys.
- Every problem type in `skills.json` has a `standards` array of Common Core codes (e.g. `["2.OA.2"]`).

## Maps & art
- Habitat maps: `data/maps/<habitat>.txt`, one character per 16px tile, every row the same width, map edges blocked, exactly one spawn `S`. Character meanings in `data/maps/legend.json`.
- Ponds must be convex (no inside corners). Paths can be 1 tile wide or rectangles.
- Only CC0 (or compatible) art; record every file in `assets/CREDITS.md` with its original pack path. Stick to the Ninja Adventure pack family for a consistent look.
- Node origins of characters and nature objects sit at their feet (bottom-center) so y-sorting works.

## Text-to-speech
- Always go through `Speech.say()`. **Never call `DisplayServer.tts_stop()` or `tts_speak(..., interrupt = true)`** — on Windows (Godot 4.7.2) interrupting speech can freeze or crash the game (Playtest 1). A test enforces this.

## Kid-facing text
- Short, calm, encouraging sentences. Never "wrong," "bad," or "fail."
- Every instruction must also be available as text-to-speech.

## Tests
- GUT tests in `tests/`, named `test_<thing>.gd`, one file per script under test.
- New logic ships with tests. All tests pass before a commit to `main`.
- Run: `godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit`

## Git
- Branch per checklist step: `phase<N>/<short-name>` (e.g. `phase1/addition-generator`).
- Small commits, present-tense summary line under ~70 chars:
  - `Add addition problem generator with tests`
  - `Fix carry bug in place-value generator`
- Merge to `main` only when tests pass.
- Never commit secrets, `.env`, or build output.

## Session hygiene
- Start: read PLAN.md, CONVENTIONS.md, PROGRESS.md, DECISIONS.md; run tests.
- End: update PROGRESS.md (what's done, what's next, open issues).
- Any change to a confirmed decision needs Chris's approval and a dated entry in DECISIONS.md.
