# Full playthrough review — 2026-11-05

Input for the next improvement plan. Not committed yet; nothing in the game was changed.

## How this was tested
- A robot player (throwaway scene `.tmp_shots/playthrough.gd`, git-ignored) played the **real game in a real window**: title → new ranger setup → storm intro → hub → Meadow → Forest → Swamp → Desert → Mountains (all animals + each hidden snake) → care, shop, and Rescue Book after each habitat → finale → Save & rest → reload.
- It used its own save (`user://profiles/bot_playthrough.json`); the boys' saves were not touched.
- It played like a kid who gets **~80% right**, takes 1.5–4 s per answer, 4–8 s on snake stories, ~90% on spelling.
- 113 screenshots in `.tmp_shots/playthrough/` (numbers below like `#025` refer to them), plus `events.jsonl` (every problem, answer, care step) and `summary.json` (frame times, memory).
- All 317 GUT tests passed before the run. No errors or warnings in Godot's console during the run.
- Not checked: the Loganator/K profile, Race mode, the web build, sound, read-aloud (voice is off), keyboard-only play, small screens.

## Top 10 to fix (my ranking)
1. **Care only ever reaches the first animal in each pen.** Deer, bear, frog, alligator, lizard, tortoise, mountain goat, and eagle can never be cared for, so they stay Level 1 and their facts never unlock (Book shows "Deer Level 1", "Bear Level 1"). Cause: `care_animal_near()` returns the pen's first resident.
2. **The game only uses the easiest 1–2 levels of each skill.** Every skill starts at level 1 for everyone, a level-up needs 10 answers, and each habitat has only ~21 problems in total. A 2nd grader spent the Meadow counting **1–3 raccoons** (`#016`), and never saw add/subtract within 100, coins (once), or division.
3. **The game runs out.** Animals never come back in normal play. After about 40 rescues (~22 min for the bot; maybe 45–70 min for a real 7-year-old) there are no more chases. That means no more math practice and nothing to spend stars on.
4. **Two Meadow Book slots can never be filled.** `data/rewards.json` lists fox and rabbit for the Meadow, but neither animal exists (the Meadow only has 6 raccoons). The page shows "???" forever (`#037`).
5. **Hints come too late to help.** The hint shows after 2 misses on a problem, but most early levels have 3 choices, so by then only the right answer is left. Only 1 hint showed in 35 chases.
6. **Banners and labels draw on top of the buttons.** The center banner sits behind/over "Book (B)" and the star counter (`#013`, `#019`, `#023`). Two hub repair messages run together and off both edges: "You fixed 4 fences! Meadow pen: 4 of 4 You fixed 2 fence…" (`#025`). Pen labels hide behind Save/Book/star buttons (`#111`).
7. **Every snake asks the same kind of add/subtract story,** even in the Swamp (place value), Desert (time/money), and Mountains (multiply). 4 of 6 snake problems used the same "Then some more came. Now there are N." template. This was a known shortcut in `open_snake()`.
8. **Habitats look almost the same.** The Swamp, Mountains, and Meadow are the same green grass with a few ponds/trees (`#058`, `#100`). There is no mud, reeds, snow, or cliffs, so a kid can't tell where they are from the screen.
9. **Some animal art doesn't match the animal.** The raccoon is red/orange, but its fact card says "black fur around their eyes" (`#037`). The snow leopard looks like a white dog or weasel. The bear is a red blob. Four of the five snake portraits look nearly alike (`#110`).
10. **You and Henrito look alike.** The default ranger has red hair with a headband, and Henrito is also red-haired. In the hub it's hard to tell which one is you (`#011`).

