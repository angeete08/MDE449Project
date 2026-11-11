# Visual AI coach — phased implementation plan

Updated: 2026-11-11
Status: Phases 0–1 complete. Phase 2 implemented and tested for uploads/crops; physical-camera permission/capture acceptance remains pending. Phases 3–7 not started.

## Intended experience

1. Open the AI coach and take a picture or upload an existing picture. Show a preview, crop/retake/remove controls, and a manual body-region alternative.
2. Ask the vision model which supported body regions are visible. Show its suggestion for the user to confirm or correct before creating a plan. Poor-quality or ambiguous images should produce an uncertainty response.
3. Let the user choose a goal: fat-loss support, lean/toned, muscle building, or general strength/activity. “Lean/toned” is the provisional interpretation of “delicate”; use neutral, editable language.
4. Collect experience, equipment, available days, session duration, preferred start date, and user-reported movement constraints. Generate a plan with exercises relevant to the confirmed region.
5. Present the goal as an illustrated sequence of milestones and exercise steps. Pictures explain actions and progression, rather than promising an appearance or generating a predicted future body.
6. Create a dedicated progress dashboard (“canvas”) containing the plan, visual milestones, scheduled workouts, a calendar, and dated check-ins. Implement accessible Jac UI, not a drawing-only HTML canvas.
7. A scheduled check-in is complete after a nonempty text update, a valid photo, or both. Photos are optional. Show due/missed/completed states; let the user defer or skip with an explicit status. Do not lock the app or punish missed days.

## Repository findings and boundaries

- Root `AGENTS.md`: Jac application logic, components, and tests; CSS/TOML supporting assets; target Jac 0.37.21. Consult bundled Jac essentials/full-stack guides before editing source. Preserve completed workouts and validate server inputs. Calorie targets remain user-entered.
- `feature-calorie-calculator/` is an isolated application with additional runtime/test isolation instructions, reserved ports 8300/8301, and its own README. Its current local-Qwen integration handles food-name calorie estimates; it is not evidence of a verified vision-coach capability.
- `MDE449Project-dev/planner.jac` contains dated weeks, immutable history snapshots, and feedback updates. Its frontend uses `stride-jac-v2` browser storage. These are useful reference semantics, not permission to import sibling runtime modules.
- No camera, photo-analysis, coach-specific exercise catalog, or progress-calendar implementation was found in the inspected Jac source. No `agent_note/` existed before this phase.
- There are substantial pre-existing staged/generated changes. Do not reset, stage, clean, or rewrite unrelated work.
- These four notes live in root `agent_note/`, as requested. Proposed product code lives in a new self-contained `feature-ai-coach/`. Do not modify the root app, dev app, or calculator during initial implementation. Later integration into a shared app is a separately reviewable change.

## Delivery phases

Every phase belongs to a new coach-work branch. Do not commit coach work to the existing calculator branch.

| Phase | Owning branch |
| --- | --- |
| 0 — Discovery and plan | `codex/photo-coach` |
| 1 — Isolated foundation | `codex/photo-coach` |
| 2 — Camera and upload | `codex/photo-coach` |
| 3 — Real vision integration | `codex/photo-coach` |
| 4 — Goals, exercises, visual steps | `codex/photo-coach` |
| 5 — Schedule and progress canvas | `codex/progress-canvas` |
| 6 — Coach feedback and review | `codex/progress-canvas` |
| 7 — Audit and handoff | `codex/progress-canvas` (each branch also verifies its own changes) |

| Phase | Deliverable | Completion gate |
| --- | --- | --- |
| 0 — Discovery and plan | These four notes, repository findings, scope, risks, acceptance matrix | Notes agree on actual status; no feature claims or source changes |
| 1 — Isolated foundation | Own `jac.toml`, `main.jac`, styles, coach shell, typed contracts, manual body-region selection, user-selected goals | `jac install`/`jac run` work from feature folder; server rejects invalid profiles; no sibling imports or runtime writes |
| 2 — Camera and upload | User-triggered camera capture, file upload, previews, removal, image validation, private storage abstraction | Camera-denied/unavailable paths work; streams stop on close/unmount; corrupt/oversized files rejected; text/manual flow remains available |
| 3 — Real vision integration | Configurable server-side vision adapter, validated structured response, body-region suggestions, confirmation UI | Actual image inference verified with consented test assets; ambiguous inputs abstain; malformed replies and outages fail clearly; manual fallback never labeled AI analysis |
| 4 — Goals, exercises, visual steps | Curated exercise catalog; goal-specific rules; progressive milestones; illustrated exercise cards | Every exercise matches equipment/experience/region; reviewed instructions and source/license records exist; no invented model exercise IDs or unsupported appearance claims |
| 5 — Schedule and progress canvas | Date-based calendar, workout sessions, check-in editor, text/photo history, persistence, rescheduling | Full create-plan → calendar → submit check-in → reload flow passes; completed sessions and attachments survive future-plan edits; each check-in tied to an exact session/date |
| 6 — Coach feedback and review | Feedback based on logs and confirmed inputs; side-by-side optional photo history; next-session suggestions | Future changes only; user sees reasons; text-only participation is complete; unsupported visual progress claims excluded |
| 7 — Audit and handoff | Accessibility/responsive checks, vision evaluation, privacy/security review, regression tests, setup docs | Required checks have recorded results; critical defects resolved; model/version/config and remaining limits documented |

