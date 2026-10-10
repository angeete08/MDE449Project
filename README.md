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

Until the PR is merged, clone its feature branch:

```sh
git clone --branch feat/jac-fitness-mvp https://github.com/angeete08/MDE449Project.git
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

If `jac install` reports `ensurepip is not available`, or `jac run` reports `missing frontend packages` such as `vite` or `jspdf`, install the frontend dependencies manually.

These steps require Node.js and npm. Stop the running app with Ctrl+C, then run the following from the project root:

```sh
cp .jac/client/configs/package.json .jac/client/package.json
npm install --prefix .jac/client --include=dev
npm install --prefix .jac/client jspdf@4.2.1 --save --include=dev
```

Confirm that both packages are installed:

```sh
npm ls --prefix .jac/client jspdf vite
```

If both appear, start the app again:

```sh
jac run
```

## Features

| Feature                  | MVP behavior                                                                                                                                                                                                                                |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Personal fitness profile | Goal, experience, 1–6 workout days, bodyweight/dumbbells/full gym, and no restriction/vegetarian/keto/high-protein diet. The server validates inputs.                                                                                       |
| Weekly workout plan      | Seven days with the requested workout count, matching equipment, strength sets/reps or cardio minutes, and rest days. Experience sets the number of sets; goal changes the strength/cardio mix.                                             |
| Daily calorie goal       | Displays a whole-number target entered by the user beside the plan. It does not calculate calorie needs or a deficit.                                                                                                                       |
| Meal suggestions         | Three randomized, research-informed ideas selected for the diet preference and approximate per-meal calorie range. Each has a researched YouTube recipe thumbnail. They are not a complete daily menu.                                    |
| Workout feedback         | One rating per workout: too easy, just right, or too hard. Easy/hard changes future unlogged strength repetitions by one or cardio duration by two minutes. Current, past, and already logged workouts stay fixed; adjustments are bounded. |

The browser saves the profile, week and feedback in `localStorage` (`stride-jac-v1`). Refresh restores a server-validated copy. Download exports JSON; Clear saved data removes it. Creating a new week resets feedback. Storage is specific to this browser and origin.

## Source and validation

- `main.jac`: web-app entry point and imports.
- `frontend.jac`: reactive form, weekly cards, meals, feedback, saving and download.
- `planner.jac`: validation and deterministic planning; public `create_plan`, `submit_feedback`, and `restore_plan` functions become Jac RPC endpoints.
- `planner_tests.jac`: five Jac test blocks, including all 648 profile combinations, feedback direction/bounds, completed-workout preservation, invalid input rejection and saved-state restoration.
- `global.css`: responsive visual styling.
- `jac.toml`: compiler pin, project entry point, dependencies, ports and test discovery.

```sh
jac check
jac test
```

Validation on October 5: fresh-directory `jac install`, bare `jac run`, compiler check, five passing tests, and browser checks of generation, feedback, refresh, download and equipment/diet changes on Apple Silicon macOS. Dynamic JSON boundary types produce compiler warnings; the compiler reports no errors. Linux/WSL execution and teammate usability review remain to be checked. See [DEMO.md](DEMO.md) for the two-minute readout and [FLOWLINE.md](FLOWLINE.md) for handoff status.

## Scope and next steps

Planning uses deterministic rules and curated meal examples, with Codex-assisted development. There is no live LLM, wearable/health integration, camera analysis, location search, account workflow, or cross-device synchronization. The app sends its saved planning state to the local Jac server for validation and feedback; it does not write fitness profiles into the server database. Jac's framework initializes its own runtime database.

Next: teammate PR review and a short usability session, then agree on a grounded model feature and oversight rules. This Jac prototype can be run from the repository. It requires a Jac server and cannot be replaced by uploading static files to that host.
