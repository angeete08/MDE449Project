# Stride — Personalized Fitness Trainer

EECS 449 · Group 10 · Team CHARS. Riva Lan, Clarissa Man, Han Sun, Atharva Geete, and Sawda Mim.

Stride now uses the team's JacHammer prototype as the main interface: landing page, account sign-in, four-step onboarding and an emerald dashboard. Application code and tests are Jac. CSS and TOML support the UI. The native iOS companion remains Swift.

## Run locally

Use **Jac 0.37.21** (the release pinned in `jac.toml`). From a checkout of this integration branch:

```sh
git clone --branch feature/jachammer-stride-integration https://github.com/angeete08/MDE449Project.git
cd MDE449Project
jac install
jac run
```

Open **http://localhost:8000**. The API runs on 8001. Sign up, sign in, complete onboarding and explicitly enable account storage. Stride Coach uses Google Gemini; create a key in [Google AI Studio](https://aistudio.google.com/apikey) and put `GOOGLE_API_KEY=your-key` in the project-root `.env` file. Gemini API free-tier availability, quotas and limits depend on Google's current terms and account/region. The rest of the app can be used without the key, but Coach replies require it. Initial startup downloads the dependencies and Jac's embedded database runtime. Stop with Ctrl+C. Use `jac run --port 8010` for a different web port (API 8011).

If the bundled frontend installer stalls, stop it before trying npm (requires Node/npm):

```sh
cp .jac/client/configs/package.json .jac/client/package.json
npm install --prefix .jac/client --include=dev
jac run
```

Do not run two dependency installers at once. Generated dependencies, database state and `.env` files are ignored by Git.

## Dashboard features

- **Today:** manually logged daily totals, a user-selected weekly goal in active minutes, current session feedback and an optional three-minute movement break based on sitting time you enter.
- **Coach:** Google Gemini-powered answers about Stride and general fitness guidance. Questions, recent chat history and limited fitness preferences are sent to Google; stored health notes and summaries are excluded. Conversations are not saved to the account. Responses are informational, not medical advice.
- **Plan:** the existing server-validated planner, equipment-specific exercises, YouTube tutorial searches, feedback that adjusts only later unlogged workouts of the same type, and a two-page PDF download. **Create next week** archives the current plan and carries difficulty forward.
- **Meals:** curated diet-specific meal ideas, approximate calories per serving and clickable YouTube recipe thumbnails. Videos can use different ingredients or portions. These ideas are not a complete daily menu and do not add up to your target.
- **Progress:** editable activity totals by date and consecutive active-day streaks. Saving the same date replaces its totals. Weekly totals use Monday through the browser's local current date. Logging workout feedback and logging daily active minutes are separate actions to avoid assuming durations or counting activity twice.
- **Health:** the existing QR-code flow to the [Stride Health iOS companion](ios/StrideHealth/README.md), a saved **Apple Health · 28-day summary**, and optional manual weekly averages. Each sync replaces the prior summary, including unavailable values. Aggregated health averages never become daily log entries. Other wearable selections are interests, not live connections.
- **History:** archived weekly workouts, exact sets/reps/durations and saved ratings.

Profile edits take effect for the next generated week; existing workouts and ratings remain unchanged. Calorie targets are always user-entered. Health-condition notes are stored but the rule-based planner does not interpret them.

## Accounts and data

Jac authentication isolates each account's profile, plan history, logs and optional health summary on its own graph root. An unauthenticated request cannot read an account profile. Logging out keeps saved data. **Health → Delete saved Stride data** removes the profile, history, logs and summary after confirmation, while retaining the sign-in account.

The earlier browser-storage UI, shared demo-account modules and their tests remain in the repository for reference. Existing local-storage or shared-demo data is not automatically migrated into a newly registered account. The main dashboard uses individual accounts.

The iPhone must run the companion app and reach this server on the same Wi-Fi. If necessary use `jac run --host 0.0.0.0` for LAN access. The existing [iPhone testing guide](test/stride-iphone-healthkit-testing-guide.pdf) documents device setup. Raw sync samples stay in the relay's memory only until aggregation/expiry; only the summary is saved to the account.

## Current scope

Planning and coaching here use explicit rules, not a live conversational model. Readiness/recovery scoring, automatic progressive overload from biomarkers, calorie or meal-portion prescriptions from height/weight, friends sharing and weekly catch-up volume changes are deferred. HRV, resting-heart-rate baselines, daily sleep, stand time and exercise-energy trends are not available in the existing four-average sync contract. Friends sharing needs an explicit invitation and consent design; the prototype's all-account scoreboard is disabled.

## Validation

```sh
jac check
jac test
```

Tests cover the original planner and Apple Health relay, dashboard plan adaptation, week boundaries, streaks, movement-break input, activity validation and authenticated account isolation. Browser checks are recorded in `docs/jachammer-integration.md`.

## Structure

- `main.jac`: routes and endpoint registration
- `components/`, `styles/`, `lib/`: JacHammer interface and UI primitives
- `services/stride.jac`: authenticated persistence and dashboard adapter
- `planner.jac`, `pdf_export.jac`: retained planning rules and PDF export
- `health_sync.jac`, `health_panel.jac`, `ios/StrideHealth/`: retained Apple Health bridge
- `frontend.jac`, `onboarding.jac`, `accounts.jac`: earlier UI/demo implementation for reference

The local JacHammer ZIP and jacpack exports remain unchanged. Updated extracted source is also mirrored into `JacHammer Version/personal-fitness-stride/` for continued prototype work.
