# DECISIONS.md — Catch That Critter

## 2026-11-05 — One pen per kind of animal (Chris; Playthrough fixes step 1)
- Replaces one shared pen per habitat (and the first draft of step 1, a button per kind in a shared pen). Each kind gets its own pen, grouped in a row by habitat with the habitat's name above; the snake's special pen ends the row. Pens are laid out in `data/maps/rescue_center.json` (`"slots": 3` per habitat, so the Meadow has room for the fox and rabbit).
- The Rescue Center map grows from 40×26 to 56×38 tiles to fit five rows of four pens.
- Fence repair: each kind's pen has 4 sections, fixed in step with how many of that kind are home (all home = fully fixed), counted from the habitat maps.
- Bought decorations stay per habitat and show up in every pen of that habitat.
- Old saves: repairs already shown were tracked per habitat, so the first visit after this change replays the fence repairs once.

## 2026-11-05 — Playthrough fixes plan (Chris)
A robot played the whole game (notes: `docs/playthrough_review_2026-11-05.md`). Chris picked:
- **Fox and rabbit:** add them to the Meadow (find or make art); the confirmed animal list stays.
- **Replay:** rescued animals slip out again once a habitat is cleared; catching them gives stars and practice, not new rescues.
- **Difficulty:** the profile's grade picks each skill's starting level; level up after 5 of the last 6 (was 8 of 10). Changes PLAN 3.11.
- **Snake stories:** each snake asks a story in its habitat's skill. Changes PLAN 3.4.
- **Order:** gameplay fixes first, then HUD, habitat looks, and art. Done before the rest of Phase 5.

## 2026-11-05 — Two profiles and ranger looks (Phase 5 step 1, Chris)
- Title screen shows **two big buttons**, one per boy: his ranger's face, his sidekick's face, his name (typed once), "with Henrito/Loganator". Slots live in `data/profiles.json`.
- Slot 1 is his existing save (`user://profiles/default.json`, Henrito, grade 2) — nothing to migrate; the first time he picks it, he names his ranger and keeps all his progress. Slot 2 is new (`ranger_2.json`): Loganator, grade **K**, Explore locked, until the preschool level exists (Phase 7).
- **Ranger look:** pick hair (red, brown, blonde, black), skin (4 tones), and outfit (teal, green, blue, red) by tapping swatches with a live preview. Done by recoloring the pack's ranger in code (`RangerLook`, colors in `data/ranger_looks.json`); the art shares one red for hair and skin shadow, so red pixels touching skin count as skin shadow.
- **Loganator** (the big brother) is Henrito's pack art recolored (brown hair, green ranger shirt) by `tools/make_loganator_art.py`, with Henrito's lines for now.
- New save fields `name` and `look` are optional (older saves still load). Tests and `--no-save` never read the real saves.

## 2026-11-05 — No helper animals; the finale (Chris)
- Helper animal bonuses (PLAN 3.5) are dropped.
- The finale plays once at the Rescue Center when all five snakes are caught **and** at least 6 other animals are home from each habitat (`"finale_critters_per_habitat": 6` in `data/maps/world.json`). Clear sky with a rainbow, sun and confetti, every rescued kind of animal hopping, the sidekick's thanks, and a "Hooray!" button. Saved as `finale_seen` (optional field, so older saves still load).

## 2026-11-05 — Habitat unlocking: the snake opens the next habitat (Chris)
- Changes PLAN 3.4 ("habitats unlock as skills are mastered"): mastering a level takes 3 play days at 80%+, too slow. Instead the Meadow and Forest start open, and catching a habitat's hidden snake opens the next: Forest's ball python → Swamp, Swamp's green anaconda → Desert, Desert's rattlesnake → Mountains.
- Set in `data/maps/world.json` as `"opens_after": "<habitat>"`. A closed gate is fenced with a sign "(find the Forest snake)" and the banner "Find the Forest's hidden snake to open the Swamp!". Catching the snake adds "The Swamp is open now!".
- His saves (normal and Playtest 2) haven't caught the ball python yet, so the Swamp, Desert, and Mountains start closed for him.

