# AI coach test results

Updated: 2026-11-11
Current phase: 1–2 implementation. Historical planning-only results follow; current evidence is appended below.

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

## Phase 1–2 results — 2026-11-11

Branch `codex/photo-coach`, base `2b13b0d2bad5f80df4525e8629b6d96d8bd1bf95`; commands run in `/Users/zeta/.codex/worktrees/photo-coach/MDE449Project/feature-ai-coach`. Current feature source was tested before its implementation commit. Compiler: official Jac 0.37.21 macOS arm64; release checksum matched. No model tested.

| Check | Result | Evidence |
| --- | --- | --- |
| `jac install` | Pass on 0.37.21 | Own `.jac/venv` and client dependencies; Pillow 12.3.0 |
| `jac run --show` | Pass | Resolves feature's own `main.jac`; config uses dotted `main` |
| `jac check --nowarn main.jac coach_profile.jac coach_media.jac coach_ui.jac capture_ui.jac camera_lifecycle.jac coach_tests.jac browser_fixture.jac` | Pass | All 8 source files checked; warnings suppressed, not a zero-warning claim |
| `jac test --jobs 0 coach_tests.jac` | Pass | 11 tests: 36 manual goal/region combinations, invalid enums/ranges/date/timezone, duplicate days/equipment, supported formats, corrupt/mismatched/oversized/dimension inputs, EXIF strip/orientation, resizing, animation, fake-track cleanup and cancellation guards |
| `jac test --jobs 0 browser_fixture.jac` | Pass | Exports synthetic geometric image and corrupt PNG fixture to `/tmp`; no personal images used |
| Manual browser flow | Pass | Codex in-app browser at localhost:8400: arms + muscle submitted successfully; invalid timezone rejected by server |
| Upload/crop/restore | Pass | Synthetic PNG → sanitized preview; keyboard crop slider to 50% → natural size 320×240 from 640×480; restore → 640×480 |
| Invalid replacement | Pass | Corrupt PNG rejected; existing valid preview retained |
| Remove/reload | Pass | Remove clears photo/crop UI; reload clears photo and profile selections |
| Development mode | Starts, privacy limitation | Jac passes Vite bare `--host`, so configuration does not keep frontend off LAN |
| `jac run --no-dev` | Pass | Client bundle built, root returns 200; UI/API bind to 127.0.0.1:8400; no 8401 listener |
| Non-dev browser retest | Pass | Preferences validated and synthetic upload preview displayed; browser error log empty |
| Responsive layout | Pass at 390×844 emulation | Single-column layout; DOM content width equals viewport width (390 px); full-page screenshot visually inspected; viewport reset afterward. Not physical mobile-device testing |
| Physical camera allowed/denied/capture/retake | Not performed | Camera code and fake-track tests exist; no user camera activated or camera permission granted |
| Live vision/calendar/workout generation | Not implemented | Phases 3–7 |

Initial issues resolved: 0.37.11 scaffold syntax differs from required 0.37.21 entry-point; entry server imports changed to project-root form; browser dynamic API boundaries explicitly typed; tuple assignment syntax corrected. Browser `fill` on a range did not trigger the expected state change, so crop was verified via keyboard Home instead. HMR transient source-map warning disappeared after clean non-dev restart.

Desktop screenshot: `/tmp/stride-coach-preview.jpg` (temporary artifact). Final source checks: no tracked changes outside `agent_note/` and `feature-ai-coach/` relative to the worktree base; runtime/dependency directories excluded from staging. Exact content belongs to the feature implementation commit following `4fca642` (see `git log`); no self-referential commit hash is embedded in that commit.
