# Stride coach — Phases 1–3

Standalone Jac app on `codex/photo-coach`. It does not import or modify the root, dev, or calorie-calculator app.

## Run

Use **Jac 0.37.21** (`jac --version`). From this folder:

```sh
jac install
jac run --show
jac run --no-dev
```

Open the local URL printed by Jac (port 8400, UI and API together). Bare `jac run` also runs the app, but Jac 0.37.21's development launcher adds an unconditional Vite `--host` flag, overriding `[client.vite.server].host`. **Use `jac run --no-dev` for photos**; do not use the development server with personal photos. This is an upstream launcher limitation, not fixed by changing `[serve].host`. Choose another unused port if needed. Do not use `--takeover` or stop another feature's server.

Jac 0.37.21 expects `entry-point = "main"`, a dotted module name. The machine's existing 0.37.11 binary is older and is not the supported runtime. Verification used a checksum-verified official 0.37.21 binary in `/tmp`, without replacing the installed compiler.

## Delivered

- Manual region, goal, experience, equipment, weekdays, duration, local date/timezone, and movement notes, checked by the server.
- Optional file upload and user-triggered camera capture; denied/unavailable camera messaging, close/cancel/retake controls, track cleanup and stale-response guards.
- Sanitized preview, adjustable crop, restore, replace and remove.
- JPEG/PNG/WebP only; actual bytes must match MIME. Maximum 10 MiB, 16 MP, 8192 px per side; minimum 32 px per side. Animated images are rejected.
- EXIF orientation applied, metadata discarded, output reduced to at most 1600 px per side and encoded as JPEG. Transparent pixels are composited on white.
- Optional live photo observations: visible regions, framing, pose and usability, followed by user confirmation. Self-reported activity days and experience describe the starting point; photos do not measure fitness or health.
- Goal example illustrations and an Other dialogue: local/API text refinement updates a structured goal and SVG picture. Manual controls work without inference. Pictures show activity emphasis, not a predicted physique.
- A training-balance reminder when requested upper/lower emphasis differs by at least two levels. This transparent preference heuristic is not a medical risk threshold or a judgment about body proportions.

## Privacy and scope

This is an **ephemeral local single-user prototype**, not a shared deployment. Both frontend and API must bind to loopback. The server sanitizes images in memory and returns them to the requesting browser. This app does not write photos to disk, graph storage, browser storage or public assets. Analysis sends sanitized pixels to the configured model only after the user requests it; API mode additionally requires the UI consent checkbox and discloses the destination. Provider retention policies apply. Previews use data URLs. Remove/reload clears UI references; garbage collection is not secure erasure. In-flight inference may finish after removal, but cannot restore the preview or its observations. There is no media listing/retrieval endpoint or persistent media owner record yet.

The 0.37.21 generated photo endpoint is conservatively classified as a writer/unknown effect and therefore bypasses Jac's reader response cache. Recheck this behavior when changing the endpoint or upgrading Jac.

Preferences remain in memory and reset on reload. Confirmation validates preferences; it does not create a plan. Reviewed exercises and progress calendars belong to later phases. Live model smoke checks are documented in the test notes; broad real-person recognition accuracy and medical assessment are not established.

Before enabling shared hosting or persisted photos, introduce authenticated ownership and retention/deletion controls. Jac's development runtime includes its standard admin services; do not expose this prototype to the network.

## Check

```sh
jac check --nowarn *.jac
jac test --jobs 0 coach_tests.jac phase3_tests.jac
# Optional synthetic browser fixtures in /tmp (no personal data):
jac test --jobs 0 browser_fixture.jac
```

Browser fixture: `/tmp/stride-coach-fixture.png`; invalid fixture: `/tmp/stride-coach-invalid.png`. Test manual submission, invalid timezone, upload, crop via keyboard sliders, restore, corrupt-file rejection, remove and reload. Real camera permission/capture and mobile-device testing remain manual acceptance checks; the lifecycle helper tests use fake tracks, not a hardware camera.

## Extend

## Model configuration

Default local test mode uses Ollama on `127.0.0.1:11434`:

```sh
ollama pull gemma3:4b
ollama pull qwen3:1.7b
# Start ollama serve if the Ollama app/service is not already running.
export COACH_PROVIDER=ollama
export COACH_VISION_MODEL=gemma3:4b
export COACH_TEXT_MODEL=qwen3:1.7b
jac run --no-dev
# Explicit live smoke check (synthetic image only):
jac test --jobs 0 phase3_live.jac
```

For the future API project, set these **server environment** variables before starting the same app; frontend code does not change:

```sh
export COACH_PROVIDER=openai
export COACH_API_BASE=https://api.openai.com/v1
export COACH_API_MODEL=YOUR_VISION_AND_STRUCTURED_OUTPUT_MODEL
# Set COACH_API_KEY securely in your shell or deployment secret manager.
jac run --no-dev
```

The adapter uses HTTPS Chat Completions, image data URLs, strict JSON Schema, `store:false` and `max_completion_tokens`. An alternative API base must support those fields and a vision-capable model; arbitrary providers are not automatically compatible. Secrets never enter client state or request bodies. Destination/model changes invalidate the displayed consent token. Transport rejects redirects, non-200 responses, oversized bodies, refusal, incomplete output and invalid schema; it never silently switches provider. Timeout is 90 seconds. Unavailable analysis leaves manual controls available. Local vision capability is checked before transmitting pixels to the model.

API transport and schema behavior are covered by offline mocks; a live paid API call still requires a configured credential/model and deployment verification. Do not expose this unauthenticated prototype publicly merely by selecting API mode. Keep model/provider logging and retention appropriate for photos.

Protocol references: [Ollama vision](https://docs.ollama.com/capabilities/vision), [Ollama structured output](https://docs.ollama.com/capabilities/structured-outputs), [OpenAI image inputs](https://developers.openai.com/api/docs/guides/images-vision?api-mode=chat), [OpenAI structured output](https://developers.openai.com/api/docs/guides/structured-outputs?api-mode=chat). The whole-body training reminder references [CDC adult activity guidance](https://www.cdc.gov/physical-activity-basics/guidelines/adults.html); its two-level UI threshold is our preference heuristic, not a CDC medical rule.

## Extension boundaries

`coach_profile.jac` owns the typed profile and authoritative validation; `coach_media.jac` owns image normalization; `capture_ui.jac` owns browser media lifecycle; `coach_ui.jac` owns the preference form. Register future server endpoints explicitly in `main.jac`. Reuse this app and these boundaries for recognition and calendar work rather than copying the app. Add persistent records only when their ownership and migration rules are implemented.

`coach_provider.jac` owns transport/configuration; `coach_vision.jac` and `coach_goals.jac` validate finite model contracts; `vision_ui.jac` and `goal_ui.jac` own confirmation and editable previews. Add providers at the transport boundary without coupling them to camera or calendar state.

Phase notes are in `../agent_note/`. Only two planned feature branches: `codex/photo-coach` (0–4) and `codex/progress-canvas` (5–7).