## 2026-11-05 — The Mountains (last habitat of Phase 4 step 1; Chris: merge the Desert and continue)
- The hub's northeast gate opens to the Mountains: mountain goats (3), snow leopards (2, fast), eagles (2), and the hidden king cobra under one of 10 rocks, with pine groves and a lake and a cool ground tint. Mountain animals practice **multiplying and dividing**; the cobra's story stays add/subtract.
- All five habitat gates are open now; the "opens soon" fence stays in the code for habitat unlocking.
- Drawn in code: mountain goat, snow leopard, eagle, king cobra, and grass and meat food icons.
- Care foods: goat grass/clover/leaves/apples/corn/berries; snow leopard meat/mice/rats/eggs/fish; eagle fish/mice/rats/lizards/meat; king cobra mice/lizards/eggs.

## 2026-11-05 — The Desert (Phase 4 step 1; Chris: merge the Swamp and continue)
- The hub's south gate opens to the Desert: lizards (3), tortoises (2), roadrunners (2, fast), and the hidden rattlesnake under one of 8 rocks, with a small oasis. Desert animals practice **time and money** (clocks and coins); the rattlesnake's story stays add/subtract.
- The art pack has no sand, so a map's info file can set `"ground_tint"`; the Desert tints its grass sandy (the oasis water picks up a slight tint too).
- Lizard art is the pack's (4×4 grid). Tortoise (turtle shape, desert colors), roadrunner, rattlesnake, and a cactus food icon are drawn in code.
- Care foods: lizard crickets/bugs/worms/flies/berries; tortoise cactus/clover/leaves/berries/apples/corn; roadrunner lizards/crickets/bugs/mice/eggs; rattlesnake mice/rats/lizards.

## 2026-11-04 — The Swamp (Phase 4 step 1, after the Forest playtest; Chris: "move to the next phase")
- The hub's east gate opens to the Swamp: turtles (3), frogs (3), alligators (2), and the hidden green anaconda under one of 7 rocks. Swamp animals practice **place value** (PLAN 3.4's Swamp skill); the anaconda's story problem stays add/subtract like every snake.
- Playtest 2 still forces add/subtract for every chase (its playtest skill overrides the animal's), so place value only shows in normal play.
- Frog art is the pack's. Turtle, alligator, green anaconda (vine snake shape in olive), and food icons flies and snails are drawn in code.
- Care foods: turtle worms/bugs/fish/leaves/berries/snails; frog flies/crickets/worms/bugs/snails; alligator fish/crab/shrimp/eggs/snails; anaconda fish/rats/eggs.

## 2026-11-04 — The Forest (Phase 4 step 1 begins; Chris: one habitat per PR, Forest first)
- The hub's top gate opens to the Forest: deer (3), bears (2), owls (2), and the hidden ball python under one of 6 rocks. Forest animals use the add/subtract skill (Forest's skill in PLAN 3.4).
- Bear and owl use the pack's 4×4 sheets (`"layout": "grid"`, right-facing column). The deer, ball python (the vine snake's shape in python colors), and food icons leaves, clover, berries, rats, gerbils are drawn in code (`tools/make_animal_art.py`, `tools/make_food_icons.py`). "Acorns" reuse the nut picture.
- Care foods: deer leaves/clover/acorns/apples/corn/berries; bear fish/honey/berries/nuts/apples/bugs; owl mice/crickets/worms/bugs/lizards; ball python mice/rats/gerbils (grade-up care like every snake).
- Habitat unlocking (PLAN 3.4) waits until the Swamp exists; for now every built habitat's gate is open.

## 2026-11-04 — Snakes get special pens and harder care (after Playtest 2.1, Chris)
- Each habitat pen is now 2 rail sections wide with a 1-section **special pen** right beside it (gold "Special" label). Its fence stays knocked over until that habitat's snake is caught, then the whole special pen is fixed; snakes don't fix the regular pen's fences. Regular pens: 4 sections now (was 6). Decorations are for regular pens only.
- **Snake care works like raccoon care, one grade harder** (`CareCatalog.harder_grade`: K→1, 1→2, 2→3, 3 stays 3): spell 3rd-grade food words (lizards, geckos, tadpoles, crickets, mice — not frogs, since frogs are rescue animals here) with 2 extra letters, then a longer care note, then its fact card, one fact per visit (snake facts moved from `animals.json` to `care.json`). Snakes level up from care like other animals.
- Playtest 2.1: he loved finding the snake (caught it on the one try after 3 empty rocks).

