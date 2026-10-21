# DECISIONS.md — Catch That Critter

Dated log of decisions and why. Confirmed decisions (PLAN.md section 2) change only with Chris's approval.

## 2026-10-20 — Plan approved
Chris approved PLAN.md. It supersedes the Google Doc "Catch That Critter – Design Doc", which described a 3D game.

## 2026-10-20 — 2D top-down instead of 3D
Keeps scope manageable for a personal project; free 2D asset packs are plentiful.

## 2026-10-20 — Godot 4 + GDScript
Free, small web exports, built-in tilemaps, camera and text-to-speech; easy desktop + web builds. GDScript is simple and readable by any AI assistant.

## 2026-10-20 — Multi-AI workflow
The GitHub repo is the single source of truth so Claude, ChatGPT, and Gemini can all pick up the work. Shared files: PLAN, CONVENTIONS, PROGRESS, DECISIONS; pointer files: CLAUDE.md, AGENTS.md, GEMINI.md.

## 2026-10-20 — Pinned Godot 4.7.2 and GUT 9.7.1
Godot 4.7.2 was the latest stable 4.x at setup. GUT 9.7.1 is the GUT release made for Godot 4.7. Compatibility renderer so the same project runs well on the web.

## 2026-10-21 — Adaptive engine details (clarifies PLAN.md 3.11)
- Mastery credit flows down: a good session (≥ 80%, ≥ 5 answers) at level N counts toward levels 1..N. Without this, the level-up rule (8 of last 10, fast) moves a strong player on before any level could collect 3 good sessions.
- A poor session at level N resets the streak for N and harder levels; easier levels keep their streak.
- Level down can trigger after 6 answers (not a full 10) so a struggling kid gets relief sooner; it also turns on "extra help" (hint after 1 miss instead of 2) until they're back to ≥ 50%.
- Only the first try at each problem counts. "Fast" = average seconds of correct answers; default 8s, clocks/coins 12s, multiply/divide 10s.
- All numbers live in `data/adaptive.json` for tuning after playtests.

## 2026-10-20 — Local saves only, TTS first, free art first
No accounts or cloud; privacy for kids. Text-to-speech before recorded voices; free asset packs before custom art.
