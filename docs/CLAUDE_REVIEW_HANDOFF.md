# Claude review handoff — 2026-10-23

Chris authorized implementation of the review suggestions on a new branch for Claude to review and merge. Branch: `codex/review-fixes`. Main and the frozen playtest checkout have not been changed. Do not treat this as an automatic merge approval without reviewing the changes and CI.

Local checkout: `C:\Users\raine\OneDrive\Documents\ChatGPT\CatchACritter\review-fixes` (a Git worktree of `C:\Users\raine\CatchACritter`). The original checkout retains the previously written review notes. Use this worktree to inspect the implementation, or fetch the branch elsewhere.

## Changes to review

1. Chase delay and movement tweens are owned by the screen and cancelled on restart, escape, catch, and exit. Finish is idempotent. Later/Esc leaves an unfinished chase without a rescue and resumes the world.
2. Chase/care buttons have visible keyboard focus and explicit navigation loops. Focus moves away from disabled or removed controls. Enter/Space activate; Tab/Shift+Tab and arrows navigate. M changes world mode; F10 ends a session in the hub.
3. `ProfileStore` writes a verified temporary JSON snapshot before rotating the last good save to `.bak`. It validates nested fields, recovers a valid backup, preserves damaged files, and rejects newer schema versions without replacing them. Save errors are visible and prevent an orderly quit from silently discarding unsaved progress. An unreadable profile blocks starting, but the window can still close.
4. Normal play has one local profile. Autosaves include rescues, care visits/facts, fence repair presentation, settings, adaptive progress, and pending session results. Resume enters the hub after the intro has been seen. Save & rest or closing the window finishes mastery exactly once; empty sessions earn no credit. Script-mode tests and `--no-save` helpers do not access the player's profile.
5. `--playtest-full` / `tools/playtest_2_launch.cmd` runs the current full loop with a separate profile and mixed addition/subtraction within 20 initially. Existing Playtest 1 configuration, shortcut, and frozen checkout are preserved.
6. Food descriptions and a reveal/hide word clue remove dependence on recognizing small sprites. Clue use is logged. Grades 2–3 get plausible care-note distractors; K/grade 1 retain the original choices. No new art or recorded speech was added; voice remains off.

## Verification

- Baseline: all 213 GUT tests passed on Godot 4.7.2.
- Updated suite: 235 tests passed, 67,064 assertions. New coverage includes live keyboard events through a full care visit, chase selection/exit, immediate retries, cancelled callbacks, disk recovery, malformed and future saves, isolated profiles, session mastery across reloads, and continued play after a failed session save.
- Separate headless processes: wrote rescue/care/answers, simulated orderly window close, then reopened and verified the saved rescue, care count, intro, and one mastery-session credit (`PROCESS_REOPEN_PASS`). Disposable profile stayed inside `.tmp_shots/`.
- Real OpenGL rendering: inspected the hub, care, word clue, note, fact, race, escape/retry, and resume screens. Fixed clipped mode text and the focused letter's contrast. Local screenshots/helper scripts are in ignored `.tmp_shots/`; they are not production code.
- Existing GUT `wait_frames` deprecation notices are not failures. No browser/macOS export or child playtest was performed.

Run the normal GUT command from this checkout. Run Playtest 2 using [the checklist](playtest_2.md). Helpers should always use `-- --no-save` unless deliberately exercising an explicit disposable profile.

## Review boundaries and remaining work

This is minimal saving, not all of Phase 5: no profile picker/customization, parent area, timed session wrap-up, or user-facing reset screen. Rescues and care are only completed when their activity finishes; leaving an unfinished task does not award it. Saved progression resumes at the hub rather than restoring exact world coordinates or an in-progress question.

The normal Meadow keeps its counting curriculum; the new playtest provides the age-appropriate math override while Forest is still unbuilt. Six rescues exhaust the current Meadow, but care can continue. Observe the actual child's reading and difficulty before tuning further.

Please review save/recovery behavior, session boundaries, keyboard focus, and the chosen starting playtest level before merging. Then continue the remaining roadmap with Chris.
