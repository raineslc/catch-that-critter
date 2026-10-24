# Codex review for Claude - 2026-10-23

Update: Chris subsequently authorized implementation on a new branch for Claude to review and merge. See [implementation handoff](CLAUDE_REVIEW_HANDOFF.md). The original review below records the earlier read-only assessment and its limitations.

## Scope and authorization

Chris requested a review of the work completed so far, with suggestions only and no implementation changes. He then asked: "Leave these notes for Claude in the documents".

This document records that review. These are recommendations, not approved implementation tasks or changes to confirmed decisions. No game code, configuration, tests, or roadmap checklist items were changed. Discuss any proposed reprioritization with Chris before changing the plan.

## Project located

- Active project: `C:\Users\raine\CatchACritter`.
- Repository: https://github.com/raineslc/catch-that-critter (private).
- Local history reviewed through `5e1f2de`, the handoff update after care PR #16.
- `C:\Users\raine\CatchACritter-playtest` is the intentionally frozen older playtest copy; do not develop there.
- The Codex chat's attached folder, `C:\Users\raine\OneDrive\Documents\ChatGPT\CatchACritter`, contained only an empty Git repository, not the active project.

## Overall assessment

The prototype has a solid foundation. Math generators and adaptive rules are separated from presentation, content and tuning live in data files, and the project has useful tests and handoff documentation. The implemented loop includes exploration, chases, the storm intro, Rescue Center fence repairs, and feeding/care/fact cards. Keep the current architecture.

There are 213 test functions in the local test suite. GitHub reports success for the care merge's test run:
https://github.com/raineslc/catch-that-critter/actions/runs/39701592864

Verification limits: this review used source code, tests, local history, existing CI results, and Claude's existing care screenshots. Codex did not run a fresh local test suite or interactive gameplay session. Timing issues below are source-derived findings to reproduce, not claims of observed runtime failures.

## 1. Fix chase restart timing (priority: high)

Evidence: `scripts/chase/chase_screen.gd`, especially `answer()` around line 198, `retry()` around line 234, and `_begin_escape()` around line 279.

The escape animation runs for 0.8 seconds, while the retry button becomes available immediately. `retry()` resets the animal's position but does not cancel the old escape tween, which can continue moving the animal after restart.

A separate delayed callback can also survive into a new attempt: a correct answer schedules `next_problem()` after 0.9 seconds. If the race expires during that delay and the child retries promptly, the old callback can replace the new attempt's question and reset its timing.

Suggested change: cancel pending transition timers and tweens when an attempt ends or restarts, or guard callbacks with an attempt identifier. Treat restart as a clean transition.

Suggested verification: with automatic advancement enabled, answer correctly just before a non-sprint timeout, retry immediately, and confirm the question remains stable and the animal stays on the new chase path. Also retry during the escape animation itself. Existing retry tests check immediate state but do not cover the subsequent old animation/callback effects.

## 2. Allow leaving an unfinished chase (priority: high usability)

Evidence: `scripts/chase/chase_screen.gd`, `_begin_escape()` around line 278 and the screen construction.

Explore mode has no timeout, and Back to the map is only offered after a Race escape. A child who is stuck or wants to do something else must finish the chase or close the game.

Suggested change: provide an always-available Back or Later control, with no penalty. Resume the world without recording a rescue. Verify exit during a question, hint, and transition delay, including cleanup of pending callbacks.

## 3. Complete keyboard support (priority: medium)

Evidence: `scripts/chase/chase_screen.gd:353` (`_big_button`) and `scripts/care/care_screen.gd:515` (`_button`) set `focus_mode = Control.FOCUS_NONE`. The hub supports Enter/Space to open care, but the care screen has no equivalent keyboard interaction for its buttons.

Movement supports the keyboard, yet completing chases and care requires a mouse.

Suggested change: add visible keyboard focus, Tab/arrow navigation, and Enter/Space activation. Verify a complete rescue-and-care visit using only the keyboard, including Next, Done, and Later.

## 4. Prioritize basic local saving and session completion before more rewards

Evidence: `scripts/game/game_state.gd` explicitly resets session state; `AdaptiveEngine.end_session()` is called by the debug screen but is not wired into normal gameplay session completion.

Rescues, care visits, and learning progress disappear when the game closes. These are documented Phase 5 gaps, not regressions or unexpectedly missing completed features.

Recommendation for Chris to consider: move one local profile with reliable saving ahead of stars, animal levels, and collection rewards. Integrate session completion with mastery evaluation and persistence. Verify close/reopen, rescue persistence, care facts, and mastery across sessions before expanding reward systems. This is a proposed roadmap change, not an approved change.

## 5. Make the next child playtest cover the current complete loop

Evidence: `data/animals.json` assigns the current raccoon to counting. Only the Meadow is available in normal gameplay. `docs/playtest_1.md` and `docs/HANDOFF.md` explain that the existing desktop shortcut runs the older playtest version with addition/subtraction overrides and without the new hub/care work.

Recommendation: prepare an explicitly versioned playtest combining the current explore -> rescue -> hub -> care loop with math suitable for the seven-year-old. The existing shortcut does not demonstrate the latest work. Keep the frozen playtest copy intact until Chris authorizes an update.

Observe whether the child can play independently for 10-15 minutes, find the return gate, discover care, understand hints, and handle a Race escape without adult intervention.

## 6. Clarify spelling prompts and tune reading difficulty

Evidence: `scripts/care/care_screen.gd` and `data/care.json`; reviewed existing screenshots including `care_spell_start.png`, `care_facts_full.png`, and `care_hub_button.png` generated by Claude's `.tmp_shots/care_shots.gd` helper.

The care screens have large, readable controls. However, Spell the food relies on recognizing pixel-art fish/shrimp while speech is disabled. In particular, the shrimp image may test picture interpretation instead of spelling.

Recommendation: validate that the child recognizes each food without help, consider clearer artwork, and consider a short recorded word prompt when revisiting audio. Preserve Chris's current voice-off decision unless he approves a change. Increase care-note difficulty gradually with less obviously silly distractors when appropriate.

## Recommended sequence for discussion

1. Resolve chase restart timing and add a safe way out of chases.
2. Complete keyboard navigation.
3. Consider moving minimal local saving/session completion forward.
4. Playtest the complete current loop at the intended math level.
5. Resume rewards and additional habitats using that feedback.

No implementation was performed as part of this review or documentation handoff.
