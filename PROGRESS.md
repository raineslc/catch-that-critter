# PROGRESS.md — Catch That Critter

Every assistant updates this at the end of a session.

## Current step
Phase 3, step 3 — Feeding via spelling, care notes, fact cards with read-aloud. (Playtest 1 can continue in parallel with `playtest-1.3`.)

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

- 2026-10-21 — Phase 2, step 1: Meadow you can walk around.
  - Art: Ninja Adventure pack (CC0) — see DECISIONS.md and `assets/CREDITS.md`. Original zip is in Chris's Downloads; only used files are in `assets/`.
  - `data/maps/meadow.txt` + `legend.json`; `MapData` reads them; `EdgeTiles` picks path/pond edge pieces; `HabitatMap` (`scenes/world/meadow.tscn`) builds ground TileMapLayer (water blocks), y-sorted trees/bushes/rocks/flowers, edge walls, spawns the ranger.
  - `Ranger` (`scenes/world/ranger.tscn`): arrows/WASD (actions added in code), click-to-move (gives up when blocked), 4-direction walk/idle animations, Camera2D ×3 zoom clamped to the map.
  - Title screen → any key → Meadow.
  - 88 tests passing (physics tests: walking, pond blocks, click-to-move, stuck give-up).

- 2026-10-21 — Phase 2, step 2: wandering critters.
  - `data/animals.json` (defaults + raccoon) read by `AnimalCatalog`; map legend `a` = raccoon spawn (2 in the Meadow).
  - `Critter`: idle → wander near home (`WanderBrain`) → startles with the pack's "!" emote when the ranger is within 40px → emits `startled` → darts away → cooldown. `PhysicsLayers`: ranger and critters only collide with the world.
  - `HabitatMap` emits `chase_requested(critter)` and shows a "Chase the Raccoon!" banner (placeholder until the chase screen).
  - 99 tests passing.

- 2026-10-21 — Phase 2, step 3: the chase.
  - `scripts/chase/`: `ChaseState` (rules: 3 right = catch, gap closes/grows; tuning in `data/chase.json`), `ChaseScreen` (scrolling path with ranger + critter at 4×, catch meter, question, `ProblemPicture`, big buttons, kind feedback, sounds, net toss → heart → "You caught the Raccoon!" with portrait), `ChaseNet`.
  - `GameState` autoload (`scripts/game/game_state.gd`): factory, adaptive engine, animal catalog, rescued list, read-aloud flag.
  - `Speech` (`scripts/tts/speech.gd`): TTS wrapper (slower rate, silent when headless); reads each question aloud.
  - Meadow: startle → world freezes → "Chase the Raccoon!" → chase opens after 0.8s → catch removes the raccoon and records the rescue → world resumes.
  - Fixed: a startled critter kept moving after the world froze (physics error).
  - 117 tests passing.

- 2026-10-21 — Phase 2, step 4: modes and Henrito.
  - `ChaseState`: Race timer, escape, sprint boost, restart. `GameState`: mode, explore lock, sidekick id. Meadow mode button.
  - `Sidekick` (`scripts/sidekick/sidekick.gd`, `data/sidekicks.json`): Henrito's art, voice, and lines. `HintText`: one-sentence strategy hint per problem type. `HintPicture`: counted dots, add/take-away dots, number line with hops, base-ten blocks (shrink to fit), clock with minute labels, coins with values, groups.
  - Chase screen: Henrito bubble, hints after the engine's miss limit, race timer bar, "Got away!" → Chase again / Back to the map.
  - `ProblemPicture` drawing refactored into shared static helpers (clock, coins, groups).
  - 139 tests passing.
- **Phase 2 (map & chase prototype) complete.**
- 2026-10-21 — Playtest 1 setup: `--playtest` mode (`data/playtest.json`: add/subtract to 12, raccoons respawn after 25s, answer log), `PlaytestLog`, `tools/summarize_playtest.py`, 6 raccoons in the Meadow, game icon, desktop shortcut → frozen worktree `C:\Users\raine\CatchACritter-playtest` at tag `playtest-1`, checklist `docs/playtest_1.md`. 146 tests passing.
  - To review: `python tools/summarize_playtest.py` (newest log) + Chris's notes.
- 2026-10-21 — Playtest 1 froze mid-chase (see DECISIONS.md "Freeze during Playtest 1"). Added `FreezeWatch` breadcrumbs + watchdog, `respawn` log events, `tools/playtest_launch.cmd` (per-session Godot verbose log), freeze reporting in the summary script → `playtest-1.1`. Not yet reproduced; a realistic robot player (walks, clicks, 25s comebacks, 30 chases) is the next check. First data point: 7/7 right at ~1.9s on level 1 → start the 7-year-old higher.
- 2026-10-21 — **Freeze fixed:** cause was stopping Windows TTS mid-sentence (`tts_stop()`), proven with the robot + freeze detector and a TTS stress test. `Speech` now never interrupts; lines wait until the voice is quiet. 156 tests passing. Playtest copy updated to `playtest-1.2`.
- 2026-10-21 — **Voice off** (Chris: voices sound weird, some lines off). `GameState.read_aloud` defaults to false; text and Henrito's bubble still show. `Speech` kept for later. Playtest copy → `playtest-1.3`. Open question for Chris: which lines sounded "off".
- 2026-10-21 — Phase 3, step 1: storm intro (`scenes/story/storm_intro.tscn`, `scripts/story/storm_intro.gd`, `data/story/intro.json`). 7 captioned panels: sunny rescue center pen (raccoon, frog, owl, lizard, bear) → night storm (rain, lightning, storm sound) → fences crash (shake) → animals scatter → morning, Henrito walks in and explains the mission and how to play. Next/click/Space/Enter, Skip. Title → intro → Meadow. New art: frog/owl/lizard/bear sprites, element tileset (fences), storm sound, "Calm Village" music. 167 tests passing.

- 2026-10-21 — Phase 3, step 2: Rescue Center hub (`scenes/world/rescue_center.tscn`, `scripts/world/rescue_center.gd` extends HabitatMap; map `data/maps/rescue_center.txt` + info file `.json`; `data/maps/world.json`). Five gates (Meadow open, others "coming soon"), five pens with storm-broken fences fixed one per rescue (animated on return), rescued animals living in their pen, Henrito in the plaza with hub lines. Meadow got an east gate back. `GameState`: rescue records, rescued spots stay rescued, travel/arrival. Intro now leads to the hub. 180 tests passing.

## Next
- Phase 3, step 3: care at the Rescue Center — feed by spelling the food name with letter tiles (K: picture match / first letter), short care notes with a choice, fact cards (3–4 kid-level facts) per animal. Text only while the voice is off.
- Chris: listen to the four chase sounds and say if any should change; try Race mode with the 7-year-old and tell me if 45 seconds feels right.

## Open issues
- Special rare animal species still to be chosen by Chris.
- Export presets (Web, Windows, macOS) not set up yet; they need Godot export templates (~1.3 GB) — do this in Phase 7 or when first needed.
- Preschool problem set is Phase 8 (not in skills.json yet).
- Tuning: "Count coins with quarters" (time_money level 5) sometimes makes a pile with no quarter; consider a "require at least one quarter" param.
- The debug screen describes pictures and hints in words; real clock/coin/dot visuals come with the chase screen (Phase 2).
