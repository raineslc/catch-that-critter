# HANDOFF — Catch That Critter (as of 2026-11-04)

Read this first in a new session, then `CLAUDE.md` → `PLAN.md` → `CONVENTIONS.md` → `PROGRESS.md` → `DECISIONS.md`, then run the tests.

## Where things stand
- **Repo:** GitHub `raineslc/catch-that-critter` (private) is the source of truth. Work in `C:\Users\raine\Projects\catch-that-critter`; start every task by fetching and branching from the latest `origin/main`. (The older checkout `C:\Users\raine\CatchACritter` is out of date — don't use it.)
- **314 GUT tests pass** locally and in CI. Last merged: Phase 4 step 1 started — the **Forest** (PR after #25).
- **Done:** Phases 0–3 (setup, math core, Meadow + chases, storm intro, Rescue Center hub, care, stars/levels/shop/Rescue Book), Playtest 2 and 2.1 with their fixes, the hidden snakes (Meadow and Forest), and the Forest habitat.
- **Game flow today:** title → storm intro → Rescue Center hub → west gate = **Meadow** (raccoons, hidden green vine snake), top gate = **Forest** (deer, bears, owls, hidden ball python), east gate = **Swamp** (turtles, frogs, alligators practicing place value; hidden green anaconda), south gate = **Desert** (lizards, tortoises, roadrunners practicing time and money; hidden rattlesnake), northeast gate = **Mountains** (mountain goats, snow leopards, eagles practicing multiply/divide; hidden king cobra). The Swamp, Desert, and Mountains open one by one as he catches the snake in the habitat before.

## Next steps (in order)
1. All five habitats are built (Meadow, Forest, Swamp, Desert, Mountains). To add or change one, follow the Forest's pattern (below); a map can set `"ground_tint"` in its info file (Desert, Mountains).
2. **Habitat unlocking is done:** Meadow and Forest start open; each habitat's hidden snake opens the next (`"opens_after"` in `data/maps/world.json`; `GameState.is_area_open`).
3. **Phase 4 is done:** helper animals were dropped (Chris); the finale (`scripts/story/finale_screen.gd`) plays once at the hub when all five snakes and 6+ animals from each habitat are home.
4. **Phase 5 step 1 done:** two profiles, ranger looks, Loganator.
5. **Next:** Playthrough fixes step 2 (starting level by grade, level up after 5 of 6) — see PLAN.md section 7 and `docs/playthrough_review_2026-11-05.md`. After those 10 steps: Phase 5 step 2, the 10–15 minute session timer with wrap-up; then step 3, the parent area (lock, Common Core report, settings — including editing a profile's name/look).

### How the Forest was added (copy this for each habitat)
- Map: `data/maps/<id>.txt` (48×28, border `P`, gate digit on the edge, one `S`, convex ponds, ≥4 rocks `r`) + `data/maps/<id>.json` (gate back to the hub, `arrive` = the hub's gate digit) + scene `scenes/world/<id>.tscn` (copy `forest.tscn`, change `map_path`) + entry in `data/maps/world.json`. In `data/maps/rescue_center.json` change that habitat's gate from `"locked": true` to `"arrive": "1"`. Add the map path to `MAPS` in `tests/test_map_data.gd` (checks edges, gates, reachability, ponds). The Forest layout came from a small throwaway generator with a reachability check; hand-editing is fine too.
- Animals: `data/animals.json` (habitat, skill, rarity; `"layout": "grid", "frames": 4` for the pack's 4×4 sheets like bear/owl) + a legend character in `data/maps/legend.json` (`critters` and `ground`). The snake: `"rarity": "special", "hides_under_rocks": true`.
- Care: `data/care.json` — 5–6 foods each (word + clue + picture), 4 care notes (≤12 words, `others` + harder `older_others`), 4 facts. Snakes are cared for one grade harder automatically.
- Art: `tools/make_animal_art.py` (2-frame 16×16 strip + 19×19 portrait drawn at 2×, `mirrored()` for faces) and `tools/make_food_icons.py` (16×16 icons). Rerun them after editing the pixel grids; list new files in `assets/CREDITS.md`.
- Tests: copy `tests/test_forest.gd`. Load only one map at a time in a test (two maps share the physics world and push each other's ranger).
- Check visually: a throwaway scene in `.tmp_shots/` (git-ignored) that saves screenshots; `forest_shot.gd` there shows the whole map plus a close-up.

## Key game rules now (details in DECISIONS.md)
- **Chases:** 3 right = caught; **3 misses in one chase = it gets away** (Explore and Race), "Chase again"/"Back to the map". Race mode **30 s**, sprint boost +3 s. Henrito hints after 2 misses on a problem.
- **Stars:** catch 3 (+1 if no misses), care 2, level-up +2, snake 5. Spend in the pen shop ("Decorate"): flowers 5, bush 8, rock 8, tree 15. Shown top right. All numbers in `data/rewards.json`.
- **Animal levels 1–5** per species from care visits (level up at 1, 3, 6, 10).
- **Care:** spell the food with letter tiles (grade 2: one decoy letter; K: first letter or picture match), a care note, then the fact card (one new fact per visit). Raccoon food words cycle through 12 foods in order.
- **Hidden snakes** (Chris's idea, replaced the rare-animal list): one per habitat — Meadow green vine snake, Forest ball python, Swamp green anaconda, Desert rattlesnake, Mountains king cobra. Under a random rock each visit until caught; "Look under the rock"; empty rocks show a bug/worm; after 3 empty rocks Henrito gives a direction clue. **One story (word) problem**, one level above his current level, catches it; a miss sends it under another rock. Each snake lives in a **special pen** beside its habitat's pen (gold "Special" label, fixed when caught) and is cared for **one grade harder**.
- **Rescue Book:** Book button / B at the hub; page per habitat, 3 animals + gold special slot; "???" until rescued.
- **Profiles:** two title buttons (`data/profiles.json`): `user://profiles/default.json` (his, Henrito, grade 2) and `ranger_2.json` (Loganator, grade K, Explore locked). Each has a name and ranger look (`RangerLook`). Playtest 2 has its own save (`playtest_2.json`) and skips the buttons. New save fields (stars, decorations, finale_seen, name, look) are optional so older saves still load — keep doing that.
- **Voice is OFF** (maybe ElevenLabs recordings later — no network calls in the game). Never interrupt TTS (froze Godot on Windows).
- Grade comes from the profile slot (2 for him, K for the second profile).

## How Chris works (follow this)
- Chris builds this for his sons: 7-year-old (main player, ~2nd grade) and 3-year-old (preschool level later). Sidekick: **Henrito** (older son), **Loganator** (younger).
- **One step at a time** on a feature branch from the latest `origin/main`: build → run → fix → commit (clear message, **no AI attribution lines**) → PR → CI green → **merge only when Chris says so** → check off PLAN.md → update PROGRESS.md → **confirm with Chris before the next step**.
- He likes **questions one at a time** (multiple choice with a recommendation) before building something new.
- **Ask before** changing a confirmed decision, downloading anything, or anything outward-facing. Log decisions in DECISIONS.md.
- **Verify visually** with real-window screenshots, not just tests.
- Chris's machine has a **GateGuard hook** that sometimes asks you to state facts before the first edit/command of a kind; answer briefly and retry.
- Explain in plain language; be honest about trade-offs; kid text short, calm, never "wrong".
- Codex review: `AGENTS.md` has review guidelines; Chris still needs to switch on Codex code review at chatgpt.com/codex → Settings → Code review.

## Playtest
- **Playtest 2.1** (`playtest-2.1-snake`): double-click `tools/playtest_2_launch.cmd` in this checkout; separate save; caught raccoons come back after 25 s. Checklist `docs/playtest_2.md`. Summarize: `python tools/summarize_playtest.py` (includes the snake hunt and stars).
- Results so far: Playtest 2 (level 3 → adapted to 2; subtraction is his weak spot). Playtest 2.1: found the snake after 3 empty rocks and caught it on the one try; loved it; bought a rock; didn't open the book. Forest playtest: 9/9 subtraction right, up to level 3; added instead of subtracting on the python's story ("18 leaves, 1 went away"), so it got away; quit spelling "lizards" for the vine snake after 2 misses.
- The old desktop shortcut still runs the frozen Playtest 1 (`C:\Users\raine\CatchACritter-playtest`).
- Next playtest idea: the Forest (new animals, the ball python), and whether he opens the Rescue Book.

## Open items / waiting on Chris
- Turn on Codex code review (see above).
- Try the Forest with his son; are the drawn animals and food pictures clear enough?
- Subtraction is his weakest area — maybe extra subtraction help later.
- Export presets/templates (~1.3 GB) not set up — Phase 7. The art pack zip is no longer in Downloads (new art is drawn in code).

## Handy commands (Windows; Godot isn't on PATH)
```powershell
$g = (Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Packages" -Filter *Godot* | Get-ChildItem -Recurse -Filter *_console.exe | Select-Object -First 1).FullName
& $g --headless --import
& $g --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```
