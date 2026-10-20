# Stride — Personalized Fitness Trainer

EECS 449 · Group 10 · Team CHARS. Team members: Riva Lan, Clarissa Man, Han Sun, Atharva Geete, and Sawda Mim.

The five-feature MVP is a full-stack **Jac** web app. The UI, server planning rules, RPC functions, and tests are authored in Jac. Jac generates the browser JavaScript and transport code; CSS supplies the visual styling. No handwritten JavaScript application or separate Node server is required.

## One-time prerequisite

Install the official **Jac 0.37.21** native binary. This project pins that release because the 0.37.23 macOS ARM64 binary failed to create its dependency environment during validation. Use the stock binary, without `--jacpython`.

```sh
curl -fsSL https://raw.githubusercontent.com/jaseci-labs/jaseci/main/scripts/install.sh | bash -s -- --version 0.37.21
export PATH="$HOME/.local/bin:$PATH"
jac --version
```

The pinned release provides Apple Silicon macOS and Linux x86_64/ARM64 binaries. On Windows, use WSL2 with Linux; for Intel Macs, use a supported Linux environment. The binary bundles the compiler and runtimes. Separate Python, pip, Node, npm, or API-key setup is unnecessary. Internet access is needed for the initial dependency/runtime downloads. See the [official installation documentation](https://jaclang.org/docs/latest/quick-guide/install/) and [release assets](https://github.com/jaseci-labs/jac/releases/tag/v0.37.21).

## Install and run

Clone the onboarding branch, which includes the Apple Health iOS sync feature:

```sh
git clone --branch feature/data-setup-onboarding https://github.com/angeete08/MDE449Project.git
cd MDE449Project
jac install
jac run
```

From an existing checkout of that branch, the complete workflow is:

```sh
jac install
jac run
```

Open **http://localhost:8000**. `jac run` reads the web-app entry point from `jac.toml`, compiles the client and server, and starts both with live reload. The API runs on port 8001. The first launch also provisions Jac's embedded PostgreSQL runtime; allow it to finish. Stop everything with **Ctrl+C**. No second terminal or separate frontend command is needed. If a port is occupied, stop the other app or use `jac run --port 8100` (API on 8101).

`jac install` installs the declared project dependencies into `.jac/` and the generated client dependency tree. Generated files and dependency folders are ignored by Git. Run commands from the repository root, not its parent directory.

### Troubleshooting

If `jac install` reports `ensurepip is not available`, or `jac run` reports `missing frontend packages` such as `vite`, `jspdf` or `qrcode`, install the frontend dependencies manually.

These steps require Node.js and npm. Stop the running app with Ctrl+C, then run the following from the project root:

```sh
cp .jac/client/configs/package.json .jac/client/package.json
npm install --prefix .jac/client --include=dev
npm install --prefix .jac/client jspdf@4.2.1 qrcode@1.5.4 --save --include=dev
```

Confirm that the packages are installed:

```sh
npm ls --prefix .jac/client jspdf qrcode vite
```

If they all appear, start the app again:

```sh
jac run
```

## Features

| Feature                  | MVP behavior                                                                                                                                                                                                                                |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Personal fitness profile | Goal, experience, 1–6 workout days, bodyweight/dumbbells/full gym, diet, calorie target, and optional weekly averages for steps, heart rate, sleep and workouts. The server validates inputs; these averages are captured but do not yet change recommendations. |
| Weekly workout plan      | Seven days with the requested workout count, matching equipment, strength sets/reps or cardio minutes, and rest days. Experience sets the number of sets; goal changes the strength/cardio mix.                                             |
| Daily calorie goal       | Displays a whole-number target entered by the user beside the plan. It does not calculate calorie needs or a deficit.                                                                                                                       |
| Meal suggestions         | First launch shows three starter recipes without form input: overnight oats, chicken grain bowl and bean vegetable tacos. Creating a plan replaces them with three ideas selected for the diet and approximate per-meal calorie range. Recipe video links and thumbnails use a local catalog, without paid API calls. These are not a complete daily menu. |
| Demo account             | A shared single-user account with editable display name, server-saved plans and workout feedback, synthetic health test connection, sign-out and reset. No external provider credentials are needed. |
| Workout feedback         | One rating per workout: too easy, just right, or too hard. Easy/hard changes future unlogged strength repetitions by one or cardio duration by two minutes. Current, past, and already logged workouts stay fixed; adjustments are bounded. |

First launch opens directly to starter recipes; no onboarding answers or inputs in **Make it yours** are required. A workout plan is optional and still requires a user-chosen calorie target. **Data settings** opens the data-source and browser-storage choices. Apple Health works through the Stride Health iPhone app (see below). Health Connect, Oura, Fitbit, Garmin Connect, WHOOP and Strava remain labeled previews.

### Single-user demo account

1. Click **Account**, then **Open demo account & enable server saving**. This explicitly enables server saving; it does not upload an existing guest/browser plan.
2. Edit the display name or click **Sync test data**. The server returns clearly labeled synthetic averages: 7,200 daily steps, 72 bpm, 7.5 hours sleep and 3 workouts/week. No wearable, mobile app, API key or paid service is required for this test connection. It is separate from real Apple Health sync.
3. Review the form, enter your chosen calorie target, and create a week. Plans, archived weeks and feedback save to the demo account. Refresh or reconnect to restore them.
4. **Sign out** revokes this session but keeps server data. **Reset demo account** confirms deletion of the saved plan, history, test summary and display name. **Clear browser data** only clears browser saves and preferences.

The account is intentionally shared by everyone using this local server, with a fixed `demo@stride.local` label, no password, no public signup, and no email delivery. It is a demonstration of account management, not production authentication. Sessions use random server-validated tokens kept in `sessionStorage`, expire after 12 hours, and end on a server restart. Account data persists in `.jac/stride-demo.sqlite3` (ignored by Git); set `STRIDE_DEMO_DB` to use another local path. Run one server process and use synthetic data for this shared account. Public multi-user deployment would require individual authentication and account isolation.

### Apple Health sync

When Apple Health is chosen, the weekly averages section shows **Send sync request to iPhone**. Stride creates a one-time request and shows a QR code and link. On an iPhone with the [Stride Health companion app](ios/StrideHealth/README.md) installed, scanning the code opens the app. The person confirms the server address, and Apple Health asks which of steps, heart rate, sleep and workouts to share. The app then uploads the last 28 days through the open-source [Open Wearables iOS SDK](https://github.com/the-momentum/open_wearables_ios_sdk). The Jac server reduces the samples to the four weekly averages, and the web page fills them in for review. The calorie target is never filled from Apple Health.

The iPhone must be on the same Wi-Fi as the computer running `jac run`. The development server already accepts network connections on port 8000 and forwards `/api` and `/function` calls to the Jac API. Requests and running totals are kept only in server memory and expire after 15 minutes without activity; raw samples are not stored. This needs a single server process.

In guest mode, allowing browser storage saves the profile, current week, archived weeks and feedback in `localStorage` (`stride-jac-v2`, with migration from `stride-jac-v1`) and data choices in `stride-data-prefs-v1`. Declining removes earlier browser saves; guest plans then last only in the current page. Browser storage and server account saving are separate choices. Refresh restores a server-validated copy. **Download PDF** exports the selected week; creating the next week archives the current week and retains its feedback. Browser storage is specific to this browser and origin.

## Source and validation

- `main.jac`: web-app entry point and imports.
- `frontend.jac`: reactive form, weekly cards, meals, feedback, saving and download.
- `accounts.jac`: demo sessions, SQLite account storage, validated plan saves, starter recipes and synthetic health test connection.
- `account_tests.jac`: account persistence, reset, expiry, sign-out and invalid-input checks using a temporary database.
- `onboarding.jac`: first-visit data setup dialog (data source, storage consent, app connection preview).
- `planner.jac`: validation and deterministic planning; public `create_plan`, `submit_feedback`, and `restore_plan` functions become Jac RPC endpoints.
- `health_sync.jac`: Apple Health sync requests, the Open Wearables SDK upload endpoints (`/api/v1/sdk/users/{id}/sync` and `/logs`) and the weekly-average summary.
- `health_panel.jac`: the Apple Health panel with the QR code and status polling.
- `health_sync_tests.jac`: summary de-duplication, time zones, missing data, phone address and request lifecycle tests.
- `ios/StrideHealth/`: the Stride Health SwiftUI companion app (the only non-Jac application code, because HealthKit needs a native iOS app). See its README for building with Xcode.
- `planner_tests.jac`: all 648 profile combinations, feedback direction/bounds, completed-workout preservation, invalid input rejection and saved-state restoration.
- `global.css`: responsive visual styling.
- `jac.toml`: compiler pin, project entry point, dependencies, ports and test discovery.

```sh
jac check
jac test
```

Validation on October 19: `jac check` passes (dynamic JSON boundary warnings remain); all 21 tests pass. Browser checks cover first-launch starter recipes without input, demo account connection and rename, synthetic sync, plan creation, feedback, refresh restoration, sign-out, optional onboarding and Apple Health QR-request creation. The account tests cover reset, expired/revoked sessions, server persistence and invalid input. A physical iPhone HealthKit transfer, Linux/WSL execution and teammate usability review were not verified in this pass. See [DEMO.md](DEMO.md) for the two-minute readout and [FLOWLINE.md](FLOWLINE.md) for earlier handoff context.

## Scope and next steps

Planning uses deterministic rules and curated meal examples, with Codex-assisted development. Apple Health is the only real health integration, through the iOS companion app; other wearables are not connected. The demo account also offers synthetic server test data. There is no live LLM, camera analysis, location search or production multi-user authentication. Health averages populate the form but do not yet change planning recommendations. The demo account persists validated planning state in its local SQLite database; guest plans use optional browser storage. Jac's framework also initializes its own runtime database.

Next: teammate PR review and a short usability session, then agree on a grounded model feature and oversight rules. This Jac prototype can be run from the repository. It requires a Jac server and cannot be replaced by uploading static files to that host.
