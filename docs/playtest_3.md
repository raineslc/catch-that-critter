# Playtest 3 — the real game (2026-11-05)

**Start:** double-click `tools/playtest_3_launch.cmd` in this checkout (`C:\Users\raine\Projects\catch-that-critter`).
It is the normal game with the playtest log on: the title's two profile buttons and the **real saves**
(`user://profiles/default.json` for him, `ranger_2.json` for his brother). Each habitat uses its own math.
Caught animals stay home (no respawns), like normal play. Voice is off.

His real save is new, so he starts from the beginning: pick his button, make his ranger, storm intro,
then the Meadow and Forest. The Swamp opens when he catches the Forest's ball python.

## What to watch
1. Title: does he find his button? Is "Make your ranger" easy (a grown-up types the name; he taps hair, skin, outfit)?
2. Does his ranger look like his choice in the game?
3. Meadow (counting) and Forest (add/subtract): chases, the hidden snakes, care in the pens.
4. Catching the ball python: does the "The Swamp is open now!" message make sense? Does he find the Swamp gate (east)?
5. Swamp place value (tens and ones, comparing with < > =, skip counting): too hard, too easy?
6. Does he open the Rescue Book (Book button or B)?
7. Save & rest (F10) at the Rescue Center, or close the window, when done.

## After
Tell Claude "he's done"; it runs `python tools/summarize_playtest.py` (shows the profile, places visited,
each skill's levels, snakes, care visits, stars, and the finale if it happened).
