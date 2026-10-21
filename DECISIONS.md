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
