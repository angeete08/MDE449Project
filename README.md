# Stride — Personalized Fitness Trainer

**University of Michigan · EECS 449 · Group 10 · Team CHARS**  
Riva Lan, Clarissa Man, Han Sun, Atharva Geete, and Sawda Mim

Stride is a fitness-planning web application that creates personalized weekly workouts, suggests meals, tracks activity, and offers a conversational AI fitness coach. Its main interface is built with Jac/JacHammer.

> **Project status:** Working course prototype. Workout planning is rule-based; the Coach uses Google Gemini. Some integrations require additional setup, and certain advanced fitness features are not implemented.

The combined online/mobile/offline application is on `dev`, `feature/mobile-app`, and `feature/mobile-mini-app`. See the [November 11 integration notes](docs/nov11-integration.md) for feature boundaries, branch cleanup, and verification. Use `jac run --no-dev` when preparing an offline installation.

## Quick start

### Requirements

- A working Jac installation compatible with **Jac 0.37.21** (pinned in `jac.toml`).
- Internet access for initial dependency installation.
- Node.js and npm if manual frontend dependency installation is necessary.
- Optional: a Google Gemini API key for Coach and meal photo analysis.

### 1. Clone and install

```bash
git clone --branch dev https://github.com/angeete08/MDE449Project.git
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
| **History**       | Displays saved previous weeks, including workouts, exercise amounts, and recorded feedback. **Your saved data** deletes your saved Stride data.                               |

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
- Questions, recent chat history, and limited fitness preferences are sent to Google for response generation. Stored health notes are not included automatically. Avoid putting sensitive medical information in chat messages.

### Meals and activity tracking

Meal suggestions are curated examples, not a complete daily nutrition plan. Calories are approximate, and linked videos may use different ingredients or portions. **Daily calorie targets are entered by the user**; Stride does not calculate or prescribe them automatically.

Activity totals are entered manually. Saving a second log for the same date replaces that date's totals. Weekly progress counts logged active minutes from Monday through the browser's current local date. Workout difficulty feedback and activity logs are separate: rating a workout does not automatically add active minutes.

## Retired: Apple Health sync

The Apple Health integration (a Swift iOS companion app plus a Jac relay that turned 28 days of HealthKit samples into four averages) was removed from the main app. Users had to build the companion in Xcode, keep the iPhone on the same Wi-Fi as the server, and pair it by QR code, while the imported averages did not change plans or Coach replies. The complete implementation, iPhone screenshots and testing guide are preserved on the `archive/apple-health-sync` branch.

## Accounts, privacy, and data

- The main dashboard uses Jac authentication and per-account graph storage for profiles, plans, history, food entries and activity logs.
- Protected account endpoints require authentication; one account should not be able to read another account's saved data.
- Logging out does not delete saved data.
- **History → Delete saved Stride data** removes the saved Stride profile, plan history, food entries and activity logs after confirmation. The login account remains.
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

Previous browser integration notes: [docs/jachammer-integration.md](docs/jachammer-integration.md).

## Current limitations and planned work

**Not currently implemented:** biometric readiness/recovery scoring, automatic plan changes based on heart rate or sleep, automatic calorie prescriptions, friends sharing, and automatic weekly catch-up volume changes. The original all-account scoreboard is disabled pending a consent-based sharing design. Other wearable choices in onboarding indicate interest; they are **not live integrations**.

## Repository structure

| Path                                             | Purpose                                                                                       |
| ------------------------------------------------ | --------------------------------------------------------------------------------------------- |
| `main.jac`                                       | Application routes and endpoint registration                                                  |
| `components/`                                    | Main dashboard, authentication UI, onboarding, Coach, and reusable interface components       |
| `services/stride.jac`                            | Authenticated account data, dashboard endpoints, activity logic, and Gemini Coach integration |
| `planner.jac`                                    | Rule-based weekly workout and meal planning, feedback adaptation, and calendar navigation     |
| `pdf_export.jac`                                 | Plan PDF generation                                                                           |
| `styles/`, `lib/`                                | UI styling and supporting utilities                                                           |
| `*_tests.jac`                                    | Automated tests                                                                               |
| `frontend.jac`, `onboarding.jac`, `accounts.jac` | Earlier prototype code retained for reference                                                 |
| `docs/`                                          | Integration notes and project documentation                                                   |

The application and its tests use Jac; styling and configuration use CSS/TOML.

---

**Scope reminder:** Stride provides general fitness planning and tracking for an academic project. It does not diagnose conditions, prescribe medical treatment, or guarantee health outcomes.

## Mobile mini app

Open `/mobile` for the phone layout. The same account and backend power phone and desktop. For home-screen installation, serve Stride over HTTPS; on iPhone use Safari → Share → Add to Home Screen, or on Android use Chrome → Add to home screen / Install app. After saving a device copy, the offline workspace supports local planning, feedback, activity tracking, goals, history and PDF export even when the server is unreachable. Coach and live health sync still need a connection. See [offline preparation, supported features and sync rules](docs/offline-use.md). See [mobile setup, architecture and verification](docs/mobile-mini-app.md).


## Photo and goal studio (Phase 3)

The authenticated Coach tab now also contains optional camera/upload previews, tentative body-region observations and editable goal illustrations with an Other dialogue. These temporary choices do not modify saved workouts or offline history. The studio can use local Ollama for testing or a configured HTTPS API; the existing Gemini conversation retains its separate configuration. See [coach setup, privacy and verification](coach/README.md). Use `jac run --no-dev` for photo testing on loopback. Reviewed exercises and the progress calendar remain later phases.