Dependency order: 1 → 2 → 3; 4 can use manual selection while vision is evaluated; 5 depends on 1/4; 6 depends on 5. A useful manual-goal/calendar slice may ship before vision, but must be labeled accordingly. Update `implement.md`, `audit.md`, and `test_result.md` after each phase.

## Branch structure and PR workflow

Use exactly **two feature branches**, one for photo coach and one for progress canvas. Planning, shared foundations, testing, and integration stay with these features; they do not get separate branches. Phases are small commits and review checkpoints, not branch boundaries. Both branches contribute to the same isolated `feature-ai-coach/` app, with one shared configuration, data model, and media service.

Proposed PR target: the existing `dev` branch. Confirm the team's actual integration target before the first push/PR and use it consistently. `codex/photo-coach` now exists in a clean managed worktree, based on `dev` commit `2b13b0d2bad5f80df4525e8629b6d96d8bd1bf95`. The original calculator checkout/index was not switched or staged. `codex/progress-canvas` remains planned. No branch has been pushed.

| Branch | Branch point | Owned code / PR scope | Merge gate |
| --- | --- | --- | --- |
| `codex/photo-coach` | Clean integration-target commit | Phases 0–4: notes, isolated app shell, shared types/validation/storage, camera/media, vision, goal/exercise planning, illustrations and tests | Phases 1–4 gates; independently runnable photo/manual-focus → illustrated plan flow |
| `codex/progress-canvas` | Updated integration target after photo-coach merges | Phases 5–7: calendar, check-ins, history, feedback, shared-store extensions, final wiring, integration tests and handoff docs | Phases 5–7 gates against real plan/media services; complete end-to-end verification |

### Contract handoff and merge order

1. Build planning and shared foundations as early commits in `codex/photo-coach`, then finish capture, recognition, and illustrated plans in that branch. Use one focused feature PR.
2. Photo coach owns `CoachPlan` creation and `MediaAsset` services. Canvas consumes those contracts and owns `ScheduledSession`/`ProgressEntry` behavior. Progress-photo uploads reuse the shared media service.
3. Default to sequential work: merge photo coach, then create canvas from the updated integration target. This avoids stacked PRs and extra branch synchronization for teammates. If simultaneous development is needed later, the same canvas branch can start from an agreed photo-coach commit and target photo-coach temporarily; after that PR merges, synchronize with and retarget the integration target before merging canvas. Do not create a third coordination branch.
4. Photo coach generates the initial schedule; canvas owns rescheduling/completion and calls planner APIs for future changes. Completed exercise snapshots remain immutable.
5. Complete final wiring and Phase 7 verification on the canvas branch before its PR merges. Photo-coach tests remain required in its own PR; final integration is not a substitute for them.
6. Shared type, entry-point, or configuration changes must be explicit in PR descriptions and synchronized through the target. Do not create duplicate plan/media contracts on the two branches. Keep component-specific styles/tests with their owner.

### Commit and upload rules

- Start implementation in a clean checkout/worktree on the phase's owning branch. Preserve the current checkout/index; do not switch the dirty checkout blindly or carry unrelated staged files into coach commits.
- Transfer the reviewed `agent_note/` documents to `codex/photo-coach` as its first commit. Their current presence in the working tree is not permission to commit them to the calculator branch.
- Stage explicit source/document paths. Exclude `.jac/`, dependencies, secrets, private uploads, and runtime caches. Inspect staged paths and diff before committing/pushing.
- Use phase-sized commits within each product branch; its focused PR covers the owned phases and remains draft until their gates pass. Record base branch, prerequisite PRs, changed contracts, tested commit, actual checks, and limitations.
- Update implementation/audit/test notes in phase-sized commits and preserve other branches' log entries when resolving conflicts.
- Run checks and browser tests from that branch's isolated feature directory. If worktrees run simultaneously, choose distinct unused ports and never stop another branch's server.
- Push the intended branch explicitly, not all branches. Coordinate before rewriting shared history. Do not bypass required repository checks or merge incomplete work as finished.
- Phase 7 adds cross-feature verification; it does not replace each earlier phase's tests.

