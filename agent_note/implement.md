# AI coach implementation log

Updated: 2026-11-11

## Current state

Phase 0 is complete. Phases 1–7 are planned and not implemented. No application source, configuration, model, dependency, camera permission, or photo storage was changed during this phase.

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
| 1 | Not started | Consult required Jac guides; create isolated app, typed contracts, validated manual goal/region flow; verify entry resolution and isolation |
| 2 | Not started | Implement capture/upload preview and private media lifecycle with failure handling |
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
