> **Updated energy/tour revision:** see [energy and interactive-tour validation](energy-tour-validation.md). It supersedes the earlier 7/14 kcal examples and five-page modal tour below.

# Local launch-review validation

Review checkout: `launch/11_14/code/`. Base dev: `c603369`. Local branch: `launch/nov16-review`. The user has approved integrating the reviewed milestone into dev.

## Automated verification (Jac 0.37.21)

- `jac check .`: **75 files passed**, with warnings (including existing dynamic boundary/private import and intrinsic metadata warnings).
- `GOOGLE_API_KEY='' GEMINI_API_KEY='' jac test --jobs 0 -x -v`: **70 tests passed in 305.40 seconds**. New coverage includes rolling-week chat retention, checkbox idempotence, partial-workout preservation, invalid/future completions, constrained routine validation, authenticated chat persistence/retries, corrected food entries, tour dismissal and safe future-week saving.
- `jac build --as client`: passed. The subsequent production review server also rebuilt successfully from the final application sources using `jac run --no-dev --port 8014 --api-port 8015`.
- `git diff --check`: passed.

The first new account test had a mock bound to the wrong isolated Jac module and made one real Gemini call with the synthetic question “What does Plan do?” and synthetic fitness preferences. No personal notes or photos were sent. The mock was corrected to intercept `litellm.completion`; the final full suite ran with provider keys disabled. Live model quality is not established by this run.

Raw final check/test logs are saved in `../validation/milestone/` relative to this checkout (the parent November 14 review folder).

## Browser checks with a synthetic account

- Fresh signup/onboarding; selecting dumbbells clears none; selecting none clears dumbbells.
- All six calorie shortcuts present; selecting 2000 updates the manual field.
- Injury note is saved and displayed in the amber Plan reminder.
- Optional tour appears after setup, Skip dismisses it, reload does not reopen it, and Quick tour reopens it. Studio instructions and Skip remain usable at 390 × 844.
- Independent exercise checkboxes update counts and energy immediately: two strength exercises yielded the disclosed reference estimate of 14 kcal. The checked total is above the difficulty controls and survives reload.
- Studio opens without a preview, accepts manual Core/dumbbells/20-minute preferences, previews the existing-catalog exercises, and saves the November 16 future week. Current checked work remains unchanged. The saved future week appears in both Plan and History calendars.
- History renders the current-week conversation section and explicit retention/deletion text. Chat persistence, retry and deletion are covered by authenticated automated tests; live chat was disabled in the review browser server.
- Cached `/offline` reloaded with the review server process suspended. A new Monday checkbox draft produced 7 kcal locally, alongside the earlier Friday 14 kcal. “Create next week offline” restored the exact saved Core routine; future checkboxes remained disabled. The draft and restored routine survived reload.
- After the server resumed, explicit Sync drafts succeeded and returned pending count to zero. Earlier completion totals stayed intact. Online Open / generate this week restored November 9 and retained the November 16 studio week.
- Desktop and phone-width layouts inspected. Screenshots are in the parent review folder: `plan-review.jpg`, `walkthrough-review.jpg`, `mobile-tour-review.jpg`.

## Review limits

Physical iPhone/Android installation, physical-camera permissions/capture, broader photo-recognition quality and new live-provider verification are still manual acceptance items. Calorie estimates use disclosed reference assumptions, not measured personal energy use. Chat rollover uses America/Detroit calendar weeks and deletes old content on the next account visit, rather than through a background job. Existing manual energy logs are preserved; users must avoid counting checked workouts again as additional activity.

## Review server

The isolated server is left available at `http://localhost:8014` with Gemini keys disabled for smoke testing. The existing app on port 8000 was not stopped or restarted. Use your normal configured environment when deliberately testing cloud features.
