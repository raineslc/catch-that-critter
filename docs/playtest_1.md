# Playtest 1 — Chase prototype (Meadow)

**Who:** older son (7). **How long:** 10–15 minutes. **Version:** git tag `playtest-1`.

## Before you start
- Double-click **"Catch That Critter (playtest)"** on the desktop. It opens full-window; close it with the window's X (or Alt+F4).
- Turn the volume up: questions and Henrito's hints are read aloud.
- What's in this version: the Meadow with 6 raccoons (caught ones come back after ~25 seconds). Every chase asks **adding and subtracting with numbers up to 12**. It starts easy (add within 6) and gets harder as he gets answers right quickly.
- Explore mode (no timer) is on at the start. The button in the top-right corner switches to **Race mode** (45-second timer).
- Try not to help unless he's really stuck — Henrito should do the helping.

## Suggested run
1. Let him figure out how to walk (arrows, WASD, or clicking) without explaining. ~1 min.
2. Explore mode: catch 3–4 raccoons.
3. Switch to Race mode: 3–4 chases.
4. Stop at 15 minutes even if he wants more (that's a good sign — note it!).

## Watch for (tick or jot a word)
**Getting around**
- [ ] Figured out moving without help? How long did it take?
- [ ] Found a raccoon on his own? Understood that walking close starts a chase?

**The chase**
- [ ] Understood what the answer buttons are for right away?
- [ ] Read the question himself, or waited for the voice?
- [ ] Noticed the catch meter (3 dots top-right) / the raccoon getting closer?
- [ ] Liked the net toss and "You caught the Raccoon!"?

**Math**
- [ ] Problems felt too easy / about right / too hard? (Note the moments.)
- [ ] Used fingers or counted out loud? Which problems?
- [ ] When he missed: frustrated, or just tried again?

**Henrito's hints**
- [ ] Noticed Henrito? Listened to the hint?
- [ ] Did the hint picture (dots / number line) actually help him get it?

**Race mode**
- [ ] 45 seconds: too short / about right / too long?
- [ ] Got a "Sprint boost!"? Did he notice it?
- [ ] If a raccoon got away: upset, or happy to "Chase again"?

**Sound & voice**
- [ ] Any sound annoying or confusing? (right answer, try again, net, caught)
- [ ] Could he understand the voice? Too slow / too fast?

## Ask him afterward
1. What was the best part?
2. What was boring or annoying?
3. Was anything confusing?
4. What animal should we add next?
5. Would you want to play again tomorrow?

## Notes
_(anything else: quotes, bugs, where he got stuck)_



## After the playtest
Tell Claude "playtest done" and paste your notes. The game saved a log of every answer on this PC; Claude runs `python tools/summarize_playtest.py` to turn it into a report (time played, raccoons caught, right/missed by level, hints, slowest problems), and together we decide what to change before Phase 3.
