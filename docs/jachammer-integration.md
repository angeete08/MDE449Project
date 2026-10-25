# JacHammer integration, October 25, 2026

## Scope agreed with the team

The JacHammer dashboard becomes the main app. Retain the existing planner, PDF export and Apple Health bridge. Restore workout tutorial links and clickable meal recipe thumbnails. Add weekly goals, daily summaries and optional movement breaks. Defer biometrics, automated calorie changes and friends sharing.

## Branch preparation

Merged `feature/data-setup-onboarding` and `feature/apple-health-ios-sync` into `dev` with merge commits. The user selected keeping the “Apple Health · 28-day summary” source label in the sole conflict. Verified all three branch tips were ancestors before deleting those remote branches and `feature/integrate-fitness-apps`. `dev` is at merge commit `c84214d`.

All new implementation is on `feature/jachammer-stride-integration`, targeting `dev` for team review. The separate calorie-calculator branch was left untouched.

## Implementation notes

- The supplied ZIP contains older Jac syntax/configuration. Adapted it for Jac 0.37.21 and kept its routes, emerald theme, typography, cards and onboarding layout.
- Dashboard state uses authenticated per-user graph roots. The existing planner's JSON state retains validated weeks, ratings and exact history. No automatic migration of earlier shared-demo/browser data.
- Weekly activity counts explicit active minutes from Monday through the browser-local date. Date edits replace totals, so imported 28-day averages do not double-count activity.
- Movement breaks depend on entered sitting minutes. No claim of background sedentary detection or physiological readiness.
- The original global scoreboard traversed every account. It is disabled pending opt-in friendship and sharing rules.
- `.env` from the export was not copied into Git. The app uses no live model or model key.

## Review checklist

- Register and sign in, finish onboarding with storage consent, then edit the existing profile.
- Save activity totals, edit the same date and refresh. Check daily and weekly totals.
- Change the weekly goal, then refresh and verify persistence.
- Check workout YouTube links and recipe-thumbnail destinations.
- Rate a past session and verify only later unlogged workouts of its type change.
- Download the current plan PDF; create next week and inspect exact archived workouts.
- Check manual averages and the iPhone QR-code panel. A full physical-device sync requires a teammate's iPhone and companion app.
- Sign in as a different account and confirm the first account's data is not visible.

## Automated verification

`jac check` compiles without errors (compiler warnings remain for dynamic UI boundary types and private endpoint imports). `jac test` includes the original 21 tests, five dashboard tests and one API integration test for anonymous rejection, account isolation and replacement of daily totals.

Browser validation results are added below after exercising the running app.

## Browser verification on October 25

Used a synthetic local account. Confirmed signup followed by automatic login, the protected onboarding route, the disabled finish button before storage consent, and successful profile save/edit/resave. The dashboard correctly showed Sunday as a rest day.

Changed the weekly goal to 120 minutes, logged 30 minutes, replaced that date with 45 minutes, and reloaded. The dashboard restored exactly 45/120 minutes (38%) with the recorded steps, calories and mileage. The optional movement break rendered the three one-minute suggestions from an entered sitting time of 60 minutes.

All three displayed recipe thumbnails loaded and linked directly to YouTube videos. Workout exercise names linked to YouTube tutorial searches. Rating Monday “Too hard” retained Monday's 2×10 workout and changed Friday's matching strength exercises to 2×9. The PDF export handler completed without a browser error. The API integration test verifies archived exact workouts, feedback and inherited difficulty, and agreement between displayed meals and saved PDF meal data.

Manual weekly averages saved with their source label and unavailable metrics stayed blank. The iPhone sync action produced a QR code and companion deep link. A physical iPhone sync was not repeated during this session. Browser console contained no application errors during these flows.
