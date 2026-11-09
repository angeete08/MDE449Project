# Stride — Personalized Fitness Trainer

**University of Michigan · EECS 449 · Group 10 · Team CHARS**  
Riva Lan, Clarissa Man, Han Sun, Atharva Geete, and Sawda Mim

Stride is a fitness-planning web application that creates personalized weekly workouts, suggests meals, tracks activity, and offers a conversational AI fitness coach. Its main interface is built with Jac/JacHammer, and an optional native iOS companion connects Apple Health data to the web application.

> **Project status:** Working course prototype. Workout planning is rule-based; the Coach uses Google Gemini. Some integrations require additional setup, and certain advanced fitness features are not implemented.

## Quick start

### Requirements

- A working Jac installation compatible with **Jac 0.37.21** (pinned in `jac.toml`).
- Internet access for initial dependency installation.
- Node.js and npm if manual frontend dependency installation is necessary.
- Optional: a Google Gemini API key for Coach and meal photo analysis.
- Optional: a Mac with Xcode and an iPhone for native Apple Health syncing.

### 1. Clone and install

```bash
git clone --branch review/coach-and-current-week https://github.com/angeete08/MDE449Project.git
cd MDE449Project
jac install
```

### 2. Configure the AI Coach (optional)

Get an API key from [Google AI Studio](https://aistudio.google.com/apikey). Create a `.env` file in the repository root:

```dotenv
GOOGLE_API_KEY=your_google_api_key_here
```

Keep the key private; do not commit `.env`. The rest of Stride works without a Gemini key, but Coach replies and meal photo estimates require it. API access, model availability, rate limits, and billing depend on your Google account and Google's current terms.

### 3. Start the application

```bash
jac run
```

Open **http://localhost:8000** in your browser. The API normally runs on port **8001**.

1. Create an account or sign in.
2. Complete the four-step onboarding flow and consent to account data storage.
3. Choose your goal, experience level, equipment, diet, and daily calorie target.
4. Open the dashboard to explore your workout plan, meals, progress, Coach, and health settings.

Stop the server with `Ctrl+C`. To use another web port, run `jac run --port 8010` (API normally on 8011).

**If the frontend dependency installer stalls:** Stop the running installer first, then run:

```bash
cp .jac/client/configs/package.json .jac/client/package.json
npm install --prefix .jac/client --include=dev
jac run
```

Do not run two installers simultaneously.

## Features

| Dashboard section | What it does                                                                                                                                                                  |
| ----------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Today**         | Shows today's scheduled workout and manually logged activity; lets you set a weekly active-minutes goal and request an optional movement break based on entered sitting time. |
| **Coach**         | Uses Google Gemini to answer general fitness questions and questions about your saved fitness preferences and scheduled workouts.                                             |
| **Plan**          | Shows a seven-day workout schedule, exercise details, tutorial searches, difficulty feedback, a next-week preview, and a downloadable PDF.                                    |
| **Meals** | Tracks intake against your daily target, completed activities, logged calories burned and signed energy balance. Includes meal ideas and manual food logging. |
| **Got your nutritions?** | Drop or choose up to ten food photos per day, review Gemini’s nutrient and portion estimates, and add selected foods to Meals. |
| **Progress**      | Lets you add or edit daily steps, calories burned, running distance, and active minutes; shows weekly totals and activity streaks.                                            |
| **Health**        | Accepts optional manual averages or a 28-day Apple Health summary through the iOS companion.                                                                                  |
| **History**       | Displays saved previous weeks, including workouts, exercise amounts, and recorded feedback.                                                                                   |

### Workout planning and weekly navigation

- The planner uses explicit rules, not Gemini, to generate exercises and meals.
- Plans depend on the selected goal, experience, workout frequency, equipment, and diet.
- Workout feedback (`Too easy`, `Just right`, or `Too hard`) can adjust **later, unlogged workouts of the same type**. Already completed workouts are preserved.
- **Open / generate this week** resolves the browser's current calendar week. It restores a saved plan for that week when available or generates one if missing. It does not generate every skipped week.
- **Preview next week** is read-only: it does not save a new plan or replace the current one.
- Previous and future saved weeks are retained during calendar navigation; archived ratings and exercise amounts are preserved.
- Profile edits affect newly generated weeks, not previously saved workouts.
- The dashboard does **not** automatically advance the saved workout plan when the calendar changes. Use **Open / generate this week** to refresh it.

### AI Coach

The Coach uses **Gemini 3.1 Flash-Lite** through LiteLLM. For certain service-unavailable or timeout errors, it retries with **Gemini 3.6 Flash**. It can discuss general fitness and limited Stride context such as goals, experience, equipment, diet, and scheduled workout titles.

Important limitations:

- The Coach does **not** edit your plan, activity logs, or profile.
- It is informational, not a medical professional or a substitute for individualized medical advice.
- Its workout context comes from the **currently saved plan**, which may be for an earlier week until you open/generate the current week.
- Recent conversation history is sent with new questions, but chat messages are not saved to your Stride account.
- Questions, recent chat history, and limited fitness preferences are sent to Google for response generation. Stored health notes and imported health summaries are not included automatically. Avoid putting sensitive medical information in chat messages.

### Meals and activity tracking

Meal suggestions are curated examples, not a complete daily nutrition plan. Calories are approximate, and linked videos may use different ingredients or portions. **Daily calorie targets are entered by the user**; Stride does not calculate or prescribe them automatically.

Activity totals are entered manually. Saving a second log for the same date replaces that date's totals. Weekly progress counts logged active minutes from Monday through the browser's current local date. Workout difficulty feedback and activity logs are separate: rating a workout does not automatically add active minutes.

## Apple Health integration (optional)

The Stride web app cannot access Apple Health directly. The native **Stride Health** iOS companion reads permitted HealthKit data and sends samples to the Jac server, which computes a **28-day summary** containing up to four averages:

- Average daily steps
- Average heart rate
- Average sleep hours
- Average workouts per week

Unavailable metrics remain blank. Syncing a new summary replaces the previous summary; it does not create daily activity logs or automatically change workout difficulty.

### iPhone setup and sync

1. Follow the [iOS companion setup guide](ios/StrideHealth/README.md) to build and install the app using Xcode.
2. Connect the iPhone and computer to the same trusted local network. Campus or guest Wi-Fi may block device-to-device connections.
3. Start the web server with LAN access:

   ```bash
   jac run --host 0.0.0.0
   ```

4. On the computer, open Stride using its **LAN IP address**, such as `http://192.168.1.20:8000`, rather than `localhost`. Replace the example IP with your computer's actual address.
5. Sign in, go to **Health**, and select **Send sync request to iPhone**.
6. Scan the QR code with the iPhone or open the generated link. Confirm the destination server and grant the requested Apple Health permissions.
7. Keep the companion app open until the transfer finishes. Return to Stride and review the imported summary.

**Security note:** `0.0.0.0` makes the development server reachable on available network interfaces. Use it only on a trusted network, do not expose it directly to the public internet, and treat one-time sync links as private. The relay processes raw samples in memory until aggregation or expiration; the account stores the resulting summary, not a permanent raw-sample history.

**Accuracy note:** Health averages are approximate and may differ from Apple's Health app, particularly when multiple devices contribute overlapping measurements. A full physical-device sync has not been verified in the documentation for this branch.

See also the [iPhone testing guide](test/stride-iphone-healthkit-testing-guide.pdf).

## Accounts, privacy, and data

- The main dashboard uses Jac authentication and per-account graph storage for profiles, plans, history, activity logs, and optional health summaries.
- Protected account endpoints require authentication; one account should not be able to read another account's saved data.
- Logging out does not delete saved data.
- **Health → Delete saved Stride data** removes the saved Stride profile, plan history, activity logs, and health summary after confirmation. The login account remains.
- Earlier browser-storage and shared-demo implementations remain in the repository for reference. Their data is **not automatically migrated** into the authenticated dashboard.
- Health-condition notes can be stored as profile data, but the rule-based planner does not interpret them.

This is a course prototype, not a production-hardened health-data service. Do not use real sensitive health information for public demos.

## Testing

Run the project's static checks and automated tests from the repository root:

```bash
jac check
jac test
```

The test suite includes coverage for planning rules, workout feedback, calendar-week navigation, activity validation, coach conversation history, mocked Gemini responses, and authenticated account behavior. The existence of tests does not guarantee that a particular checkout or physical-device integration has passed; run them in your environment before the demo.

### Suggested manual demo checklist

1. Register, sign in, and complete onboarding.
2. Confirm a seven-day plan contains the selected number of workouts and appropriate rest days.
3. Rate a completed workout; verify only eligible later workouts change.
4. Preview next week; confirm the current plan remains unchanged.
5. Open/generate the current week and inspect saved history.
6. Save an activity log, edit it, refresh, and verify the replacement persisted.
7. Download the plan PDF and open meal recipe links.
8. Ask the Coach a question (requires a configured Gemini key).
9. Sign in to a second account and verify account isolation.
10. If an iPhone is available, test Apple Health syncing separately on a trusted local network.

Previous browser integration notes: [docs/jachammer-integration.md](docs/jachammer-integration.md).

## Current limitations and planned work

**Not currently implemented:** biometric readiness/recovery scoring, automatic plan changes based on heart rate or sleep, automatic calorie prescriptions, friends sharing, and automatic weekly catch-up volume changes. The original all-account scoreboard is disabled pending a consent-based sharing design. Other wearable choices in onboarding indicate interest; they are **not live integrations**.

The Apple Health sync contract exposes only the four averages listed above, not detailed HRV, resting-heart-rate baselines, daily sleep trends, stand time, or exercise-energy trends.

## Repository structure

| Path                                             | Purpose                                                                                       |
| ------------------------------------------------ | --------------------------------------------------------------------------------------------- |
| `main.jac`                                       | Application routes and endpoint registration                                                  |
| `components/`                                    | Main dashboard, authentication UI, onboarding, Coach, and reusable interface components       |
| `services/stride.jac`                            | Authenticated account data, dashboard endpoints, activity logic, and Gemini Coach integration |
| `planner.jac`                                    | Rule-based weekly workout and meal planning, feedback adaptation, and calendar navigation     |
| `pdf_export.jac`                                 | Plan PDF generation                                                                           |
| `health_sync.jac`, `health_panel.jac`            | Apple Health relay endpoints and web sync interface                                           |
| `ios/StrideHealth/`                              | Native Swift/HealthKit companion application                                                  |
| `styles/`, `lib/`                                | UI styling and supporting utilities                                                           |
| `*_tests.jac`                                    | Automated tests                                                                               |
| `frontend.jac`, `onboarding.jac`, `accounts.jac` | Earlier prototype code retained for reference                                                 |
| `docs/`                                          | Integration notes and project documentation                                                   |

The main web application and its tests use Jac; styling and configuration use CSS/TOML, and the native iOS companion is written in Swift.

---

**Scope reminder:** Stride provides general fitness planning and tracking for an academic project. It does not diagnose conditions, prescribe medical treatment, or guarantee health outcomes.