## Optimization / performance
Short version: **no performance problems on this PC.**
- 60 fps in every scene. Over ~95,000 frames, only 18 took longer than 33 ms, and the worst was 135 ms at startup on the title screen. Chases, care, shop, and Book all held a steady 16.7 ms.
- Walking through a gate to a new map took 22–85 ms.
- Memory went from 54 MB to 65 MB over the whole game, and no leaked (orphan) nodes.
- GPU: RTX 3060 laptop with the Compatibility renderer. A low-end laptop or the **web build** is untested and is the real risk.
- Worth watching for the web build:
  - Every first-try answer saves the profile, and each save does ~4 file operations (read old, write temp, read temp, rename). That's fine on desktop; in a browser it hits IndexedDB each time. Consider saving at the end of each chase or care visit instead.
  - The storm intro builds its rain and the ranger recolor pixel by pixel when the scene loads. That's cheap now, but it would be the first suspect if web loads stutter.
  - The JSON data files are re-read on each chase/care start. They're tiny, so this is not a problem.

## Difficulty
What the robot saw (80% correct):

| Habitat | Problems | Levels reached | Example |
|---|---|---|---|
| Meadow (counting) | 18 | 1–2 | "How many critters?" → 1 (choices 1, 2, 3) |
| Forest (add/sub) | 21 | 1–3 | "7 + 2", "3 − 1" |
| Swamp (place value) | 24 | 1–2 | "How many ones are in 88?" (`#059`) |
| Desert (time/money) | 21 | 1–3 | 8:00 on the clock (`#081`); one coins problem |
| Mountains (× ÷) | 24 | 1–3 | "5 groups of 2", "3 × 3" |

- **Too easy at the start for a 2nd grader.** The profile's grade (2) isn't used to choose a starting level. Meadow counting is a kindergarten skill.
- **Mountains is grade 3,** but it starts so easy that a 2nd grader is fine. That's good, as long as it keeps adapting.
- **Escapes are rare.** 1 escape in 35 chases at 80% accuracy. That's gentle, which is probably right for him. Race mode wasn't tested.
- **Snakes.** The first snake (Meadow, a kindergarten habitat) asked a 2nd-grade story ("10 crickets, 7 went away"); the robot missed twice and needed 10 rock peeks (`#020`, `#021`). The later snakes were found in 2–3 peeks, often on the first rock tried. The direction clue (`#023`) works well.
- **Care is easy for grade 2.** The note question is always one obvious choice out of two ("A warm bath" or "A drink of water", `#027`). Spelling short words like *fish*, *corn*, *mice*, *bugs* with one extra letter is fine.
- **Levels stopped by the end:** counting 2, add/subtract 3, place value 2, time/money 3, multiply/divide 3. Nothing was mastered (mastery needs 3 sessions).

## Experience / game flow
- **Length:** the robot took 22 minutes for everything: Meadow ~3 min, each later habitat ~2.5–3 min, plus about 1 min per hub visit for care, shop, and Book. A real kid is maybe 2–3× slower, so about **4–5 sessions of 10–15 minutes and then the game is over.**
- **Chase rhythm:** each chase is 3 problems in about 15 s and feels quick. Walking to the next animal took about 2 s, so animals are close and easy to find.
- **No reason to go back:** once a habitat is cleared, it's empty except for its snake (also gone once caught). Nothing pulls him back to the Meadow.
- **Star economy is loose.** By the 2nd habitat the robot could buy all four decorations for that pen right away. It ended with every decoration in 4 pens plus 54 stars left over, with nothing to spend them on.
- **Fence repair:** each pen is fully fixed after 4 rescues (`Meadow pen: 4 of 4`), so rescues 5–8 don't visibly fix anything.
- **The finale shows the moment you arrive** after the last snake, before you can care for the new Mountains animals. It's a single screen and then the game is back to normal. It thanks "Ranger" instead of using his ranger's name (`#110`).
- **Hidden-snake pacing:** the bot needed 2–10 peeks per snake, and a missed story sends the snake to another rock. That's good tension. The "You get one try!" text may stress some kids.
- **Save/reload works:** after Save & rest → title → load, it kept 40 rescues, 54 stars, the name, and intro/finale seen.
- **Sidekick talk:** only two hub lines show at the start ("The gate is on the left!"). He says nothing new after the Meadow, such as which gate to try next.