## 2026-11-04 — Special animals are hidden snakes (Chris; replaces the rare-animal list from earlier today)
- One hidden snake per habitat: **Meadow green vine snake** (built first), Forest ball python, Swamp green anaconda, Desert rattlesnake, Mountains king cobra. The Desert's regular "snake" becomes a **roadrunner**.
- **Finding:** it hides under one of the habitat's rocks, a different one each visit, every visit until caught. "Look under the rock" when next to one. Empty rocks show a worm, bugs, or a beetle with "Try another rock!"; after every 3 different empty rocks Henrito says which way it is (up/down/left/right).
- **Catching:** one story problem (add/subtract) one level above the player's current level in the chase skill (plain add/subtract for skills without stories yet). A right answer catches it (5 stars); a miss: "slid away to hide under another rock," shows the answer kindly, and it moves to a different rock. Snake answers don't count toward adaptive difficulty (they're above level on purpose).
- Snakes come with their whole fact card (in `data/animals.json`) and live in their habitat's pen; they aren't fed or cared for.
- Art drawn for the project (`tools/make_snake_art.py`), since the pack zip is gone from Downloads.

## 2026-11-04 — Stars, levels, shop, and the Rescue Book (Phase 3 step 4, Chris's choices)
- **Stars:** 3 per catch + 1 bonus for a chase with no misses; 2 per finished care visit; 2 more when an animal levels up. Misses never take stars away. All numbers in `data/rewards.json`.
- **Animal levels 1–5, per species**, from finished care visits: level 2 at 1 visit, 3 at 3, 4 at 6, 5 at 10. Shown under the pen ("Raccoon level 2") and in the book.
- **Small pen shop now** ("Decorate" next to "Care for..." at a pen with animals): flowers 5★, bush 8★, rock 8★, tree 15★, each once per pen, using the map's own nature art. Decorations don't block the animals. Animal accessories come later.
- **Rescue Book** (Book button or B at the hub): one page per habitat with its 3 animals and a gold "special" slot; animals not rescued yet show "???". A rescued animal shows its level, how many are home, and the facts learned from care.
- Stars and decorations are saved. They are optional fields, so saves from before this step still load (starting at 0 stars).

## 2026-11-04 — After Playtest 2 (Chris)
- **Three misses and the animal gets away**, in Explore and Race mode alike (`misses_to_escape` in `data/chase.json`; misses count across the whole chase). This replaces "Explore mode has no way to lose" from 2026-10-21. The escape shows "Chase again" / "Back to the map", and nothing is lost. Henrito's hint still comes after the 2nd miss on a problem.
- **Raccoon food words cycle through 12 foods** (Chris asked for at least 10, raccoon-appropriate and spellable): fish, corn, bugs, nuts, eggs, crab, clams, plums, worms, grapes, apples, shrimp — roughly easy to harder. A finished care visit moves to the next word; the whole list comes before any repeat. The pack only has fish and shrimp art, so the other 10 icons were drawn for the project (`tools/make_food_icons.py`).
- **Gate bounce fixed:** the gate you arrive through stays off until you walk about 3 tiles away, so holding the arrow key doesn't carry you straight back out.
- The fast misses in the log were Chris testing wrong answers on purpose, not guessing.

## 2026-11-04 — Chris's answers: race timer, rare animals, voice, sounds
- **Race mode: 30 seconds** per chase (was 45; `data/chase.json`). Chris: he answers fast, so shorter is more exciting. Sprint boost (+3s) unchanged.
- **Special rare animals** (one per habitat): Meadow albino raccoon, Forest white deer, Swamp axolotl, Desert fennec fox, Mountains red panda. (Snow leopard stays a regular Mountains animal.) Art still to be found or made in Phase 4.
- **Raccoon food words stay fish and shrimp.**
- **Chase sounds:** all four are fine as they are.
- **Voice stays off.** Revisit audio later, possibly with ElevenLabs voices recorded ahead of time and shipped as audio files (no network calls in the game).
- **Order:** Playtest 2 first, then Phase 3 step 4 (stars, animal levels, collection book), shaped by what the playtest shows.

## 2026-10-23 — Review fixes authorized on a review branch
Chris: "Go ahead and make the suggested changes. Create a new branch that claude can review and merge to main."
Implement the review follow-up together on `codex/review-fixes`, leaving merge to Claude. Bring a single local save profile and session completion forward from Phase 5; keep multi-profile customization, timed wrap-up, and the parent area planned. Give the current full-loop playtest its own save so it cannot alter normal-game progress. Keep speech off; use a short food description and an optional reveal-and-hide word clue for unclear pictures. Preserve the frozen Playtest 1 worktree and shortcut.

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

## 2026-10-21 — Caring for animals (details for PLAN.md 3.9)
- Walk up to a pen with animals in it → "Care for the Raccoon" button (or Space/Enter) → care screen; the world waits underneath, like a chase.
- One visit = **feed → care note → fact card**. Care is per species (all the raccoons share one card). The kid presses Next when ready (no timers); "Later" leaves without counting the visit.
- **Feeding by grade** (`data/care.json`): 1st–3rd spell the whole word with letter tiles (0 / 1 / 2 extra decoy letters); K gets either "first letter" (3 tiles, rest of the word shown) or "match the word to a picture" (3 pictures). The 7-year-old is set to grade 2 (`GameState.grade`) until profiles in Phase 5. Spelling isn't adaptive yet.
- Tiles fill the blanks left to right; another letter wiggles and stays (gentle "Try again"). After 2 misses on one letter Henrito says "Next comes the letter h." and that tile glows. Never shows the whole word.
- Care notes: one short sentence + a question, one sensible choice and one silly one. The silly choice is greyed out with "Let's try the other one." Notes take turns visit by visit.
- **Fact cards: one new fact per visit** (marked "New!") until all 3–4 are known — a reason to come back, and only one new sentence to read each time.
- The "Read to me" button on the fact card only appears when the voice is on (it's off since Chris's call); text only for now.
- **Raccoon food = fish and shrimp** (not nuts): the pack's nut pictures look like a cookie/ball, and the picture has to be clear for spelling to work. Raccoons do eat both. Honey is the third picture for the K picture match (and the bear later). Chris to say if he'd rather have easier words (shrimp is 6 letters with "shr").
- Care can be repeated right away for now; stars and animal levels (next step) will decide any limits.

## 2026-10-21 — Rescue Center hub with gates; new games start there (Chris)
- Changes PLAN 3.4's "one scrolling map": the Rescue Center is its own area in the middle with a gate per habitat (west Meadow, north Forest and Mountains, east Swamp, south Desert); each habitat is its own small text map. Gates to habitats that aren't built yet are fenced off with a "(coming soon)" sign. Keeps maps small and easy to edit.
- After the storm intro, new games start at the Rescue Center; Henrito stands in the plaza and points to the Meadow gate, later cheers how many animals are home.
- One pen per habitat, 6 fence sections each (3 rail pieces × top/bottom), all knocked over by the storm. Each rescue from a habitat fixes one section of its pen; fixes since your last visit stand up while you watch with a banner ("You fixed 2 fences! Meadow pen: 2 of 6"). Rescued animals live and wander in their pen (up to 8 shown).
- Rescued map spots are remembered (`GameState.rescues`), so a caught raccoon doesn't reappear when you go back to the Meadow (playtest mode still brings them back). Everything resets when the game closes until saves arrive in Phase 5.

## 2026-10-21 — Voice off for now (changes a confirmed decision, with Chris's approval)
Chris: "some of the voice lines are off and they all sound weird. Let's leave the voice out of it for now." `GameState.read_aloud` now defaults to off: questions, Henrito's cheers and hints are shown as text only (his speech bubble stays). The `Speech` wrapper (never-interrupt fix included) stays in the code, unused, so audio can return later — better voices or recorded lines. Must be revisited before the preschool level (Phase 8), which can't work without audio. Open: which lines sounded "off" (wording vs. pronunciation).

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
