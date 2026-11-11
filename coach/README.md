# Photo and goal coach

Integrated into the existing Stride Coach tab in both desktop and mobile dashboards. This folder is a module, not a separate app: run `jac install` and `jac run --no-dev` from the parent `MDE449Project-mobile` folder with Jac 0.37.21. Sign in, complete onboarding and open Coach. Existing Gemini chat remains available above the photo studio.

## Delivered through Phase 3

Optional camera/upload, sanitized preview, crop/restore/remove, tentative visible-region/framing/pose observations, user-confirmed focus, self-reported activity baseline, goal examples, and an Other dialogue with iterative model-assisted or manual picture refinement. SVG illustrations show training emphasis, not predicted bodies. A two-level upper/lower emphasis difference triggers a transparent planning reminder, not a medical risk score. Reviewed exercises and the progress calendar remain later phases.

All five photo/goal endpoints require authentication. Photos and drafts remain ephemeral; nothing is added to the account graph, existing workout history, offline queue or service-worker cache. Model requests happen only on explicit actions. API mode discloses its destination and requires a checkbox before photo or goal-text submission. Removal invalidates the UI result but cannot undo an already-sent request. Provider retention policies apply.

Image limits: JPEG/PNG/WebP, 10 MiB, 16 MP, dimensions 32–8192; normalized to metadata-free JPEG at most 1600 px per side. Neither photos nor generated observations establish body fat, fitness, injury or healthy body proportions.

## Local test model

Start Ollama locally if it is not already running, then:

```sh
ollama pull gemma3:4b
ollama pull qwen3:1.7b
export COACH_PROVIDER=ollama
export COACH_VISION_MODEL=gemma3:4b
export COACH_TEXT_MODEL=qwen3:1.7b
jac run --no-dev
```

Models use loopback 127.0.0.1:11434. Keep enough RAM free; the 8 GB test machine took about 80 seconds for a cold goal+vision smoke check and timed out under concurrent compilation. Manual controls remain usable when inference fails.

## API configuration

The photo/goal adapter is independent of the existing Gemini conversation adapter. To use an HTTPS Chat Completions API:

```sh
export COACH_PROVIDER=openai
export COACH_API_BASE=https://api.openai.com/v1
export COACH_API_MODEL=YOUR_VISION_AND_STRUCTURED_OUTPUT_MODEL
# Set COACH_API_KEY in the server environment or secret manager.
jac run --no-dev
```

Requires image data URLs, strict JSON Schema, store:false and max_completion_tokens support. Alternative API bases must support this contract; arbitrary providers are not automatically compatible. No frontend changes are needed. Keys stay server-side. Changed destination/model invalidates the displayed consent token. Transport rejects redirects, non-200 responses, oversized responses, refusal, incomplete output and invalid fields. Timeout: 90 seconds. No silent provider fallback.

Existing free-form chat continues to use its GOOGLE_API_KEY/GEMINI_API_KEY configuration. Selecting local photo analysis does not change that chat's provider disclosure.

## Verification

From the parent app:

```sh
jac check
jac test --jobs 0
jac test --jobs 0 coach/coach_tests.jac coach/phase3_tests.jac coach/api_tests.jac
# Explicit real local inference using synthetic pixels, not a personal photo:
COACH_LIVE_TEST=1 jac test --jobs 0 coach/phase3_live.jac
# Optional browser upload fixtures in /tmp:
jac test --jobs 0 coach/browser_fixture.jac
```

Live local smoke testing covers goal translation and abstention on a blank image. Real-person recognition quality requires a broader consented evaluation set. API compatibility has automated mocked coverage; no live paid API call has been verified. Physical-camera permission/capture remains a manual acceptance item.

## Extension boundaries

- coach_provider.jac: configuration and bounded transport.
- coach_vision.jac / coach_goals.jac: strict model contracts.
- coach_media.jac: byte validation and normalization.
- capture_ui.jac / vision_ui.jac / goal_ui.jac: photo lifecycle, confirmation and editable previews.
- coach_profile.jac: server validation; coach_ui.jac: temporary planning preferences.
- main.jac at app root: endpoint registration; components/ChatCoach.jac: integration.

CSS is scoped to .photo-coach. Keep persisted plan/calendar work on the later codex/progress-canvas branch and preserve completed workouts.

References: [Ollama vision](https://docs.ollama.com/capabilities/vision), [structured output](https://docs.ollama.com/capabilities/structured-outputs), [OpenAI image inputs](https://developers.openai.com/api/docs/guides/images-vision?api-mode=chat), [OpenAI structured output](https://developers.openai.com/api/docs/guides/structured-outputs?api-mode=chat), [CDC adult activity guidance](https://www.cdc.gov/physical-activity-basics/guidelines/adults.html). The emphasis threshold is an app heuristic, not a CDC medical rule.
