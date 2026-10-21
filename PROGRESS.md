# PROGRESS.md — Catch That Critter

Every assistant updates this at the end of a session.

## Current step
Phase 1, step 1 — Problem generators for the five skill areas with Common Core tags + tests.

## Done
- 2026-10-20 — Phase 0, step 1: private GitHub repo raineslc/catch-that-critter created with PLAN.md, CONVENTIONS.md, PROGRESS.md, DECISIONS.md, CLAUDE.md, AGENTS.md, GEMINI.md, .gitignore, .env.example.
- 2026-10-20 — Phase 0, step 2: Godot 4.7.2 project (`project.godot`, placeholder title screen `scenes/main.tscn`), folder skeleton, GUT 9.7.1 in `addons/gut/`, smoke tests (3 passing), GitHub Actions workflow running GUT on pushes to main and PRs.

## Next
- Phase 1, step 1: pure-GDScript problem generators in `scripts/problems/` (counting, add/subtract, place value, time/money, multiplication), each tagged with Common Core codes, seeded RNG, GUT tests.

## Open issues
- Special rare animal species still to be chosen by Chris.
- Export presets (Web, Windows, macOS) not set up yet; they need Godot export templates (~1.3 GB) — do this in Phase 7 or when first needed.
