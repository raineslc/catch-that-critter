# PLAN.md — Catch That Critter

> Handoff plan for AI coding assistants (Claude Code, ChatGPT/Codex, Gemini). Design reference: Google Doc "Kids Math Game – Design Doc (Pet Shelter Chase)" (note: the doc still describes 3D; this plan supersedes it).
> Workflow (Chris's new-coding-project process): approve plan → set up git → build one small, tested step at a time with a commit per step → verify with tests and review → README, secrets in env vars, deployment.
> **Status:** Approved by Chris on 2026-10-20. Next: Playthrough fixes (section 7, added 2026-11-05).

## 1. Goal & Success Criteria
**Catch That Critter** is a personal **2D top-down** educational game Chris is building for his sons. Kids play as a customizable kid ranger, walk around one big map (classic Pokémon-style view), chase runaway wild animals by answering Common Core–aligned math problems, and bring them back to a Wildlife Rescue Center where they care for them through spelling/reading tasks and unlock kid-friendly animal fact cards.

Not a commercial product: no pricing, store listings, ads, or school licensing.

**Success = the MVP in section 8 runs in a browser and on desktop, and the 7-year-old can play a full 10–15 minute session on his own.**

## 2. Decisions (confirmed)
- Title: **Catch That Critter**.
- Visual style: **2D top-down** (changed from 3D to keep scope manageable).
- Engine: **Godot 4** (2D), GDScript.
- **Multi-AI project:** workable across **Claude, ChatGPT, and Gemini** (section 6).
- Players:
  - Older son, age 7: main player now; start around **2nd grade** (adaptive system adjusts).
  - Younger son, age 3: plays later; needs a **preschool level** (3.5).
  - Both love wild animals, reptiles, and interesting animals.
- Platforms: **desktop (Windows/macOS) and web** first. Tablets later.
- Player character: **customizable kid ranger** (skin tone, hair, outfit via swappable sprite layers).
- Story: **a big thunderstorm** knocks down the rescue center's fences and the animals scatter across the map.
- Sidekick / hint-giver: **the ranger's brother, set per profile**:
  - Older son's profile: **Henrito**, the little brother (regardless of ranger customization).
  - Younger son's profile: **Loganator**, the older brother.
  - Look: generic white boys with brown hair (Henrito smaller/younger, Loganator taller/older), junior-ranger outfits.
  - Voice: calm and encouraging (TTS; gentle voice, slightly slower rate). No recorded voices of the boys.
- Math curriculum: **Common Core** aligned (K–3, plus preschool later).
- Session length: **10–15 minutes**, with a gentle wrap-up.
- Rescued animals **stay in enclosures** at the Rescue Center.
- **Special rare animals:** yes; species chosen by Chris later.
- **No day/night cycle.**
- Art: **free 2D asset packs** (e.g., Kenney top-down/RPG tiles and animal sprites); custom art later.
- Read-aloud: **text-to-speech** first. **Paused 2026-10-21 (Chris):** the Windows voices sounded weird and some lines were off, so the voice is off for now; all text still shows on screen. Revisit before the preschool level (which needs audio) — better voices or recorded audio.
- Saves: **local on device only**.

## 3. Design Details

### 3.1 Story
- Short intro (a few illustrated panels with TTS narration): thunderstorm, fences fall, animals scatter.
- The sidekick brother greets the ranger and explains the mission: bring every animal home.
- Each capture repairs a section of fence at the Rescue Center.
- Finale when all animals are home: clear sky and a celebration. **(Chris 2026-11-05: all five snakes caught and at least 6 other animals home from each habitat; plays once.)**

### 3.2 Profiles
- Two profiles now (allow up to 4).
- Each stores: name, ranger look, starting level (Preschool, K–3), sidekick (name, sprite, voice settings), progress.
- Sidekick is data-driven per profile, so Henrito and Loganator share one hint system.

### 3.3 Sidekick Behavior
- Every line calm, warm, encouraging; never says "wrong." E.g., "Nice try, let's count together." "You've got this."
- Appears for hints after 2 misses, at session start/end, and to celebrate captures. Shows as a small portrait in a speech bubble.
- One-sentence lines.

### 3.4 Map & Habitats (Common Core aligned)
Rescue Center hub in the middle with a gate to each habitat; each habitat is its own top-down map (changed from one big scrolling map on 2026-10-21, Chris's choice; see DECISIONS.md). New games start at the Rescue Center.

| Habitat | Skill focus | Grade | Example standards | Animals |
|---|---|---|---|---|
| Meadow | Counting, number recognition, comparing to 20 | K | K.CC | Fox, raccoon, rabbit |
| Forest | Add & subtract within 20, then 100 | 1–2 | 1.OA, 2.OA, 2.NBT.5 | Deer, bear, owl |
| Swamp | Place value, comparing (<, >, =) | 2 | 1.NBT, 2.NBT.1–4 | Turtle, frog, alligator |
| Desert | Telling time, counting money | 2–3 | 1.MD.3, 2.MD.7–8, 3.MD.1 | Lizard, tortoise, roadrunner |
| Mountains | Multiplication & intro division | 3 | 3.OA | Mountain goat, snow leopard, eagle |

- Every problem type in `skills.json` has a `standards` field for the parent report.
- Habitats unlock as skills are mastered; for the 7-year-old, Meadow and Forest start unlocked. **Changed 2026-11-05 (Chris):** catching a habitat's hidden snake opens the next habitat (Forest → Swamp → Desert → Mountains); mastery took too long (3 play days per level).
- Rarity tiers: common / uncommon / rare / **special**. **Special = each habitat's hidden snake** (Chris, 2026-11-04): Meadow green vine snake, Forest ball python, Swamp green anaconda, Desert rattlesnake, Mountains king cobra. It hides under one of the habitat's rocks (a different one each visit) until caught; peek under rocks to find it (empty rocks hold a bug or worm; after 3 empty rocks the sidekick gives a direction clue). Catching it takes **one story (word) problem**, one level harder than the player's current add/subtract level (**changing 2026-11-05, Chris:** a story in the habitat's own skill, Playthrough fixes step 4); a miss and it slides under another rock to find again. It comes with its own fact card and lives in the pen.
- Constant bright daytime; no day/night cycle.

### 3.5 Preschool Level (later, for the younger son)
- No reading: everything spoken by TTS and shown with pictures.
- Count critters (1–10), tap the matching number, "more" or "fewer," simple shapes.
- Bigger buttons, slow chases, no timer, no penalty.
- Rescue Center care via picture-matching.

### 3.6 Exploring & Chase Mechanic (2D top-down)
- Ranger walks the map with arrow keys/WASD or click-to-move (tap later on tablets).
- Animals wander in their habitat; walking close startles one and starts a chase.
- In a chase, the camera follows as the animal runs along a path and the ranger follows automatically; a problem appears with 3–4 big answer buttons.
- Correct: ranger speeds up. 3 correct = toss the net = capture.
- Wrong: animal pulls ahead a little; gentle "try again" sound.
- Fast correct answers give a sprint boost (Race mode only).
- After 2 misses on the same problem, the sidekick gives a visual hint (dots, number line, clock, coins), read aloud.

### 3.7 Modes
- **Explore:** no timer. Default for Preschool and K.
- **Race:** timer per chase; animal escapes if time runs out (retry right away).
- Parent setting can lock Explore.

### 3.8 Sessions
- 10–15 minutes (parent-adjustable).
- At the limit, the sidekick says it's "time to let the animals rest"; current chase/task finishes, then a summary (animals rescued, stars) and save.

### 3.9 Wildlife Rescue Center (Literacy Layer)
- Top-down hub with **enclosures** that fill as animals come home.
- Feed: spell the food's name with letter tiles (K: picture-match or first letter; Preschool: picture-match).
- Care notes: short sentences, then a simple choice.
- Fact cards per animal: 3–4 facts at K–3 reading level, TTS read-aloud button.
- ~~Helper animals: well-cared-for animals give chase bonuses.~~ Dropped by Chris 2026-11-05.

### 3.10 Rewards & Progression
- Stars from chases and care; spend on enclosure decorations and animal accessories.
- Fence repair after the storm.
- Animal levels 1–5 through care.
- Collection book with special slots for special animals. No leaderboards.

### 3.11 Adaptive Difficulty
- Per-skill accuracy and response time.
- Rolling last 10 problems: ≥ 80% correct and fast → step up; < 50% → step down, more hints. **Changing (Chris 2026-11-05, Playthrough fixes step 2):** step up after 5 of the last 6; each skill's starting level comes from the profile's grade.
- Mastery = 3 consecutive sessions above 80% at a level. A good session at a harder level also counts for the easier levels in that skill (otherwise fast learners level up before ever "mastering" anything); a poor session resets that level and harder ones. Sessions with fewer than 5 answers at a level don't count either way.
- Only the first try at each problem counts; "fast" is the average time of correct answers (per-skill limits in `data/adaptive.json`, e.g. clocks get longer).

### 3.12 Parent Area
- Parent lock (e.g., "What is 7 × 8?" or hold-to-unlock).
- Per profile: mastered/struggling skills with Common Core codes, time played, animals rescued.
- Settings: lock Explore, session length, volume, edit sidekick, starting level, reset profile.

### 3.13 Accessibility & Child Safety
- Big targets (min ~64 px; larger in Preschool), high contrast, dyslexia-friendly font option.
- All instructions available as TTS.
- No ads, purchases, chat, or external links. Data stays local.

### 3.14 Art & Audio
- Bright, friendly 2D pixel or flat-vector style from free packs; pick one consistent pack family.
- Sidekick sprites: brown-haired, light-skinned kids in junior-ranger outfits.
- Storm intro sounds, cheerful music per habitat, positive sound effects.
- Track licenses in `assets/CREDITS.md`.

## 4. Tech Stack & Why
- **Godot 4 (2D):** free, small web exports, built-in TileMapLayer, Camera2D, and DisplayServer text-to-speech; easy desktop + web export; tablets later.
- **GDScript:** simple, readable by any AI assistant.
- **JSON data files:** animals, skills, words, sidekicks editable without code.
- **GUT:** unit tests. **GitHub Actions:** tests + web/desktop exports.

## 5. File/Folder Structure
- `scenes/` — intro, world map (TileMapLayer), habitats, chase, rescue center + enclosures, menus, parent area.
- `scripts/problems/` — Common Core–tagged generators (pure GDScript, testable), incl. preschool set.
- `scripts/adaptive/` — difficulty engine.
- `scripts/progress/` — profiles, sessions, save/load (JSON in `user://`; IndexedDB-backed on web).
- `scripts/sidekick/` — sidekick controller driven by profile data.
- `scripts/tts/` — TTS wrapper (voice, rate, pitch), swappable for recorded audio.
- `data/` — animals.json, skills.json, words.json, sidekicks.json.
- `assets/` — sprites, tilesets, audio, fonts, CREDITS.md.
- `tests/` — GUT tests.

## 6. Multi-AI Workflow (Claude, ChatGPT, Gemini)
- **GitHub repo** is home; this **PLAN.md** is the master plan. Nothing lives only in one AI's chat or memory.
- Shared files: `PLAN.md`, `CONVENTIONS.md` (style, naming, tests, commit format), `PROGRESS.md` (current step, done, next, issues; every assistant updates it at session end), `DECISIONS.md` (dated decisions and why).
- Pointer files: `CLAUDE.md` (Claude Code), `AGENTS.md` (ChatGPT/Codex), `GEMINI.md` (Gemini). Each says: read the shared files first, run tests, work on a branch, commit small, update PROGRESS.md before finishing, never change a confirmed decision without Chris's approval, no secrets in the repo.

## 7. Build Steps (one at a time; run, commit, check off, confirm before the next)

### Approved review follow-up — 2026-10-23
Chris authorized the review suggestions together on a new branch for Claude to review and merge. This brings minimal saving/session completion forward; the remaining Phase 5 features stay planned.
- [x] Cancel stale chase transitions; allow leaving unfinished chases.
- [x] Support keyboard navigation through chase and care.
- [x] Add one local profile with autosave, recovery, and session mastery completion.
- [x] Prepare a separately saved, versioned full-loop playtest with suitable starting math.
- [x] Clarify food prompts and add harder care-note distractors for older readers; keep voice off.
- [x] Run regression tests and visual checks; leave a review handoff for Claude without merging.

### Phase 0 — Setup
- [x] Create GitHub repo; add PLAN.md, CONVENTIONS.md, PROGRESS.md, DECISIONS.md, CLAUDE.md, AGENTS.md, GEMINI.md, .gitignore, .env.example.
- [x] Init Godot 4 project, folders, GUT, CI.

### Phase 1 — Math Core (no graphics)
- [x] Problem generators for the five skill areas with Common Core tags + tests.
- [x] Adaptive difficulty engine + tests.
- [x] Simple debug screen to answer generated problems.

### Phase 2 — Map & Chase Prototype
- [x] Meadow tilemap with free 2D tiles; ranger walking + camera.
- [x] Wandering animal that starts a chase when approached.
- [x] Chase screen: answer buttons, speed-up, net capture.
- [x] Explore and Race modes; Henrito hints after 2 misses (TTS).

### Playtest 1 (added 2026-10-21, Chris's request)
- [x] Playtest setup: desktop shortcut (`--playtest`), add/subtract to 12 for every chase, 6 raccoons that come back, local answer log + `tools/summarize_playtest.py`, checklist `docs/playtest_1.md`.
- [ ] Run the playtest with the 7-year-old; review notes + log summary. (First session froze → fixed in playtest-1.2; voice off in 1.3. Chris moved on to Phase 3 on 2026-10-21; review whenever more sessions happen.)

### Phase 3 — Story & Rescue Center
- [x] Storm intro panels with narration. (Captions instead of spoken narration while the voice is off.)
- [x] Rescue Center hub with enclosures and fence repair.
- [x] Feeding via spelling, care notes, fact cards with read-aloud. (Read-aloud button appears when the voice is on; it's off for now.)
- [x] Stars, animal levels, collection book. (Small pen shop with 4 decorations; animal accessories later.)

### Phase 4 — Full Map
- [x] Forest, Swamp, Desert, Mountains; habitat unlocking; all animal data. (Forest and Swamp 2026-11-04; Desert, Mountains, unlocking 2026-11-05. Unlocking: each habitat's hidden snake opens the next.)
- [x] Special rarity tier: hidden snakes for the other habitats (all five done 2026-11-05); ~~helper animal bonuses~~ (dropped); finale (2026-11-05).

### Phase 5 — Profiles, Sessions & Parent Area
- [x] Two profiles with per-profile sidekick, ranger customization, save/load. (2026-11-05: two big title buttons; name typed once; hair/skin/outfit swatches; second profile = Loganator, grade K, Explore locked.)
- [ ] 10–15 minute session timer with wrap-up.
- [ ] Parent lock, Common Core progress report, settings.

### Playthrough fixes (added 2026-11-05, from `docs/playthrough_review_2026-11-05.md`)
A robot played the whole game start to finish; these fix what it found. Chris chose gameplay fixes first, then looks. Do these before the rest of Phase 5. Steps 1–5 change logic/data; steps 6–10 change what screens look like and wait for Chris's merge.
- [ ] **1. Care for any animal in a pen.** When a pen has more than one kind of animal, the kid picks which one (one button per kind, with its face). Today only the first kind can ever be cared for, so 8 of 15 species stay Level 1 and their facts never unlock.
- [ ] **2. Starting level by grade, quicker level-ups.** The profile's grade picks each skill's starting level (table in `data/adaptive.json`; K = level 1 everywhere). Level up after 5 of the last 6 right and fast (was 8 of 10). Only new saves and skills he hasn't practiced yet use the grade start; his progress is kept.
- [ ] **3. Hints before only one answer is left.** On 3-button problems the hint shows after 1 miss (2 misses on 4-button problems). Add a hint picture for "7 + 2"-style problems so the middle of the chase screen isn't empty.
- [ ] **4. Snake stories for every skill.** Each habitat's snake asks a story in that habitat's skill (counting, add/subtract, place value, time/money, groups/sharing), a few templates each. Stories start at 2 or more ("saw 1 beetle" reads oddly). The Meadow snake stays at K level.
- [ ] **5. Runaways come back.** After all of a habitat's animals are home, a few rescued animals slip out again after a while. Catching one gives stars and practice but isn't a new rescue (Book, fence, and finale counts don't change). Fence repair spreads across all of a pen's rescues instead of finishing at 4.
- [ ] **6. Fox and rabbit in the Meadow.** Find (free, CC0, ask Chris before downloading) or make fox and rabbit art; add them to the Meadow map and data so the Book's two "???" slots can be filled.
- [ ] **7. HUD and hub layout.** Banner below the HUD buttons; repair messages one at a time; pen labels clear of the HUD; Care and Decorate buttons apart; gate signs on screen; widen the walk to the Mountains gate; decorations off the fence line; finale uses the ranger's name.
- [ ] **8. Habitats look different.** A ground look per habitat: swamp mud and reeds, desert sand and cacti, mountain rock and snow (from the Ninja Adventure pack where possible).
- [ ] **9. Clearer animal art.** Gray raccoon with a black mask, snow leopard, bear, five snake faces that look different, and a default ranger that doesn't look like Henrito.
- [ ] **10. More to buy.** More decorations, some unlocked as a pen's animals level up, so stars keep their value. Then re-run the robot playthrough and compare with the 2026-11-05 review.

### Phase 6 — Verify & Polish
- [ ] Full test pass; code review for bugs and edge cases.
- [ ] Accessibility options, audio, web performance.
- [ ] Playtest with the 7-year-old; tune difficulty.

### Phase 7 — Finish (personal release)
- [ ] README (what it is, setup, how to run/build).
- [ ] Confirm no secrets in code.
- [ ] Web build on simple static hosting (e.g., Render static site) + Windows/macOS builds.

### Phase 8 — Preschool Level
- [ ] Preschool generators, picture-only care, slow no-timer chases, Loganator profile.

## 8. MVP Definition of Done
- Storm intro plus Meadow and Forest playable end to end: explore, chase, capture, enclosures, care, fact cards with read-aloud.
- Henrito gives calm, encouraging hints; adaptive difficulty working and tested.
- Older son's profile saves locally; session wrap-up; basic parent report.
- Runs smoothly in a desktop browser and as a desktop build.
- Shared multi-AI files in place; PROGRESS.md current.

## 9. Risks & Open Questions
- **Scope:** still a big game for a personal project. Ship the MVP (Meadow + Forest) before anything else.
- **Web TTS:** Godot's web TTS relies on the browser's speech voices, which vary by browser; test early in Phase 2.
- **Free art consistency:** mixing packs can look messy; pick one pack family up front.
- **Multi-AI drift:** different assistants may change style or decisions; CONVENTIONS.md, DECISIONS.md, and tests keep them in line.
- **Design doc out of date:** the Google Doc still says 3D; update or mark it superseded.
- Open: tablet builds; custom art and recorded voices; cloud saves; Spanish.
