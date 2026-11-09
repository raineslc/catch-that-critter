# PROGRESS.md — Catch That Critter

Every assistant updates this at the end of a session. Quick overview for a new session: `docs/HANDOFF.md`.

## Current step
Approved review follow-up implemented on `codex/review-fixes`, awaiting Claude's review and merge. See [implementation handoff](docs/CLAUDE_REVIEW_HANDOFF.md). Phase 3 care remains complete; rewards remain next after review/playtesting.

## Done
- 2026-11-09 — Real game, right speed: level up on right answers only (speed rule removed); the chase shows the picked ranger look; `tools/play.cmd` starts the normal game with the answer log on (`-- --log`); `tools/summarize_playtest.py` skips a cut-off line and groups by skill and level. 330 tests pass; chase checked with a real-window screenshot (blonde, blue-outfit ranger). Not played by hand.
- 2026-11-09 — Design, gameplay, and code review: `docs/review_2026-11-09.md` (code read, five real playtest logs, a new 30-minute robot playthrough, screenshots). Main findings: he had only ever played the add/subtract playtest build; the speed rule kept him on one level; two sessions were fast guessing; the robot reaches the top of counting and add/subtract in one playthrough.
- 2026-11-05 — Playthrough fixes step 6: fox and rabbit drawn in the game's pixel style (`tools/make_animal_art.py`) and added to the Meadow (2 of each, in open grass away from the raccoons), with pens, care notes, foods, and facts. The Book's Meadow page can now be filled. 329 tests pass (new: every Book animal can be found on its habitat's map); checked with Meadow, chase, pen, and Book screenshots. Not played by hand.
- 2026-11-05 — Playthrough fixes step 5: in a habitat whose animals are all home, 2 rescued animals slip out about 20 seconds into each visit; catching one gives stars and practice but isn't a new rescue. 328 tests pass. Logic only; not played by hand.
- 2026-11-05 — Playthrough fixes step 4: each hidden snake asks a story in its habitat's skill (counting, add/subtract, place value, time/money, groups/sharing), with 1–2 story templates for every kind of problem; counts in stories start at 2. Clock, coin, group, and counting stories show their picture. 324 tests pass (every skill and level checked over 30 seeds); checked with snake-screen screenshots. Not played by hand.
- 2026-11-05 — Playthrough fixes step 3: hints come after 1 miss on 3-button problems (2 on 4-button ones), so two answers are still left. Problems with no picture show bigger in the middle of the chase screen until the hint. 322 tests pass; checked with chase screenshots (add, place value, multiply, before and after the hint). Not played by hand.
- 2026-11-05 — Playthrough fixes step 2: each skill a profile has never practiced starts at its grade's level (`starting_levels` in `data/adaptive.json`; a grade-2 player starts the Meadow at "which number is more" and the Forest at "within 20"). Level up after 5 of the last 6 right and fast (was 8 of 10). 319 tests pass. Logic only; not played by hand.
- 2026-11-05 — Playthrough fixes step 1 (changed by Chris to one pen per kind): the Rescue Center is now 56×38 tiles with a row of pens per habitat (one per kind of animal, then the snake pen, habitat name above). Each kind lives in its own pen; its fence is fixed in step with how many of that kind are home; "Care for the Bear" shows the animal's face; Care and Decorate sit apart. Decorations show in every pen of their habitat. 315 tests pass; checked with full-hub and close-up screenshots. Old saves replay fence repairs once.
- 2026-11-05 — Full robot playthrough of the real game (all 5 habitats, finale, save/reload; 60 fps, no errors). Notes in `docs/playthrough_review_2026-11-05.md`. Chris approved a 10-step "Playthrough fixes" block in PLAN.md section 7, to do before the rest of Phase 5.
- 2026-10-23 — Implemented the authorized review suggestions: cancelled stale chase transitions, Later/Esc exit, full chase/care keyboard navigation, one local save profile with backup recovery and session mastery, separately saved Playtest 2, food descriptions/word clues, and older-reader care distractors. 235 GUT tests pass; separate-process save/reopen and real-render visual checks pass. No merge to main; child playtest still needed.
- 2026-10-23 - Codex completed a read-only review and, at Chris's request, saved [notes for Claude](docs/CODEX_REVIEW_2026-10-23.md) and linked them from the handoff. Existing care-merge CI success was checked; no fresh local test run or gameplay session was performed. Suggestions await prioritization with Chris; no game code or plan changes.
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

- 2026-10-21 — Fixed a flaky test: `test_freeze_watch` waited for physics frames, which run in a catch-up burst after the deliberate stall before FreezeWatch's `_process` could log "recovered"; it now waits for process frames.
- 2026-10-21 — Phase 3, step 3: care at the Rescue Center. Walk up to a pen with animals → "Care for the Raccoon" → `CareScreen` (`scripts/care/`): feed by spelling the food's name with letter tiles (K: first letter or picture match), a short care note with a choice, then the fact card (one new fact per visit). Logic in `CareCatalog` (`data/care.json`), `SpellingTask`, `CareChoice`, `CareVisit`; `GameState.grade` ("2") and `care_visits`. Henrito hints after 2 misses. Food art: fish, shrimp, honey. Details in DECISIONS.md. 213 tests passing.

- 2026-11-04 — Codex review on GitHub: review guidelines added to AGENTS.md (PR #19). Chris's answers: Race mode 30 seconds, rare animals picked (albino raccoon, white deer, axolotl, fennec fox, red panda), fish/shrimp stay, chase sounds fine, voice stays off (maybe ElevenLabs later). See DECISIONS.md.

- 2026-11-04 — Playtest 2 run and reviewed (10 min, 6 catches, no freezes; adaptive difficulty moved him from level 3 to 2). Fixes from Chris: 3 misses = the animal gets away, raccoon spelling cycles through 12 foods (10 new icons), gate bounce fixed. 240 tests passing.

- 2026-11-04 — Phase 3, step 4: stars (catch 3 + 1 no-miss bonus, care 2, level-up 2), animal levels 1–5 per species from care visits, a small pen shop (4 decorations) and the Rescue Book (page per habitat, special slots). Logic in `Rewards` (`data/rewards.json`) and `GameState`; screens `ShopScreen`, `BookScreen`. 258 tests passing.
- **Phase 3 (Rescue Center) complete.**

- 2026-11-04 — Hidden snakes (Chris's idea, replaces the rare-animal list): the Meadow's green vine snake hides under one of its rocks; "Look under the rock" to find it (finds and a Henrito clue after 3 empty rocks), then one story problem one level harder catches it (5 stars) or it slides under another rock. `SnakeHunt`, `WordProblem` (`data/word_problems.json`), `SnakeScreen`; art from `tools/make_snake_art.py`. 269 tests passing.

- 2026-11-04 — Playtest 2.1 (7 min, no freezes): found the snake after 3 empty rocks and caught it on the one try; 12 stars earned, bought a rock. Then, per Chris: snakes get a special pen beside their habitat's pen and are cared for one grade harder (5 new snake food words). 272 tests passing.

- 2026-11-04 — Phase 4 step 1 begins: the **Forest** (hub's top gate): deer, bears, owls to chase and care for, and the hidden ball python. Grid-sheet animals supported in `Critter`. Art tools renamed/extended (`tools/make_animal_art.py`). 277 tests passing. Handoff for the next session: `docs/HANDOFF.md`.
- 2026-11-04 — Forest playtest: 9/9 first tries right (all subtraction, avg 1.7 s), moved up to level 3; found the ball python after 2 empty rocks but answered 19 for 18 − 1 (added instead of subtracting), so it slid away; fed the bear; quit the vine snake's "lizards" spelling after 2 misses.
- 2026-11-04 — The **Swamp** (hub's east gate): turtles, frogs, alligators (place value) and the hidden green anaconda. 282 tests passing.
- 2026-11-05 — The **Desert** (hub's south gate): lizards, tortoises, roadrunners (time and money) and the hidden rattlesnake; sandy ground tint. 287 tests passing.
- 2026-11-05 — The **Mountains** (hub's northeast gate): mountain goats, snow leopards, eagles (multiply/divide) and the hidden king cobra. All five habitats are built. 292 tests passing.
- 2026-11-05 — **Habitat unlocking** (Phase 4 step 1 done): the Meadow and Forest start open; each hidden snake opens the next habitat. 297 tests passing.
- 2026-11-05 — Phase 4 done: helper animals dropped (Chris); the **finale** plays once when all five snakes and 6+ animals from each habitat are home. 303 tests passing.
- 2026-11-05 — Phase 5 step 1: **two profiles** (big title buttons, name typed once), ranger hair/skin/outfit recolors, and **Loganator** for the second profile. 314 tests passing.

## Next
- Chris: turn on Codex code review for the repo at chatgpt.com/codex → Settings → Code review (automatic reviews).
- Phase 5 step 2 (confirm with Chris first): 10–15 minute session timer with wrap-up. Then step 3: parent lock, progress report, settings.
- Chris: playtest the new habitats (catch the ball python to open the Swamp).
- Chris: are the care notes and facts at the right reading level? (Check during Playtest 2.)

## Open issues
- Special rare animal species still to be chosen by Chris.
- Export presets (Web, Windows, macOS) not set up yet; they need Godot export templates (~1.3 GB) — do this in Phase 7 or when first needed.
- Preschool problem set is Phase 8 (not in skills.json yet).
- Tuning: "Count coins with quarters" (time_money level 5) sometimes makes a pile with no quarter; consider a "require at least one quarter" param.
- The debug screen describes pictures and hints in words; real clock/coin/dot visuals come with the chase screen (Phase 2).
