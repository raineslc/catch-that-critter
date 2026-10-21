# DECISIONS.md — Catch That Critter

Dated log of decisions and why. Confirmed decisions (PLAN.md section 2) change only with Chris's approval.

## 2026-10-20 — Plan approved
Chris approved PLAN.md. It supersedes the Google Doc "Catch That Critter – Design Doc", which described a 3D game.

## 2026-10-20 — 2D top-down instead of 3D
Keeps scope manageable for a personal project; free 2D asset packs are plentiful.

## 2026-10-20 — Godot 4 + GDScript
Free, small web exports, built-in tilemaps, camera and text-to-speech; easy desktop + web builds. GDScript is simple and readable by any AI assistant.

## 2026-10-20 — Multi-AI workflow
The GitHub repo is the single source of truth so Claude, ChatGPT, and Gemini can all pick up the work. Shared files: PLAN, CONVENTIONS, PROGRESS, DECISIONS; pointer files: CLAUDE.md, AGENTS.md, GEMINI.md.

## 2026-10-20 — Pinned Godot 4.7.2 and GUT 9.7.1
Godot 4.7.2 was the latest stable 4.x at setup. GUT 9.7.1 is the GUT release made for Godot 4.7. Compatibility renderer so the same project runs well on the web.

## 2026-10-21 — Art pack: Ninja Adventure (CC0)
- Chris picked **Ninja Adventure** by Pixel-Boy & AAA (CC0, 16×16 top-down) over Kenney: one consistent style with character portraits (good for Henrito's hint bubble), tiles, UI, sounds, music. Files we use are listed in `assets/CREDITS.md`.
- Animals in the pack that match the plan: raccoon, bear, owl, frog, alligator (Reptile2), lizard, snake. **Missing:** fox, rabbit, deer, turtle, tortoise, mountain goat, snow leopard, eagle — decide in Phase 2 step 2 (swap species, find matching CC0 sprites, or recolor).
- The pack's characters are whole sprites, not hair/skin/outfit layers. "Customizable ranger via swappable sprite layers" (PLAN 2) likely becomes "pick from several kid rangers" in Phase 5 — needs Chris's OK then. Placeholder ranger: the pack's "Hunter".
- Meadow uses the pack's lighter yellow-green grass: it's the only grass that matches the pond shore tiles.

## 2026-10-21 — Freeze during Playtest 1: investigation
- **What happened:** first playtest session (14:32) hard-froze (everything stopped; force-quit from Task Manager) right after the first answer of chase 3, at t=47.1s — exactly 25.0s after the first raccoon was caught, i.e. the moment it came back. No Windows hang/crash report; Godot's own log wasn't written for the shortcut launch.
- **Tried:** a robot player (12 chases, real window, TTS on, comebacks every 4s landing mid-chase) did not freeze.
- **Added (playtest-only):** `FreezeWatch` — breadcrumbs at each step (problem made, buttons ready, TTS stop/speak/queued, sounds, net toss, raccoon comes back) and a background-thread watchdog that writes a `freeze` event with the last 12 steps to the playtest log after 5s without a frame (`recovered` if it wakes up); `respawn` events in the log; `tools/playtest_launch.cmd` saves Godot's verbose log per session with a timestamp; summary script reports freezes. Released as `playtest-1.1`.
- Suspects until proven: Windows TTS (`tts_stop`/`tts_speak`) on the main thread; something in the comeback path during a chase.
- **Root cause (found same day):** a realistic robot player (walks, real mouse clicks, 25s comebacks) froze in its 5th chase; the freeze detector showed the main thread stuck inside `DisplayServer.tts_stop()`, called when the next question arrived while the voice was still reading the previous one (fast answerers trigger this constantly). The raccoon comeback in Chris's session was a coincidence. A TTS-only stress test (150 speak/stop cycles, random gaps) **crashed or hung in 4 of 5 runs** when stopping/interrupting speech (`tts_stop()` or `tts_speak(..., interrupt=true)`), and **never** (2/2 runs OK) when the voice was left to finish.
- **Fix:** `Speech` never stops or interrupts the voice. A line asked for while it's talking waits (only the newest waiting line is kept) and `GameState` speaks it as soon as the voice is quiet. `Speech.stop()` only drops the waiting line. The debug screen goes through `Speech` too. A test fails if any script calls `tts_stop(` or an interrupting `tts_speak`.
- Trade-off: if he answers before the question finishes being read, the rest of that sentence still plays, then the next question is read.

## 2026-10-21 — Playtest 1 before Phase 3
Chris asked for a playtest before starting Phase 3. Setup (all playtest-only, switched on by the `--playtest` launch flag so the normal game is unchanged):
- **Math:** every chase uses `playtest_add_sub_12` from `data/playtest.json` — adding and subtracting with every number (problem and buttons) 12 or less, 7 levels from "add within 6" to "missing number within 12" (Chris: "start with only numbers up to and including 12").
- **More play:** the Meadow now has 6 raccoon spots (kept for the real game too); in playtests a caught raccoon comes back after 25 seconds.
- **Log:** every answer, hint, level change, chase, and escape goes to `%APPDATA%\Godot\app_userdata\Catch That Critter\playtest\*.jsonl` (local only). `tools/summarize_playtest.py` makes a readable report.
- **Launch:** desktop shortcut runs Godot 4.7.2 on a frozen copy of the `playtest-1` tag in `C:\Users\raine\CatchACritter-playtest` (git worktree), so Phase 3 work can't break the playtest.
- New: `AddSubtractGenerator` "choice_max" param caps addition buttons; `ProblemFactory.add_skill()`; game icon from the raccoon portrait.

## 2026-10-21 — Race mode and Henrito's hints (details)
- Race: 45 seconds per chase (`data/chase.json`). A right answer within 5 seconds is a **sprint boost**: closes extra distance and adds 3 seconds. When time runs out the critter gets away; "Chase again" restarts the same chase, "Back to the map" returns to the Meadow. Nothing is lost.
- The kid picks Explore or Race with a button in the Meadow's corner; it's hidden and Explore is forced when `GameState.explore_locked` is on (the parent area sets it in Phase 5). Default is Explore.
- Henrito appears as a portrait in a speech bubble: cheers at the start, on sprints, on catches and escapes (lines in `data/sidekicks.json`), and after 2 misses on one problem (1 with extra help) says a one-sentence strategy hint aloud while a hint picture replaces the problem picture. Hints point to a strategy (count up, look at the biggest place, start with the biggest coin) and never say the answer.
- Henrito's art is the pack's "Boy" character (brown hair). His voice is TTS at rate 0.9, slightly higher pitch.
- Answer buttons now handle clicks a frame later (deferred) so old buttons can be removed safely.

## 2026-10-21 — Chase is its own screen
PLAN 3.6 says the camera follows the animal along a path with the ranger following automatically. Built as a full-screen chase view: a scrolling path at 4× zoom (critter ahead, ranger behind, gap shrinks/grows with answers) above a big question panel. The world freezes underneath and resumes after. Simpler and clearer for a 7-year-old than steering through the real map, and it leaves room for the problem, picture, and big buttons.
- Every try moves the chase (right closes the gap, a miss lets the critter pull ahead); only the first try goes to the difficulty engine.
- Explore mode has no way to lose: misses never end the chase. (Race mode's timer comes in the next step.)
- Pictures (critters to count, analog clock, US coins labeled by name not value, equal groups) are drawn in code. The pack has no net, so it's drawn too.
- Sounds picked by file name without listening (coin "ding", soft blip, whoosh, success jingle) — Chris to listen and swap if needed (`assets/audio/sfx/`).
- `GameState` autoload holds the session's problem factory, difficulty engine, animal catalog, and rescued list until profiles/saves arrive (Phase 5). New players start every skill at level 1 for now.

## 2026-10-21 — Missing species: pack animals now, fill gaps later
Chris chose to build with the pack's animals first (raccoon in the Meadow now) and find or make fox, rabbit, deer, turtle, tortoise, mountain goat, snow leopard, and eagle before they're needed (fox/rabbit/deer before the MVP is done). The confirmed animal list in PLAN.md is unchanged.

## 2026-10-21 — Maps are text files
Habitat layouts live in `data/maps/*.txt` (one character per 16px tile; meanings in `data/maps/legend.json`) so they can be edited without Godot. Ponds must be convex (no inside corners); a test enforces it.

## 2026-10-21 — Adaptive engine details (clarifies PLAN.md 3.11)
- Mastery credit flows down: a good session (≥ 80%, ≥ 5 answers) at level N counts toward levels 1..N. Without this, the level-up rule (8 of last 10, fast) moves a strong player on before any level could collect 3 good sessions.
- A poor session at level N resets the streak for N and harder levels; easier levels keep their streak.
- Level down can trigger after 6 answers (not a full 10) so a struggling kid gets relief sooner; it also turns on "extra help" (hint after 1 miss instead of 2) until they're back to ≥ 50%.
- Only the first try at each problem counts. "Fast" = average seconds of correct answers; default 8s, clocks/coins 12s, multiply/divide 10s.
- All numbers live in `data/adaptive.json` for tuning after playtests.

## 2026-10-20 — Local saves only, TTS first, free art first
No accounts or cloud; privacy for kids. Text-to-speech before recorded voices; free asset packs before custom art.
