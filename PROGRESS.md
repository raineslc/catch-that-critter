# PROGRESS.md — Catch That Critter

Every assistant updates this at the end of a session.

## Current step
Phase 2, step 1 — Meadow tilemap with free 2D tiles; ranger walking + camera.

## Done
- 2026-10-20 — Phase 0, step 1: private GitHub repo raineslc/catch-that-critter created with PLAN.md, CONVENTIONS.md, PROGRESS.md, DECISIONS.md, CLAUDE.md, AGENTS.md, GEMINI.md, .gitignore, .env.example.
- 2026-10-20 — Phase 0, step 2: Godot 4.7.2 project (`project.godot`, placeholder title screen `scenes/main.tscn`), folder skeleton, GUT 9.7.1 in `addons/gut/`, smoke tests, GitHub Actions workflow running GUT on pushes to main and PRs.
- 2026-10-20 — Phase 1, step 1: math problem generators.
  - `scripts/problems/`: `MathProblem` (prompt, spoken TTS text, answer, choices, standards, hint, data), `ChoiceBuilder` (seeded, believable wrong choices), one generator per habitat (`CountingGenerator`, `AddSubtractGenerator`, `PlaceValueGenerator`, `TimeMoneyGenerator`, `MultiplyDivideGenerator`), and `ProblemFactory`.
  - `data/skills.json`: 5 skills, 29 levels total, each with a description, problem type, Common Core codes, hint type, number of answer buttons, and tuning params.
  - 36 tests passing (every level sampled 300×: answer among choices, no duplicates/negatives, right button count, valid standard codes, no unkind words).

- 2026-10-21 — Phase 1, step 2: adaptive difficulty engine.
  - `scripts/adaptive/`: `AdaptiveEngine` (record_answer → LEVEL_UP / LEVEL_DOWN / NONE, extra help + misses_before_hint, end_session → newly mastered levels, stats for the parent report, to_dict/load_dict for saves) and `SkillProgress` (per-skill data).
  - `data/adaptive.json`: all tuning numbers. Rule details logged in DECISIONS.md (2026-10-21).
  - 59 tests passing (23 new).

- 2026-10-21 — Phase 1, step 3: debug screen `scenes/debug/problem_tester.tscn` (script `scripts/debug/problem_tester.gd`). Pick a skill/level, answer with big buttons, see level changes, extra help, hints (in words), lifetime stats, end-session mastery; "Read aloud" toggle uses Godot TTS. 70 tests passing.
  - TTS check on Chris's Windows PC: Godot found 3 English voices (Microsoft David, Zira, Mark). Web TTS still untested.
- **Phase 1 (math core) complete.**

## Next
- Phase 2, step 1: pick ONE free 2D asset pack family (Kenney or similar, CC0) for tiles + animals + ranger; Meadow tilemap; ranger walks with arrows/WASD/click; Camera2D follows. Ask Chris before downloading assets.

## Open issues
- Special rare animal species still to be chosen by Chris.
- Export presets (Web, Windows, macOS) not set up yet; they need Godot export templates (~1.3 GB) — do this in Phase 7 or when first needed.
- Preschool problem set is Phase 8 (not in skills.json yet).
- Tuning: "Count coins with quarters" (time_money level 5) sometimes makes a pile with no quarter; consider a "require at least one quarter" param.
- The debug screen describes pictures and hints in words; real clock/coin/dot visuals come with the chase screen (Phase 2).