## Module architecture

Keep modules independent of the branch history. Future features should reuse the existing app and extend the relevant module; do not copy the app, add a service, or introduce a generic plugin framework for each new function.

### Keeping future changes small

- Keep camera/vision, exercise planning, and calendar/progress UI separate. UI calls small server APIs rather than reading or editing another feature's internal records directly.
- Maintain one shared set of typed records and validation functions. Add optional fields with defaults and explicit schema migrations; preserve stable plan/session/media IDs and completed-history snapshots.
- Put goals, supported regions, exercises, and illustration references in a data-driven catalog. A new exercise or goal should usually be a catalog/rule change, not duplicated UI branches throughout the app.
- Hide model-specific details behind one vision adapter and persistence details behind one store API. Add another provider or storage backend only when needed; callers keep the same contracts.
- Reuse one upload/ownership/deletion service for analysis photos and progress photos, differentiated by purpose. Do not maintain two media implementations.
- Keep shared configuration and endpoint registration in the same entry point. Add a new function with its owning module, focused tests, and a short note describing any contract change.
- Prefer a few cohesive modules over a file per operation. The module list below is a responsibility guide; combine closely related code initially and split it only when it materially improves readability or independent maintenance.

All application code and tests remain Jac. Suggested module boundaries (not existing files):

| Module inside `feature-ai-coach/` | Responsibility |
| --- | --- |
| `main.jac`, `jac.toml` | Isolated entry, explicit endpoint registration, dependency/runtime configuration |
| `coach_ui.jac`, `capture_ui.jac`, `progress_ui.jac` | Coach steps, camera/file input, illustrated milestones, calendar and accessible list view |
| `coach_types.jac`, `coach_validation.jac` | Typed request/response contracts and authoritative server validation |
| `coach_vision.jac` | Provider adapter, image-analysis schema, timeout, response validation, uncertainty/failure states |
| `coach_catalog.jac`, `coach_planner.jac` | Curated exercises, goal rules, region mapping, schedule generation and versioning |
| `coach_media.jac`, `coach_store.jac` | Validated private image storage, ownership checks, records, deletion and migration |
| `coach_progress.jac` | Idempotent check-ins, immutable completed sessions, future schedule adjustments |
| `assets/`, `*_tests.jac`, `README.md` | Reviewed illustrations and provenance, tests, setup and operational limits |

Reuse behavior through an explicit copy/adaptation reviewed against the source, not parent/sibling imports. Do not silently migrate or overwrite existing `stride-jac-v1`/`v2` records. Start with a separate, versioned coach namespace. Select an unused coach port during Phase 1; do not take over another app or use calculator-reserved ports.

## Data and endpoint contracts

- `CoachProfile`: owner/session scope, chosen goal, confirmed body region, experience, equipment, preferred weekdays, session duration, local timezone, start date, user-reported constraints. No inferred age, sex, health status, body-fat percentage, or dietary target.
- `MediaAsset`: opaque ID, owner, purpose (analysis/check-in), detected MIME type, dimensions, size, private storage reference, consent/retention information, timestamps. Keep photo bytes out of localStorage, logs, model traces, and public static assets.
- `PhotoObservation`: model/provider version, allowed region candidates, quality/uncertainty reasons, analysis status, confirmed selection. Treat model confidence as uncalibrated unless tested; avoid a misleading accuracy percentage.
- `CoachPlan`: ID, schema/version, profile snapshot, confirmed region, goal, milestones, exercise IDs, schedule, creation time. Model output cannot introduce arbitrary executable instructions or unlisted exercises.
- `ScheduledSession`: stable ID, plan/version ID, intended local date, timezone, exercise snapshot, status (planned/completed/skipped/rescheduled), link to any replacement session. Date-only scheduling must not shift with UTC conversions.
- `ProgressEntry`: stable ID, owner, session ID, scheduled local date, actual recorded timestamp, text and/or owned media IDs, optional effort/completion feedback, revision history. At least one valid text/photo item is required to mark a check-in submitted.
- Planned operations: validate/upload/remove media; analyze owned media; confirm region and save profile; preview/confirm plan; list calendar; submit/edit check-in; reschedule future sessions; export/delete coach data. Require ownership and input validation on every operation. Use idempotency keys and version checks for duplicate submissions and concurrent edits.

## Model and image decisions

