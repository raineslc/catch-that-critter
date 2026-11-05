# Playtest 2 — Rescue, care, and saved progress

## Playtest 2.1 — the hidden snake (2026-11-04)

Same launcher (`tools/playtest_2_launch.cmd`, from `C:\Users\raine\Projects\catch-that-critter` on the latest `main`) and the same saved progress as before. New since the last session:

- **The hidden green vine snake** is under one of the Meadow's rocks. Walk next to a rock and press **Look under the rock** (or Space/Enter). Empty rocks show a little bug or worm; after 3 empty rocks Henrito says which way to look. Finding it gives **one** story problem: right catches it, a miss sends it under another rock.
- **Three misses in a chase and the animal gets away** ("Chase again" / "Back to the map").
- **Stars** (top right): catches, care visits, level-ups, and the snake. Spend them with **Decorate** at a pen.
- **Rescue Book**: **Book** button or **B** at the Rescue Center.
- Spelling now goes through 12 raccoon foods.
- For this session caught raccoons come back after 25 seconds, so there is always something to chase.

Suggested: let him find the snake on his own first (only hint "Look under the rocks" if he's stuck for a few minutes). Then catch a raccoon, care for it, buy a decoration, and open the book to find the snake's page. Watch whether he reads the story problem all the way through before tapping.

After the session: `python tools/summarize_playtest.py` shows the snake hunt and stars too.


Version: `playtest-2.0-review` on `codex/review-fixes`. Intended player: the seven-year-old. Allow 10–15 minutes. A child playtest is still needed; automated checks do not replace it.

## Launch

From this branch's checkout, double-click `tools/playtest_2_launch.cmd`. Alternatively, run Godot with `--path . -- --playtest-full`.

This runs the current title/story/hub/Meadow/care loop. The old desktop shortcut still runs frozen Playtest 1 and has not been changed.

- A fresh Playtest 2 profile starts with mixed addition/subtraction within 20 (level 3). Difficulty adjusts from there; later levels can reach 100.
- Rescued raccoons stay rescued. There are six available in the current Meadow. Returning to the hub makes fence repairs visible and allows repeated care visits.
- Voice remains off. Food descriptions and an optional Show/Hide word clue help identify spelling pictures.
- Playtest 2 progress saves separately from the normal game. Reopening continues the same profile and learned level; it does not reset to level 3 each time.

## Controls

| Where | Keyboard | Mouse |
|---|---|---|
| Map | Arrows/WASD to move; M toggles Explore/Race | Click to walk; click mode button |
| Beside an occupied pen | Enter/Space opens care | Care button |
| Chase/care | Tab/Shift+Tab or arrows select; Enter/Space activates | Click a choice |
| Chase/care exit | Esc | Later |
| Rescue Center | F10 saves and ends the learning session | Save & rest |

## Suggested session

1. Start or continue. Find the Meadow, catch a raccoon, and return through its east gate.
2. Watch the pen repair. Find the Care button without adult directions.
3. Spell the food, choose what helps in the note, and read the fact. Observe whether the food description is enough, or the word clue is needed.
4. Try a chase with only the keyboard. Try Later/Esc before completing one; the animal should remain available.
5. Try Race, let an animal escape, and immediately choose Chase again. The new question and animal should stay stable.
6. Return to the hub and choose Save & rest. Close and reopen. Confirm rescues, care facts, and math difficulty remain.

Watch for reading difficulty, accidental exits, visibility of keyboard focus, whether the harder care choices make sense, and whether the starting math is too easy or too hard. Ask if the child wants another turn. Stop at the planned time.

## Saves and logs (grown-ups)

Windows data directory: `%APPDATA%\Godot\app_userdata\Catch That Critter\`.

- Normal profile: `profiles/default.json`.
- Playtest 2 profile: `profiles/playtest_2.json`.
- Each profile has a `.bak` recovery copy. An unreadable primary recovered from backup is retained as `.damaged-<timestamp>` on the next save. Unsupported future versions and profiles without a readable backup are preserved; the title displays a message instead of overwriting them.
- Answer/care logs remain in `playtest/`; the launcher also captures Godot logs. `python tools/summarize_playtest.py` summarizes chase results. Raw logs include `word_clue`, `fed`, and `care_end` events.
- For a temporary unsaved demonstration, append `--no-save` after the user-argument separator. Do not delete the normal profile to restart a playtest. Back up the Playtest 2 profile and its `.bak` before deliberately resetting it.

Session mastery is evaluated on Save & rest or an orderly window close. Autosaves retain unfinished session answers after a crash so they can resume; they do not count a crash as a second session. A timed wrap-up, multiple profiles, parent settings, and web export verification remain planned work.
