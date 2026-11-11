# AI coach test results

Updated: 2026-11-11
Current phase: 3, integrated with the current mobile/offline baseline. Historical results follow; migration verification is appended below.

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

## Phase 3 prototype evidence — 2026-11-11

Before migration: 21 offline tests passed and 15 source files checked. Real Ollama 0.40.3 with qwen3:1.7b and gemma3:4b passed a goal-translation plus blank-image-abstention smoke test in 80.45 s on an 8 GB Apple Silicon machine. The first vision prompt hallucinated regions on a blank image; the revised human-presence-first schema/prompt passed the regression. Concurrent model loading and compilation caused a 90-second timeout; sequential verification succeeded.

Prototype browser checks verified Other opens a dialogue, manual picture changes, balance reminder, accept, cancel retaining the selected draft, and server-validated self-reported activity baseline. These are not evidence of real-person recognition accuracy or physical-camera testing. API transport uses automated mocks; live external inference remains unverified.

## Corrected baseline verification — 2026-11-11

Target: /Users/zeta/Documents/EECS449_e1/MDE449Project-mobile. Branch: codex/photo-coach, merged with feature/offline-part at 83b04c9. The outer Course Compass app is unchanged.

- Source check: root main.jac plus all 15 coach Jac files passed (16 total, 61.85 s).
- Dependency installation: existing environment lacked pip; its bundled Python also fails macOS detection in pip/packaging. Jac install could not complete. Reused the already verified Pillow 12.3.0 package from the same Jac/Python runtime's coach environment for local verification. This is a machine setup limitation, not a clean-install success claim. The dependency remains declared in jac.toml for teammates.
- Full suite and integrated browser results: pending at this entry; see subsequent entries.

### Integration results after repairs

- Full initial run: 49 passed, 2 failed, 4 errors. Media compilation failures arose in the process started before Pillow was available. The old absolute-date HealthKit fixture fell outside its 28-day window. Two provider mocks patched a different module instance after packaging.
- Repaired fixture date relative to the test clock (no health-sync logic changed), patched the actual provider function module, and reran affected tests with dependencies available.
- Affected regression run: **21 passed in 200.06 s** across dashboard_api_tests.jac, offline_tests.jac, health_sync_tests.jac, coach/phase3_tests.jac and coach/api_tests.jac. Includes anonymous denial on all five coach endpoints, authenticated validation, existing account isolation, completed-workout behavior and offline sync.
- Final source recheck: main.jac, health_sync_tests.jac and coach/phase3_tests.jac passed (3 files, 82.91 s), in addition to the preceding 16-file check.
- Browser: synthetic local QA account, onboarding, desktop Coach tab, custom illustration and warning, accepted preferences, self-reported baseline, image upload/normalization, real local model abstention on geometric shapes, removal clearing observations, and existing /mobile route verified. No physical camera activated. No live Google/OpenAI request sent.
- Explicit live smoke now requires COACH_LIVE_TEST=1, so a broad test discovery cannot accidentally load a model or depend on Ollama.
- Remaining: representative real-person image evaluation, physical-device/camera acceptance, live external API verification, and a clean dependency install on this machine's repaired Jac runtime.

### Final handoff checks

- Opt-in live-test guard: 1 passed in 4.63 s without loading a model.
- Final preview rebuilt successfully at http://localhost:8410. After following the existing service-worker close/reopen update flow, the custom dialog measured 880 px wide at x=200 in a 1280 px viewport, confirming centering. Screenshot: /tmp/stride-coach-integrated.jpg.
- Browser checks used a synthetic local QA account only; no existing user profile was edited and no physical camera was activated. Mobile route was checked, not a physical phone or native build.
- git diff --check passed. Source changes are confined to the integrated coach, its entry/config/UI integration, documentation, and the date-stable health-sync test fixture.
