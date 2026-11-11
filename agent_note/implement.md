# AI coach implementation log

Updated: 2026-11-11

## Current state

Phases 0–1 are complete. Phase 2 code is implemented with upload/crop browser verification; physical-camera acceptance remains pending. Phases 3–7 are not implemented. Historical Phase 0 entries below describe the earlier planning-only state.

## Phase 0 — repository discovery and planning

- Read root and calculator `AGENTS.md` instructions, calculator configuration/entry/README, and dev planner/frontend history behavior.
- Searched application Jac source for camera, photo, vision, coach, calendar, and progress implementations. The inspected source contains fitness planning and nutrition integrations, but no implemented visual coach flow.
- Identified dated-week/history behavior in `MDE449Project-dev/` as a reference for preserving completed workouts.
- Recorded the calculator's strict isolation rules and its local food-model integration. Neither establishes a vision capability for this feature.
- Created `plan.md`, this log, `audit.md`, and `test_result.md` under root `agent_note/`.
- Selected a proposed self-contained `feature-ai-coach/` architecture; that folder has not yet been created.

## Implementation queue

Branch ownership: Phases 0–4 → `codex/photo-coach`; Phases 5–7 → `codex/progress-canvas`. Exactly two feature branches; notes, foundations, and final integration are commits within them. Follow the branch points, contract handoff, and PR gates in `plan.md`.

| Phase | State | Next concrete action |
| --- | --- | --- |
| 1 | Complete | Isolated Jac 0.37.21 app, typed profile, server validation, manual flow verified |
| 2 | Implemented; hardware acceptance pending | Upload/crop/restore/remove/reload verified; permission/capture on real hardware still needs testing |
| 3 | Not started | Evaluate a real image-capable provider and implement schema-validated region suggestions |
| 4 | Not started | Build reviewed exercise catalog, goal rules, and illustrated steps |
| 5 | Not started | Persist plan/session/check-in entities and build calendar/dashboard |
| 6 | Not started | Add feedback-driven future-plan updates without rewriting completed history |
| 7 | Not started | Run full functional, visual, model, accessibility, isolation, and privacy acceptance checks |

## Rules for subsequent entries

Record the owning branch, base branch/PR, and tested commit with each phase entry.

Append a dated entry for each phase containing: files changed, behavior delivered, actual commands and working directories, test evidence, model/provider used if any, unresolved defects, and next actions. Mark a phase complete only when its gate in `plan.md` is met. Keep illustrative designs separate from implemented behavior. Never label manual or mocked recognition as verified AI.

## Branch planning update — 2026-11-11

Simplified the original branch proposal to two feature branches at the user's request. Photo coach includes planning/shared foundations; canvas includes final integration. Default workflow is sequential, with one feature PR per branch. Added maintainability rules for shared records, catalogs, vision/storage adapters, reusable media handling, and small backward-compatible changes. `dev` remains the proposed integration target, pending confirmation before the first push/PR. No branches were created/switched, no commits or pushes occurred, and existing staging was untouched. Transfer these working-tree notes to `codex/photo-coach` before committing.

## Proposed first runnable slice

Manual body-region confirmation → goal selection → validated plan preview → illustrated exercise cards → dated check-in calendar. Camera and actual model inference join this slice only after their own validation gates. This sequencing keeps development useful while the vision integration is evaluated, without disguising a fallback as AI.

## Phases 1–2 — 2026-11-11

- Branch: `codex/photo-coach`; base: `dev` at `2b13b0d2bad5f80df4525e8629b6d96d8bd1bf95`. Notes first committed as `4fca642`. Implementation is recorded in the subsequent feature commit; no remote push/PR.
- Worktree: `/Users/zeta/.codex/worktrees/photo-coach/MDE449Project`; app: `feature-ai-coach/`.
- Added typed `CoachProfile`/`ProfileResult`, server validation, manual goal/region selection and schedule preferences. Confirmation validates but does not persist or generate a workout.
- Added `PhotoResult` and a single ephemeral normalization service. No media database or identity claims: there are no saved assets, listing or retrieval endpoints. Future persistent media needs ownership/authentication first.
- Added file picker and camera controls, preview/crop/restore/remove, stream cleanup, stale-response cancellation guards and manual fallback. No object URLs are created. Original and cropped previews contain only server-normalized pixels; originals are not persisted.
- Added Jac tests, synthetic browser-fixture exporter, CSS, isolated config, README and ignore rules. No handwritten JS/Python application files.
- Read Jac essentials/fullstack/component/browser/ref/endpoint/config/diagnostic guides. Discovered installed CLI 0.37.11; downloaded official 0.37.21 to `/tmp` and verified its release SHA-256. Changed the scaffold entry-point to `main` for 0.37.21.
- Jac's Vite launcher passes unconditional `--host`, overriding its configured host. Personal-photo workflow therefore uses `jac run --no-dev`; verified UI/API on `127.0.0.1:8400`, no listener on 8401. No runtime dependency was patched.
- All changes are in `feature-ai-coach/` and `agent_note/`. No root/dev/calculator logic or workout/calorie records are read or written. Integration and live AI remain later phases.
