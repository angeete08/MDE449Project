# November 16 review milestone (local only)

This checkout lives at `launch/11_14/code/`, based on dev `c603369`. Do not push it until the user has reviewed and approved it.

## Behavior to review

- Equipment selection makes “none” exclusive; removing the final equipment choice restores “none.” Server normalization also accepts older mixed selections without preserving “none.”
- Calorie target shortcuts: 1000, 1200, 1500, 2000, 2500, 3000. These are input shortcuts, not recommended intakes; the editable target remains user-controlled.
- Account injury notes persist as before and appear in a compact amber Plan reminder. Notes are echoed as text, not interpreted as a diagnosis or exercise prescription. They are excluded from cloud chat context.
- Every recommended exercise has an independent completion checkbox and illustrative kcal estimate. The checked total appears above difficulty feedback; ratings remain separate. Completed and partially completed days are protected from automatic adaptation.
- Estimates use a 70 kg reference mass and 2024 Adult Compendium MET categories: resistance 3.5, moderate walking 3.8, mild stretching 2.3. Formula: MET × 70 × minutes / 60. Strength assumes three seconds per repetition and 45 seconds between sets. These assumptions are disclosed in the UI. No body-weight inference or personal calorie target calculation is performed.
- Meals combines checked workout estimates with manually logged ADDITIONAL activity energy. Do not log checked workouts again as extra energy. Existing manual logs are not rewritten. Photo estimates can be corrected on the same food entry before adding intake; retries do not create duplicates.
- Coach saves successful question/answer pairs to the authenticated account. History shows only the current Monday–Sunday week in America/Detroit. Earlier weeks are deleted upon the next authenticated account/profile access, not by a background scheduler. Deletion is available in History. Maximum 100 exchanges per week; at capacity, the user must delete history to continue. Failed provider requests do not save incomplete pairs; request IDs make successful retries idempotent. UI messages and provider context are bounded separately.
- Photo and goal studio: optional image/manual focus → confirm/edit focus → preferences → exercise preview → explicit Save next week. Exercises come from Stride's existing catalog and deterministic rules, not unreviewed model-generated movements. Cloud/local model choice still applies only to the separate photo/goal interpretation. The saved week records confirmed preferences/goal notes; raw photos stay ephemeral.
- Studio schedules are saved only to a future week; existing saved weeks cannot be overwritten. The preview includes chosen weekdays, focus and equipment. Bands/mat-only selections fall back to the bodyweight catalog, disclosed before save. Session minutes are a budget, not measured workout duration. Notes are reminders, not medically interpreted constraints.
- Progress calendars in Plan and History include archived/current/saved future weeks. When a future week arrives, Open / generate this week restores it, including its exercise selection and completion state.
- Offline copies include completion/calendar/confirmed routine data and the optional injury reminder, with updated storage consent. Completion edits replay as conditional whole-plan drafts; conflicts and completed-workout preservation remain enforced. Chat and new food entries still require the server.
- Phone access/install instructions are in the compact upper-right global banner menu, not repeated on landing/onboarding/dashboard.
- The optional five-page tour appears on the first dashboard visit after onboarding/login. Skip tour and completion persist per account. Quick tour reopens it. It explains each tab, the studio workflow and local/cloud/offline boundaries.

## Start

Use Jac 0.37.21. Run `jac install`, then `jac run --no-dev`. For a second local review server, use `jac run --no-dev --port 8014 --api-port 8015` (without stopping another running app). Open the printed localhost address. Use a stable HTTPS origin for physical phone installation and offline acceptance.

## Reference

MET categories: https://pacompendium.com/conditioning-exercise/ and https://pacompendium.com/walking/ . Estimates are illustrative app calculations, not a validated personal energy model.

## Acceptance

Record the final compile, automated test, production build and browser results in `docs/nov16-validation.md`. Use synthetic accounts and mocked providers for automated tests. Do not claim physical-phone installation, camera hardware or live-model recognition quality from browser emulation/mock tests.
