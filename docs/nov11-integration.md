# November 11 feature integration

The shared integration combines `review/coach-and-current-week`, `feat/calorie-tracker-nutrition-analyzer`, `feature-visial-coach` (including `feature/mobile-mini-app` and `feature/offline-part`), and the original `feature/mobile-app` history. Merge commits preserve the original feature commits.

`dev`, `feature/mobile-app`, and `feature/mobile-mini-app` share this combined application. Start from `dev` for new work. `feature/offline-part` remains the original dedicated offline baseline; its functionality is also included in the shared application.

## Online and offline behavior

- `/app` is the desktop dashboard; `/mobile` uses the same account and features in the phone layout.
- Meals includes daily intake, manual food logging, activity counts and energy balance. The nutrition tab accepts meal photos for Gemini estimates. These account operations require the server; photo analysis also needs a Gemini key and network access.
- Coach contains conversational history/reply improvements and the optional photo/goal studio. Reviewed exercise selection and its progress calendar remain unfinished. Live model output and physical camera capture were not revalidated during integration.
- `/offline` retains local workouts, feedback, activity, goals, history, selected meal ideas, next-week creation and PDF export after explicitly saving a device copy. It does not run AI or record the new nutrition food log offline. Sync drafts explicitly after reconnecting.
- Online current-week navigation and read-only next-week previews remain intact. Offline next-week creation restores an already-saved future week instead of replacing it. Sync rejects drafts that would lose existing weeks or change completed workouts.
- Keep local `.env`, account databases and exported device copies private and outside commits. Existing installations may show an update notice: save/sync drafts, close every Stride tab/window, and reopen to activate the new cached app.

## Run and verify

Use Jac 0.37.21, then `jac install`, `jac check`, `jac test --jobs 0`, and `jac run --no-dev`. Dependency pins from the offline branch avoid the nutrition branch's previously observed HTTP-client compilation issue.

Integration browser checks used a synthetic account: current-week restoration, 550-kcal manual meal logging and persistence, nutrition uploader, Coach UI, and host-stopped offline reload/next-week restoration followed by successful reconnect sync. Physical Android/iPhone installation, Apple Health device capture, live Gemini and photo-analysis quality require separate acceptance checks.

The remote branch set after cleanup is `main`, `calorie-calculator`, `dev`, `feature/calorie-calculator`, `feature/mobile-app`, `feature/mobile-mini-app`, `feature/offline-part`, and `logos`. The merged nutrition, visual-coach and review branch names can be removed because their commits remain reachable through the shared merge history.
