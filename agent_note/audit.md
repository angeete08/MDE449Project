# AI coach audit register

Updated: 2026-11-11
Scope: Phase 1–2 implementation self-review and tests. This is not a completed security, medical, or model-quality audit. Historical planning risks below remain applicable to later phases; current controls are recorded at the end.

| ID | Priority | Finding / risk | Planned control and evidence | State |
| --- | --- | --- | --- | --- |
| A01 | High | No visual-coach implementation or verified vision-model capability in inspected source | Real image-input smoke test, provider/version record, failure cases, and explicit manual fallback | Open — Phase 3 |
| A02 | High | Photos cannot justify the requested broad “body analysis” claims | Restrict output to visible regions/quality and user-confirmed focus; no body-fat estimates, diagnosis, attractiveness scoring, or inferred goals | Scope specified; enforcement unimplemented |
| A03 | High | Private progress photos could leak through logs, public assets, shared caches, or missing ownership checks | Private storage, server authorization, metadata stripping, bounded uploads, deletion/retention tests, no photo payloads in logs | Open — Phases 2/5 |
| A04 | High | Untrusted model/image text could alter goals or generate unsuitable exercises | Strict schema, region/exercise allowlists, user confirmation, curated progression rules, adversarial fixtures | Open — Phases 3/4 |
| A05 | High | Schedule edits or feedback could destroy completed workout/check-in history | Stable IDs, immutable completed snapshots, future-only edits, version conflicts and idempotency tests | Open — Phase 5 |
| A06 | Medium | Generic goal labels and pictures could imply a promised appearance or regional fat reduction | User-selected neutral goals; action/milestone illustrations; no future-body predictions; review final exercise copy | Open — Phase 4 |
| A07 | Medium | “Required progress uploads” could unnecessarily force body photos | Text OR photo completes a check-in; explicit skipped/deferred states; no app lockout | Specified; unimplemented |
| A08 | Medium | Camera permissions and long-running streams can fail or outlive the capture UI | User-triggered request; denial/upload fallback; stop tracks and revoke preview URLs on close/unmount | Open — Phase 2 |
| A09 | Medium | UTC conversion/DST/rescheduling can attach updates to the wrong calendar day | Store intended local date plus timezone and timestamp; month/year/DST/idempotency tests | Open — Phase 5 |
| A10 | Medium | Existing apps have different history/runtime behavior | Isolated new feature, no sibling imports, baseline checksums, dedicated runtime and unused ports | Planned — Phase 1 |
| A11 | High | Repository status shows pre-existing staged generated runtime files, including a JWT-secret path | Do not inspect or reproduce secret contents. Before any publishing task, explicitly review staged paths and exclude runtime/credential material; do not silently reset the user's index | Existing issue recorded; untouched |
| A12 | Medium | Current local food model could be mistaken for a body/vision-trained model | Separate adapter and capability test; honest model labeling; no training on user photos without a separate consented-data plan | Open — Phase 3 |
| A13 | Medium | Illustrations can depict incorrect movements or lack usage rights | Asset/license register, reviewed start/end positions, written cues, keyboard/screen-reader equivalents | Open — Phase 4 |
| A14 | Medium | Persistence/authentication architecture is not yet selected | Decide local-only versus authenticated multi-user mode before storing photos; test cross-user access before shared deployment | Open — Phases 1/2 |

## Planning review

- Branch ownership is simplified to two branches: photo coach (Phases 0–4) and progress canvas (Phases 5–7). Shared foundations and final integration stay inside these features. Both contribute to one `feature-ai-coach/` app with reusable types/media/storage; no coach changes belong on the calculator branch.
- Merge gates require shared contract compatibility, real plan/media integration before canvas completion, and explicit staged-path review. Branches/PRs have not yet been created or audited.

- Requested capabilities are covered by explicit phases and acceptance scenarios.
- “Delicate” and “canvas” have provisional definitions rather than silently assumed clinical/visual meanings.
- Model selection, real inference, authentication/storage, and illustrated assets remain implementation decisions; none are represented as completed.
- No application source or existing Git staging was changed in Phase 0.

## Audit process during implementation

For each risk, record the affected files, reproducible scenario, observed result, fix, and re-test evidence. A control described in a plan does not close a finding. Before final handoff, inspect media authorization/deletion, server validation, history preservation, provider data handling, and generated-image claims. Label self-review as self-review; no teammate or user review has occurred in this phase.

## Phase 1–2 self-review — 2026-11-11

- A02/A12: UI explicitly states manual focus, no analysis, no workouts generated. No model/provider is configured or called.
- A03/A14: selected ephemeral local prototype. Decoder checks format signatures/MIME, dimensions, encoded/decoded sizes, still images and corruption. EXIF rotation tested; fresh RGB output strips EXIF/ICC/text. No persisted photo, public URL, logs of payloads, or shared photo reader exists. No cross-user-storage claim is made; authenticated ownership remains required before persistence.
- Generated 0.37.21 photo RPC metadata is `unknown=true`, `writes=["*"]`; inspected runtime confirms it bypasses reader caching. Recheck after compiler or media-service changes. Previews use data URLs; removal clears state rather than revoking nonexistent object URLs. Memory release uses GC, not secure erasure.
- A08: camera starts on user action with audio disabled; accepted and stale streams stop their tracks on close/cancel/unmount; stale image replies cannot restore removed state. Fake-track and cancellation-helper tests pass. Real permission, device interruption and physical capture are still unverified.
- A10: app's own entry/config/dependencies/runtime; no sibling imports. Clean worktree tracked files outside notes/app match its base. Original checkout left untouched by operations. No pre-run checksum baseline was captured, so do not claim a before/after checksum proof for concurrently edited original files.
- A11: only explicit new feature/note paths staged for coach commits; generated `.jac`, dependencies, logs and private directories ignored. Original staging unchanged by this task.
- A15 (runtime limitation): Jac 0.37.21 dev Vite binds all interfaces even with `[client.vite.server].host`; verified command contains bare `--host`. Mitigation is documented and tested `jac run --no-dev` on loopback. Bare `jac run` is usable for development with synthetic fixtures only. No shared deployment approved or delivered.
- Real camera and mobile-device checks remain outstanding. There has been no teammate review or user testing.
