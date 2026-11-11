# AI coach test results

Updated: 2026-11-11
Current phase: 0 — planning only

## Evidence collected

| Check | Result | Evidence / limitation |
| --- | --- | --- |
| Repository instructions | Read | Root and calculator `AGENTS.md`; dev instructions also inspected |
| Existing application entry/configuration | Inspected | Calculator owns its runtime/entry and reserves 8300/8301; not a coach runtime verification |
| Existing history behavior | Inspected | Dev planner has dated weeks and history snapshots; tests were not rerun |
| Existing visual coach implementation | Not found in inspected Jac source | Keyword search plus source reads; no claim about files outside the inspected workspace |
| Requested notes | Created | `plan.md`, `implement.md`, `audit.md`, `test_result.md` |
| Source/model/dependency changes | None in this phase | Documentation-only scope |

## Tests not run

Branch-plan review (2026-11-11, revised): every phase 0–7 maps to exactly one of two feature branches: photo coach (0–4) and progress canvas (5–7). Removed separate planning/foundation/integration branches and documented sequential merging, shared interfaces, and extension rules. Local inspection confirmed `dev` exists and the current branch is `feature/calorie-calculator`. Proposed coach branches have not been created/pushed. This update changes documentation only; no runtime tests were needed or run.

- `jac check`, `jac test`, app startup, and browser flows: not run because this phase creates documentation only and no coach app exists yet. Earlier calculator test results do not validate this new feature.
- Camera permission, image upload, media deletion/ownership, live vision inference, exercise rules, illustration accuracy, calendar persistence, and progress check-ins: not implemented/tested.
- No user study, teammate review, clinical assessment, trained vision-model evaluation, or measured model accuracy has been performed.

## Required test groups before product completion

| Group | Required cases | Current status |
| --- | --- | --- |
| Isolation/build | Correct feature CWD and entry; own runtime; no parent/sibling changes; Jac 0.37.21 | Pending |
| Input and media | Profile enums/ranges; image type/bytes/dimensions/size; malformed upload; EXIF orientation; retention/deletion | Pending |
| Camera/browser | Permission allowed/denied; no camera; capture/retake/cancel; track cleanup; mobile fallback | Pending |
| Vision contract | Allowed regions; multiple/unknown regions; malformed schema; timeout/outage; malicious image text; manual correction | Pending |
| Live vision evaluation | Consented fixtures covering regions, clothing, framing, lighting, occlusion and varied appearances; per-region errors and abstentions; latency | Pending; fixtures/model not selected |
| Goal/exercise rules | Each goal × region × equipment × experience; constraints; allowed exercise IDs; recovery/progression bounds | Pending |
| Visual/accessibility | Illustrated steps/captions; missing assets; keyboard/focus; screen-reader calendar alternative; responsive layout | Pending |
| Calendar | Month/year/leap/DST boundaries; local dates; future-only rescheduling; duplicate sessions; version conflict | Pending |
| Check-ins | Text-only/photo-only/both/empty; upload failure; duplicate submit; retry; edit/delete; restart/reload | Pending |
| Ownership/privacy | Cross-user plan/photo access; private URLs; removal; no raw image/secret logging; external-inference disclosure | Pending |
| Regression | Existing completed history and calorie targets preserved; unrelated apps/runtime untouched | Pending |

## Result entry template

For each subsequent run record: date, phase, feature working directory, toolchain/browser/model versions, exact command or UI scenario, expected result, actual result, pass/fail/blocked status, artifact path, and remaining limitation. Keep mocked tests distinct from live-model runs. Record failures and resolutions instead of replacing them with an unsupported “all passed.”
