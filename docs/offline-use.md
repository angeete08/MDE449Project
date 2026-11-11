# Using Stride without a reachable server

## Prepare once while connected

1. Deploy a production build with Jac 0.37.21 over a stable HTTPS origin (localhost is suitable for development). Run `jac install`, then `jac run --no-dev`. Development/HMR mode is not an offline deployment.
2. Sign in and finish your profile. Open **Offline workspace** at `/offline`.
3. Wait for the message that offline app files are cached, enable the device-storage checkbox, and choose **Save my account for offline use**. The cached app files do not include personal account data; the checkbox explicitly permits a readable local copy of workouts, logs and health summaries.
4. Install to the home screen. The manifest now launches `/offline`; an existing installation may need reinstalling to adopt the new launch URL.
5. Export a device backup. The file contains personal fitness data; keep it somewhere appropriate.

After this preparation the laptop can be asleep, switched off, or on another network. The offline workspace uses downloaded code and local browser storage, without API requests for its local operations. Opening or installing a page alone does not download account data. Use the same URL/origin: browser storage and installation belong to that origin.

## Works locally

- View workouts and exercise sets/reps/durations.
- Rate workouts and adapt later unlogged workouts of the same type. Completed workouts remain unchanged. Future workouts cannot be rated.
- Archive the current week and generate subsequent weeks using the same portable Jac schedule rules as the server. Previously selected meal ideas are retained.
- Enter or replace daily activity totals; change the weekly minutes goal; calculate weekly progress and active-day streaks.
- View saved meals, health summary and archived plans.
- Generate current or archived plan PDFs.
- Get the optional three-minute movement-break suggestion from entered sitting time.
- Export and restore a JSON device backup containing the snapshot and local edits.

The local working view includes unsynced changes immediately. They are listed as pending until acknowledged by the server. Server dates and validation still apply at sync time.

## Needs a connection

Initial account setup and download, sign-in, editing profile/preferences, Gemini Coach answers, external recipe/workout videos, live Apple Health sync, and exchanging changes with other devices. There is no on-device AI model or direct browser access to HealthKit. Offline health values are saved summaries, not live measurements.

## Reconnecting

Choose **Sync drafts** while signed in to the original account. Network availability alone does not prove the server is reachable. Each change has an expected base value; if the server differs, syncing stops and keeps the draft. A full plan (including offline-created weeks) is compared as one change. Review/export a conflicting draft before discarding it; then refresh to use server data. No automatic background replay or silent last-writer-wins occurs.

Retries recognize already-applied values. Acknowledged changes are saved into the device snapshot before proceeding, so interrupted replay retains the locally visible result. Server replay checks the authenticated account, revalidates dates/ranges/plans, and protects completed workouts. Mutations share a reentrant process lock; this targets the existing single-process Jac server. A multi-worker/distributed deployment needs database-level concurrency control before relying on the same guarantee across workers.

## Storage and updates

- Device data uses the `stride.offline.v1` localStorage envelope; authentication tokens are not copied into it. The offline page intentionally works without a live auth check after explicit opt-in.
- Anyone using this browser can read the saved copy. **Erase device copy** removes it and unsynced drafts. Logging out removes it too, with confirmation if drafts are pending. Clearing server data through the dashboard also clears that browser's copy. Copies on other offline devices cannot be remotely erased while disconnected.
- Storage can fill or be evicted. Private browsing, clearing site data, removing an app, or changing the deployment origin may lose access to the copy. Export backups; do not treat browser storage as a guaranteed permanent backup.
- Restoring a backup replaces local state, not server data. Sync still requires the original account.
- A generated Workbox worker caches only public JS/CSS/fonts and the anonymous app shell. It does not cache API responses, credentials, or health endpoints. Personal snapshots are stored only by the explicit save action.
- Updates wait rather than forcibly reloading an open editing session. When an update is ready, save drafts, close all Stride tabs/windows, and reopen while connected.

## Implementation

`planning_rules.jac` contains the unchanged portable schedule/profile/catalog rules extracted from `planner.jac`. `components/offline_planner.jac` handles browser calendar arithmetic, local adaptation, next-week state and activity summaries. `services/offline.jac` provides authenticated snapshot and conditional replay endpoints. `OfflineApp.jac` renders the independent offline workspace; `offline_store.jac` handles device copies and backups. Vite PWA generates the service worker from TOML configuration; no handwritten JavaScript worker was added.

LiteLLM/OpenAI are pinned to 1.106.0/2.20.0 because newer resolved dependencies brought an HTTP client that failed compilation with the project's Jac 0.37.21. The PWA build dependency is pinned to 1.2.0.

## Verification

On 2026-11-09, the production build was tested in the desktop in-app browser, including a 390-pixel mobile viewport. With the local Jac hosting process stopped, `/offline` reloaded successfully; activity and goal drafts, workout feedback and next-week generation survived another reload. Restarting the host and choosing Sync drafts applied all three queued changes and returned the pending count to zero. The final cached build also reloaded with the host stopped, displayed archived history and exported a plan PDF. Physical iPhone/Android installation and browser-storage eviction have not been tested.
