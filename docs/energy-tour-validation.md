# Energy totals and interactive tour revision

Local-only changes to the review checkout at `launch/11_14/code/`, on `launch/nov16-review`. No push to dev is authorized for this milestone.

## User comments addressed

1. Meals Total Calories Burned includes checked exercises and manually logged activity for the displayed date. Checkbox changes update the parent saved state and all derived totals.
2. Today's Energy Balance is the first panel in Today and is removed from Meals. Food intake reloads when Today opens after food logging.
3. Every calendar date, including rest days, displays workout estimates, logged activity kcal and their sum. Archived and future weeks use the same calculation.
4. Exercise estimates now use activity-specific Compendium categories and a displayed duration rather than one flat strength rate over a very short inferred block. For the disclosed 70 kg reference and five-minute two-set blocks, weighted squats estimate 31 kcal, general resistance 21 kcal and light core 17 kcal. The duration is an app planning assumption, not a published per-exercise measurement. Timed exercises keep their scheduled duration. These are estimates, not measured personal calories.
5. Workout cards display checked exercise kcal, Logged activities and Total for that date above difficulty feedback.
6. After the welcome dialog, the tour opens Today, Plan, Meals, Coach, History and offline access in sequence. A nonmodal guide highlights each feature and permits real clicks/input before Next. Hide/Show, Back, Next and Skip are available without requiring a mutation. Only the instructions scroll in a short viewport. A reopened tour survives dashboard refreshes.

All calorie displays share `workout_rules.day_energy`. No calorie totals are accumulated as checkbox events occur; they are recalculated from completion state and matching-date logs, preventing retry/double-count errors. Existing manual activity records and completed exercise amounts are preserved.

## Sources and assumptions

- 2024 Adult Compendium conditioning activity categories: https://pacompendium.com/conditioning-exercise/
- Walking categories: https://pacompendium.com/walking/
- Category mapping to the app's individual movements is an app inference. Reference mass: 70 kg. Formula: MET × 3.5 × 70 / 200 × minutes. Strength duration: sets × (1.5 + 0.1 × reps) minutes including rest/setup. Actual weight, time, pace and effort change energy use; the UI discloses the assumptions and source links.

## Verification

- Jac 0.37.21: `jac check .` — **77 files passed** with warnings.
- Full serial suite with Gemini credentials disabled — **73 tests passed in 231.24 seconds**.
- New tests cover category/rate/duration values, same-date workout-plus-manual sums, rest-day entries, archived weeks, checkbox retries/unchecks, and replacement of manual totals.
- Final targeted checks after the browser-driven fixes — DashboardApp and Walkthrough both passed.
- Final production review server rebuilt successfully and runs at http://localhost:8014 . Gemini remains disabled for smoke testing. The temporary server on 8016 is stopped after verification.
- `git diff --check` passed.

### Browser acceptance

A separate synthetic Energy QA account was used for writes, preserving the user's Milestone QA activity entries.

- A 21 kcal checked exercise plus 100 manually logged kcal showed **121 kcal** consistently in Today, Meals and the corresponding calendar day.
- Unchecking removed only the 21 kcal; the 100 kcal manual entry remained. Rechecking restored 121, rather than accumulating another estimate.
- A 400 kcal food entry in Meals appeared as 400 intake / 121 activity out / +279 net when returning to Today.
- Users could open and save the activity dialog, check an exercise, enter food and switch tabs while the nonmodal tour stayed open. Guide Hide/Show and Back/Next opened the corresponding features.
- On the final 8014 build, Quick tour remained open through Open / generate this week, an idempotent dashboard refresh that preserved saved workouts.
- At 525 × 616 (the commented viewport), instructions scroll independently and Hide, Back/Next and Skip stay visible. The default viewport was restored afterward.
- The original example is date-specific: 186 logged kcal is dated November 14, a rest day. Checked Monday/Friday exercises belong to November 9/13 and appear on those dates. The user's manual 186 kcal and original check states were preserved.

Screenshots in the parent review folder: `energy-tour-mobile.jpg`, `energy-tour-review.jpg`. Automated logs: `../validation/energy-tour/` relative to this checkout. Physical-device installation and new live-model quality were not evaluated by this revision.