## UI
- **Banner overlap** (see Top 10 #6). The banner sits at y=100, right where the second row of HUD buttons is.
- **Hub HUD covers the pens at the top of the screen.** Labels like "Forest pen / Owl level 2" sit under "Book (B)", and "Mountains pen … Level 1" sits under the stars (`#111`).
- **The Care and Decorate buttons touch:** "Care for the Snow Leopard" runs into "Decorate" (`#111`).
- **The care button doesn't say which animal** a kid is about to care for until it appears, and it's always the same one (Top 10 #1). Kids can't choose a species.
- **Gate signs sit at the screen edge** and get cut off: "To the Swam…", "(find the Forest …" (`#011`). The Desert sign overlaps its gate fence.
- **The chase screen has a lot of empty space.** "7 + 2", place-value, and multiply problems show no picture until a hint, so the middle third of the screen is blank (`#039`, `#059`). Counting and clocks look good (`#081`).
- **"Later (Esc)" on the chase screen** sits right under the ranger on the track and looks like part of the scene (`#016`).
- **Ranger setup:** the Back/Start buttons are dark-on-dark with weak borders (`#003`). It works, though.
- **Shop:** clear and simple (`#035`). Items you can't afford look about the same as ones you can; check the disabled style.
- **Book:** clean (`#037`). The "???" slots for animals that don't exist hurt it (Top 10 #4). The special slot's gold border works.
- **Snake miss screen** says "The answer was 3. You'll get it next time!" — good, kind, and clear (`#021`).
- **Title:** only one big card plus the logo, with lots of empty green and no art (`#001`). Fine for now; a candidate for polish.

## Graphics
- **Tiles look nice and consistent,** but the grass, trees, and paths are identical in every habitat. Desert and Mountains have a tint that barely shows in screenshots.
- **The 3× camera zoom** makes the hub feel cramped: pens, labels, and HUD fight for space.
- **Animal sprites are tiny on the map** (16×16 at 3×) and some are hard to read (owl, snow leopard, raccoon colors). The chase-screen sprite at 4× helps.
- **Fact cards and care screens** are plain beige with one text box (`#048`). A big picture of the animal would make the fact more memorable.
- **Decorations can sit on the fence line:** the Meadow pen's rock lands on the bottom fence (`#036`).
- **The finale is cheerful** (rainbow, sun, confetti, every face, `#110`). It's a good payoff, but static.

## Smaller notes
- The bot got physically stuck 4 times. 3 of those were walking from the hub to the Mountains gate, around fixed fences and decorations near the top pens. The Mountains gate was the longest walk (17.5 s); a kid using arrow keys might snag on the same corners.
- The finale and the hub care pass compete: the finale pops up over the hub immediately, so the planned care visit for the Mountains pen didn't happen in this run.
- Snake story wording "saw 1 beetle. Then some more came. Now there are 13" reads oddly with 1. Maybe use a minimum start of 2.
- Raccoon food words cycle in a fixed order (by design); fine.

## Suggested themes for the next plan
1. **Care fixes:** pick which animal to care for in a pen (or cycle through residents), so all 15 species can level up and unlock facts.
2. **Difficulty:** use the profile's grade to choose each skill's starting level; consider fewer answers to level up (e.g. 6) or let the snake story drive a level check; add hint pictures before the last choice is left (hint after 1 miss on 3-choice problems).
3. **Replay / practice loop:** bring a few animals back after a while (like the playtests), or add "visitors"/daily critters, so math practice keeps going after the finale. This ties into Phase 5's session timer.
4. **Snake stories per skill:** place-value, time/money, and multiply stories for the later snakes; more templates.
5. **Book/data fixes:** remove fox and rabbit from the Meadow page, or add those animals to the Meadow map.
6. **HUD layout pass:** move the banner below the HUD, queue or shorten the repair messages, keep pen labels clear of the HUD, separate the Care and Decorate buttons, and keep gate signs on screen.
7. **Habitat identity:** a ground tile set or strong tint per habitat (swamp mud and reeds, desert sand and cacti, mountain rock and snow).
8. **Art pass on unclear animals:** raccoon (gray with black mask), snow leopard, bear, distinct snake portraits; a ranger default that doesn't match Henrito.
9. **Star sinks:** more decorations, or ones that unlock per habitat level.
10. **Web performance check** when the export presets are set up (Phase 7): save frequency, load times.