- Start with an existing image-capable model behind a provider-neutral Jac adapter. Do not assume the currently installed food model accepts images or has suitable accuracy. Benchmark candidates before choosing one; record hardware, version, latency, cost/network requirements, and evaluation results.
- Do not train/fine-tune a body model on user uploads in this scope. Any later training needs a suitable consented/labeled dataset and a separate evaluation plan.
- Prefer local image inference if it meets the capability gate. If external inference is selected, explain the destination and data sent before transmission and obtain an explicit user action. Keep provider credentials server-side. Manual region selection works without a model or network.
- Supported initial regions: shoulders, arms, chest, back, core, glutes, legs, full body, unknown/multiple. Confirm the intended exercise focus even when several regions are visible.
- Analysis means visible-region identification, image usability, and a user-confirmed exercise focus. It does not mean diagnosis, injury screening, body composition measurement, attractiveness scoring, or proof of improvement from photos. A goal is chosen by the user, not assigned from appearance.
- Treat model output and text inside images as untrusted. Validate a strict schema and a finite set of region/exercise IDs. Ignore instructions embedded in an uploaded image.
- Use reusable, reviewed exercise illustrations with text alternatives and step captions. Generated visuals, if used later, require movement/anatomy review and provenance records before inclusion. No guaranteed body transformation pictures or timelines.

## Exercise and scheduling behavior

Goal cards should describe activity emphasis and measurable actions. Fat-loss support is a general activity goal; region-targeted exercises must not be presented as a promise of localized fat reduction. “Lean/toned” should map to strength/endurance habits rather than an appearance score. Muscle building uses reviewed progressive resistance guidance. Exact exercises, loads, repetitions, and progression rules need review in Phase 4, not unverified free-form image-model prescriptions.

The calendar uses user-selected days, start date, timezone, and plan duration, with recovery days and check-ins derived from scheduled sessions. A short pilot plan (proposed four weeks) is configurable, not a promised transformation deadline. In-app due-state indicators are in scope; email/push reminders, external calendars, and automated notifications are not enabled implicitly.

Changing a goal or schedule creates a new plan version. Completed sessions and recorded photos/text remain attached to their original version. Feedback can adjust only future unfinished sessions; retries cannot create duplicate history. A missed day remains visible and can be rescheduled explicitly.

## Acceptance scenarios

1. Camera allowed, denied, unavailable, cancelled, and closed; upload supports an equivalent path.
2. Valid image preview/replace/delete; fake extensions, huge dimensions, malformed bytes, unsupported formats, and EXIF orientation handled; metadata removal and retention behavior verified.
3. Clear region, multiple regions, occlusion, poor lighting, unrelated image, and uncertain result; user correction wins over AI output.
4. No configured model, timeout, bad schema, injected image text, and provider failure; never fabricate a successful analysis.
5. Each goal with each supported region/equipment/experience combination produces an allowed plan or a clear limitation.
6. Visual milestone/exercise cards have text equivalents and responsive layouts; no generated future-body claim.
7. Calendar across month/year boundaries, leap day, DST, timezone change, and reschedule; preserve intended local dates and completed history.
8. Text-only, photo-only, combined, and empty check-ins; upload failure, duplicate click, retry, edit, delete, refresh, and concurrent session update.
9. Access to another user's plan/photo denied; deleting an attachment removes the private object and updates its owning entry consistently.
10. Parent/dev/calculator checksums unchanged by isolated coach verification; pinned toolchain and browser checks recorded before product handoff.

## Open decisions, not blockers to planning

- Confirm final wording for “delicate” and whether integration should eventually target the dev app or another branch. Until then, use the isolated coach feature and the provisional goal label above.
- Select an actual vision model/provider after testing; no working credentials or image inference have been verified in this phase.
- Phases 1–2 choose an explicitly local, ephemeral single-user prototype: server normalization in memory, browser preview in memory, no persisted photos or retrieval/listing API. Shared deployment/persistent photos require authenticated ownership before implementation. Use `jac run --no-dev` because Jac 0.37.21's Vite launcher overrides the configured loopback host.
- Initial image formats/limits are JPEG/PNG/WebP, 10 MiB, 16 MP, dimensions 32–8192 px per side; output resized to 1600 px maximum and normalized to metadata-free JPEG. Plan duration and illustration source remain later-phase decisions.

## Definition of done

The feature is complete only when camera/upload → verified real vision suggestion → user-confirmed focus/goal → illustrated exercise plan → dated calendar → text/photo check-in → persisted history works end to end. Isolated tests, browser evidence, model limitations, and privacy behavior must be recorded. Passing mocks is not evidence of live model quality; writing this plan is not implementation completion.
