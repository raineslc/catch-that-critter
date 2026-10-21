# HANDOFF — Catch That Critter (as of 2026-10-21)

Read this first in a new session, then `CLAUDE.md` → `PLAN.md` → `CONVENTIONS.md` → `PROGRESS.md` → `DECISIONS.md`, then run the tests.

## Where things stand
- **Repo:** `C:\Users\raine\CatchACritter`, GitHub `raineslc/catch-that-critter` (private). `main` has everything merged (last: PR #14, Rescue Center hub). **180 GUT tests pass** locally and in CI. Branch `phase3/care` (not merged yet) adds Phase 3 step 3 — 213 tests pass.
- **Done:** Phase 0 (setup), Phase 1 (math core), Phase 2 (Meadow + chase prototype), Playtest 1 setup, Phase 3 steps 1–2 (storm intro, Rescue Center hub).
- **Phase 3, step 3 (care) built** on `phase3/care`: walk to a pen with animals → "Care for the Raccoon" → spell the food (fish/shrimp) → care note → fact card (one new fact per visit). Waiting on Chris to push/PR/merge.
- **Next step: Phase 3, step 4** — stars, animal levels 1–5 through care, collection book.
- **Game flow today:** title → storm intro (7 captioned panels) → Rescue Center hub (Henrito in the plaza, 5 pens with storm-broken fences, 5 gates; only the Meadow gate is open) → Meadow (6 raccoons) → walk close → chase (3 right answers = net toss = rescue) → back at the hub each rescue fixes one fence section of that habitat's pen and the animal lives in the pen → walk up to the pen to care for it (feed by spelling, care note, fact card).

## How Chris works (follow this)
- Chris builds this for his sons: 7-year-old (main player, ~2nd grade) and 3-year-old (preschool level later). Sidekick: **Henrito** for the older son's profile, **Loganator** for the younger's.
- **One PLAN.md checklist step at a time**, on a feature branch: build → run → fix → commit (clear message, **no AI attribution lines**) → PR → CI green → merge → check off PLAN.md → update PROGRESS.md → **confirm with Chris before the next step**.
- **Ask before** changing a confirmed decision, downloading anything, or anything outward-facing. Log decisions in DECISIONS.md.
- **Verify visually**, not just with tests: render real-window screenshots with a throwaway scene in git-ignored `.tmp_shots/` (bare `godot -s` scripts can't see the `GameState` autoload). This caught many layout bugs.
- Chris's machine has a **GateGuard hook**: before the first command/edit of certain kinds it asks you to state facts (what changes, rollback, his instruction verbatim, no duplicate file). Answer briefly and retry.
- Explain in plain language; be honest about trade-offs; keep kid text short, calm, never "wrong".

## Key decisions so far (details in DECISIONS.md)
- Godot **4.7.2**, GDScript (static typing), GUT **9.7.1**, Compatibility renderer, 1280×720. Data-driven JSON in `data/`.
- Art: **Ninja Adventure pack (CC0)**; every used file listed in `assets/CREDITS.md`. Original zip in Chris's Downloads. Missing species (fox, rabbit, deer, turtle, tortoise, goat, snow leopard, eagle) — build with pack animals now, fill gaps later. Ranger customization will likely be "pick a kid sprite" (pack has no layers) — needs Chris's OK in Phase 5.
- Chase = its own screen (scrolling path, critter ahead, ranger behind). Explore (no timer) / Race (45s, sprint boost +3s for answers ≤5s, "Chase again"). Henrito hints after 2 misses (1 with extra help) with hint pictures.
- **Voice is OFF** (Chris: Windows TTS sounded weird, some lines off). `Speech` code kept, unused. Must solve audio before the preschool level. Open question: which lines were "off" (wording vs pronunciation).
- **Never stop/interrupt TTS** (`tts_stop()` / interrupting `tts_speak`) — it froze/crashed Godot on Windows (Playtest 1 freeze). Test-enforced.
- World = **hub with gates**; new games start at the Rescue Center. Maps are text files `data/maps/<id>.txt` + info `data/maps/<id>.json` + `data/maps/world.json`. Ponds convex; gates are digits on the map edge.
- Adaptive difficulty: last 10 first-try answers per skill; ≥80% and fast → up; <50% (after 6) → down + extra help; mastery = 3 good sessions (credit flows to easier levels).
- Progress resets when the game closes until profiles/saves (Phase 5).

## Playtest
- Desktop shortcut **"Catch That Critter (playtest)"** → `tools/playtest_launch.cmd` in frozen worktree `C:\Users\raine\CatchACritter-playtest` at tag **`playtest-1.3`** (pre-intro/hub version: Meadow only, add/subtract ≤12, raccoons come back, voice off). Don't develop in that folder; to update: tag a new version on `main`, `git -C C:\Users\raine\CatchACritter-playtest checkout --detach <tag>`, run `--import` there.
- Logs: `%APPDATA%\Godot\app_userdata\Catch That Critter\playtest\` (answers, freezes with last steps, Godot verbose log). Summarize: `python tools/summarize_playtest.py`.
- First session (2026-10-21): froze (fixed); son got 7/7 right at ~1.9s on level 1 → consider starting him higher.
- Robot players for regression (git-ignored, in `.tmp_shots/`): `bot2.tscn` walks/clicks 30 chases with a hang watchdog.

## Open items / waiting on Chris
- Which voice lines sounded "off"; listen to the 4 chase sounds; is Race 45s right; species for "special" rare animals.
- Review more playtest sessions when they happen (checklist `docs/playtest_1.md`).
- Tuning: "coins with quarters" level can roll piles without a quarter; starting level for the 7-year-old.
- Export presets/templates (~1.3 GB) not set up — Phase 7.

## Handy commands (Windows; Godot isn't on PATH)
```powershell
$g = (Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Packages" -Filter *Godot* | Get-ChildItem -Recurse -Filter *_console.exe | Select-Object -First 1).FullName
& $g --headless --import
& $g --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```
