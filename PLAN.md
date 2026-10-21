# PLAN.md — Catch That Critter

> Handoff plan for AI coding assistants (Claude Code, ChatGPT/Codex, Gemini). Design reference: Google Doc "Kids Math Game – Design Doc (Pet Shelter Chase)" (note: the doc still describes 3D; this plan supersedes it).
> Workflow (Chris's new-coding-project process): approve plan → set up git → build one small, tested step at a time with a commit per step → verify with tests and review → README, secrets in env vars, deployment.
> **Status:** Approved by Chris on 2026-10-20. Building Phase 0.

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
- Read-aloud: **text-to-speech** first.
- Saves: **local on device only**.

## 3. Design Details

### 3.1 Story
- Short intro (a few illustrated panels with TTS narration): thunderstorm, fences fall, animals scatter.
- The sidekick brother greets the ranger and explains the mission: bring every animal home.
- Each capture repairs a section of fence at the Rescue Center.
- Finale when all animals are home: clear sky and a celebration.

### 3.2 Profiles
- Two profiles now (allow up to 4).
- Each stores: name, ranger look, starting level (Preschool, K–3), sidekick (name, sprite, voice settings), progress.
- Sidekick is data-driven per profile, so Henrito and Loganator share one hint system.

### 3.3 Sidekick Behavior
- Every line calm, warm, encouraging; never says "wrong." E.g., "Nice try, let's count together." "You've got this."
- Appears for hints after 2 misses, at session start/end, and to celebrate captures. Shows as a small portrait in a speech bubble.
- One-sentence lines.

### 3.4 Map & Habitats (Common Core aligned)
One scrolling top-down tilemap; Rescue Center in the middle; habitats around it.

| Habitat | Skill focus | Grade | Example standards | Animals |
|---|---|---|---|---|
| Meadow | Counting, number recognition, comparing to 20 | K | K.CC | Fox, raccoon, rabbit |
| Forest | Add & subtract within 20, then 100 | 1–2 | 1.OA, 2.OA, 2.NBT.5 | Deer, bear, owl |
| Swamp | Place value, comparing (<, >, =) | 2 | 1.NBT, 2.NBT.1–4 | Turtle, frog, alligator |
| Desert | Telling time, counting money | 2–3 | 1.MD.3, 2.MD.7–8, 3.MD.1 | Lizard, tortoise, snake |
| Mountains | Multiplication & intro division | 3 | 3.OA | Mountain goat, snow leopard, eagle |

- Every problem type in `skills.json` has a `standards` field for the parent report.
- Habitats unlock as skills are mastered; for the 7-year-old, Meadow and Forest start unlocked.
- Rarity tiers: common / uncommon / rare / **special** (special = rare spawn, unique fact card, special enclosure decoration; species placeholders until Chris picks).
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
- Helper animals: well-cared-for animals give chase bonuses (e.g., owl shows the runaway's path).

### 3.10 Rewards & Progression
- Stars from chases and care; spend on enclosure decorations and animal accessories.
- Fence repair after the storm.
- Animal levels 1–5 through care.
- Collection book with special slots for special animals. No leaderboards.

### 3.11 Adaptive Difficulty
- Per-skill accuracy and response time.
- Rolling last 10 problems: ≥ 80% correct and fast → step up; < 50% → step down, more hints.
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

### Phase 0 — Setup
- [x] Create GitHub repo; add PLAN.md, CONVENTIONS.md, PROGRESS.md, DECISIONS.md, CLAUDE.md, AGENTS.md, GEMINI.md, .gitignore, .env.example.
- [x] Init Godot 4 project, folders, GUT, CI.

### Phase 1 — Math Core (no graphics)
- [x] Problem generators for the five skill areas with Common Core tags + tests.
- [x] Adaptive difficulty engine + tests.
- [x] Simple debug screen to answer generated problems.

### Phase 2 — Map & Chase Prototype
- [x] Meadow tilemap with free 2D tiles; ranger walking + camera.
- [ ] Wandering animal that starts a chase when approached.
- [ ] Chase screen: answer buttons, speed-up, net capture.
- [ ] Explore and Race modes; Henrito hints after 2 misses (TTS).

### Phase 3 — Story & Rescue Center
- [ ] Storm intro panels with narration.
- [ ] Rescue Center hub with enclosures and fence repair.
- [ ] Feeding via spelling, care notes, fact cards with read-aloud.
- [ ] Stars, animal levels, collection book.

### Phase 4 — Full Map
- [ ] Forest, Swamp, Desert, Mountains; habitat unlocking; all animal data.
- [ ] Special rarity tier (placeholders); helper animal bonuses; finale.

### Phase 5 — Profiles, Sessions & Parent Area
- [ ] Two profiles with per-profile sidekick, ranger customization, save/load.
- [ ] 10–15 minute session timer with wrap-up.
- [ ] Parent lock, Common Core progress report, settings.

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
- Open: special rare animal species; tablet builds; custom art and recorded voices; cloud saves; Spanish.
