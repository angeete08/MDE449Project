# Stride mobile mini app

> Offline support supersedes the original online-only scope below. See [the offline-use guide](offline-use.md) for current preparation, functionality and sync behavior. The home-screen start URL is now `/offline`.

## Original choice and scope

An online, installable Progressive Web App is the best fit for the requested lightweight iPhone/Android app. It reuses Stride's Jac/React UI, authentication and server APIs. A native React Native implementation would require replacing the DOM/Radix UI; a WeChat Mini Program introduces a different platform without meeting the requested general phone scope.

Apple Health continues to use the existing Swift companion. This web app does not read HealthKit directly. Offline editing, background sync, push notifications and Android health integration are not implemented. Loading and saving require a reachable server. No service worker caches personal account or health responses.

## Branch and reused work

- Base: latest fetched `origin/dev`, `2b13b0d`, fetched November 9, 2026.
- Branch: `feature/mobile-mini-app`.
- `origin/main` remains the starter sample at `e463140`; the user selected `dev`.
- Adapted mobile route parameters, authentication redirects, scrolling tabs and action layout from `origin/feature/mobile-app` (`3010576`). Reused its Stride icon, resized to 192px and 512px.
- Retained dev's Coach, workout feedback and Apple Health fixes and desktop theme.

## Run and install

With the project's pinned Jac 0.37.21:

```sh
jac install
jac run --host 0.0.0.0
```

For a trusted Wi-Fi demo, open `http://YOUR_COMPUTER_LAN_IP:8000/mobile` on your phone. Phone localhost points to the phone, not the laptop. HTTP LAN access tests the UI; reliable home-screen app installation needs an HTTPS deployment with a trusted certificate. Keep frontend and authenticated API on the same public origin. The computer/server must remain running.

At the HTTPS deployment, open `/mobile`:

- iPhone: Safari → Share → Add to Home Screen.
- Android: Chrome → menu → Add to home screen / Install app.

The app icon launches `/mobile`. Signed-out users go to `/mobile-login`; signup and profile editing use `/mobile-onboarding`. Login and profile save return to `/mobile`. Desktop routes remain available. Manifest scope `/` keeps authentication pages within the installed window.

The manifest lives at `/static/assets/manifest.webmanifest`; React 19 hoists the application component's manifest link and Apple metadata into the document head. It defines standalone display, start URL and icons. No separate mobile backend or native build is required.

## Phone acceptance checklist

1. Open `/mobile` signed out; verify mobile login redirect.
2. Register a test account, finish onboarding with consent, and verify return to `/mobile`.
3. At 375px and 390px widths, verify page fit, scrolling tabs, readable inputs and usable profile/activity/logout controls.
4. Save activity, reload, edit the profile and log out; check persistence and mobile navigation.
5. Verify `/app` still works on desktop.
6. Fetch the manifest/icons and inspect the document-head manifest link.
7. On physical iPhone/Android devices over HTTPS, install and relaunch, then check keyboard, safe areas and saved account access. Desktop browser checks do not establish physical-device installation.

References: [PWA installation](https://web.dev/learn/pwa/installation), [installability requirements](https://developer.mozilla.org/en-US/docs/Web/Progressive_web_apps/Guides/Making_PWAs_installable).

## Verification in this checkout (November 9, 2026)

- Jac 0.37.21 `check`: passed with dynamic UI/runtime warnings, including intrinsic metadata tag warnings; the emitted JavaScript contains the expected HTML tags.
- `jac test --jobs 0`: 22 passed, 3 skipped. This is not full integration coverage.
- `jac build --as client`: passed; the manifest and icon assets are included.
- `git diff --check`: passed.
- Live browser/account checks are blocked: `jac install` fails in the standalone runtime's Python environment (ensurepip/native XML symbol failure), and server startup reports missing `litellm`. Frontend npm dependencies installed successfully.
- A further attempt with the official Python companion could not extract because the local disk was nearly full. Temporary files from that failed attempt were selected for cleanup.
- Physical iPhone/Android HTTPS installation and Apple Health device sync have not been tested.

The system `jac` is 0.37.11; verification used the separately downloaded official 0.37.21 binary, without replacing the system installation. Use a working 0.37.21 environment and run the phone acceptance checklist before publishing.
