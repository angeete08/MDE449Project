# Stride coach — Phases 1–2

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

## Privacy and scope

This is an **ephemeral local single-user prototype**, not a shared deployment. Both frontend and API must bind to loopback. The server sanitizes images in memory and returns them to the requesting browser. No photo is written to disk, graph storage, browser storage, public assets, or external providers. Previews use data URLs, not object URLs. Remove/reload clears the UI references; runtime memory is reclaimed by garbage collection, not secure erasure. In-flight processing can finish after cancellation, but its response cannot restore the preview. There is no media listing/retrieval endpoint and no persistent media owner record yet.

The 0.37.21 generated photo endpoint is conservatively classified as a writer/unknown effect and therefore bypasses Jac's reader response cache. Recheck this behavior when changing the endpoint or upgrading Jac.

Preferences also remain in memory and reset on reload. Confirmation validates preferences; it does not create a plan. Region recognition, exercise prescriptions, illustrations and progress calendars belong to later phases. No live AI or body assessment is implemented.

Before enabling shared hosting or persisted photos, introduce authenticated ownership and retention/deletion controls. Jac's development runtime includes its standard admin services; do not expose this prototype to the network.

## Check

```sh
jac check --nowarn main.jac coach_profile.jac coach_media.jac coach_ui.jac capture_ui.jac camera_lifecycle.jac coach_tests.jac browser_fixture.jac
jac test --jobs 0 coach_tests.jac
# Optional synthetic browser fixtures in /tmp (no personal data):
jac test --jobs 0 browser_fixture.jac
```

Browser fixture: `/tmp/stride-coach-fixture.png`; invalid fixture: `/tmp/stride-coach-invalid.png`. Test manual submission, invalid timezone, upload, crop via keyboard sliders, restore, corrupt-file rejection, remove and reload. Real camera permission/capture and mobile-device testing remain manual acceptance checks; the lifecycle helper tests use fake tracks, not a hardware camera.

## Extend

`coach_profile.jac` owns the typed profile and authoritative validation; `coach_media.jac` owns image normalization; `capture_ui.jac` owns browser media lifecycle; `coach_ui.jac` owns the preference form. Register future server endpoints explicitly in `main.jac`. Reuse this app and these boundaries for recognition and calendar work rather than copying the app. Add persistent records only when their ownership and migration rules are implemented.

Phase notes are in `../agent_note/`. Only two planned feature branches: `codex/photo-coach` (0–4) and `codex/progress-canvas` (5–7).
