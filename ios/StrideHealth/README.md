# Stride Health (iOS companion)

A small SwiftUI app that sends Apple Health data to the Stride Jac web app. The web app cannot read Apple Health directly, so it sends a sync request to this app, the app reads HealthKit, and it uploads the samples to the Stride server. The server turns them into the four optional weekly averages on the planning form: daily steps, heart rate, sleep per night and workouts per week.

It reuses the MIT-licensed [Open Wearables iOS SDK](https://github.com/the-momentum/open_wearables_ios_sdk) (0.15.0, pinned through Swift Package Manager) for HealthKit permission, querying and upload. The Jac server implements the SDK's upload endpoints in `health_sync.jac`.

This is the project's only non-Jac application code. HealthKit is reachable only from a native iOS app.

## How a sync works

1. In Stride, open **Data settings**, choose **Fill it from connected apps** and then **Apple Health**.
2. In **Weekly averages**, select **Send sync request to iPhone**. Stride creates a one-time request and shows a QR code and a `stridehealth://sync?host=…&id=…&days=28` link.
3. Scan the code with the iPhone Camera app (or tap the link on the iPhone). Stride Health opens and shows the server address and the data requested.
4. **Allow and sync**. iOS shows the Apple Health permission sheet for steps, heart rate, sleep and workouts.
5. The SDK uploads the last 28 days to `POST {host}/api/v1/sdk/users/{id}/sync`. When the SDK finishes, the app calls `POST {host}/function/finish_health_sync` and signs the SDK out so nothing keeps syncing in the background.
6. The web page fills in the averages. Review them before creating the week.

Requests expire after 15 minutes without activity. The server keeps running totals in memory only, never the raw samples, and drops the results 10 minutes after completion. The request ID is the only credential, so treat the link as private.

## Requirements

- A Mac with Xcode 15 or later.
- An iPhone running iOS 16 or later. The Simulator also works if you add sample data in its Health app.
- The iPhone and the computer running `jac run` on the same Wi-Fi. The development server already listens on the network at port 8000. Some campus or guest networks block device-to-device traffic; use a phone hotspot or home Wi-Fi if the sync never starts.

## Build and install

The Xcode project is generated from `project.yml` with [XcodeGen](https://github.com/yonaskolb/XcodeGen) 2.46.0 and committed, so you only need Xcode:

1. Open `ios/StrideHealth/StrideHealth.xcodeproj`. Xcode downloads the SDK package.
2. Select the **StrideHealth** target, then **Signing & Capabilities**. Choose your team and, if Xcode asks, change the bundle identifier (`edu.eecs449.group10.stridehealth`) to one unique to you. The HealthKit capability is already in `StrideHealth.entitlements`.
3. Connect the iPhone, select it as the run destination and press **Run**. On the iPhone, trust the developer profile under **Settings → General → VPN & Device Management** if asked, and enable Developer Mode if iOS prompts for it.

After changing `project.yml`, regenerate with `xcodegen generate` from this folder.

## Files

- `StrideHealth/StrideHealthApp.swift` – app entry; handles `stridehealth://` links.
- `StrideHealth/SyncRequest.swift` – parses and validates a sync link. Plain HTTP is accepted only for local-network hosts.
- `StrideHealth/SyncModel.swift` – permission, SDK upload, completion call and sign-out.
- `StrideHealth/ContentView.swift` – confirmation, progress and result screens.
- `project.yml` – XcodeGen spec, including Info.plist keys (URL scheme, Health and local-network usage text, local-network ATS exception, SDK background task IDs) and the HealthKit entitlement.

## Limits

- Not yet built or run on a device or Simulator. It was written on a machine without Xcode. The link parser was compiled and tested with `swiftc`, and the app was type-checked against a stub of the SDK's public API.
- HealthKit does not tell apps which read permissions were declined. A declined type looks like a type with no data, and its average is left empty.
- Step and sleep totals are de-duplicated by using the largest source each day (for example the Watch or the iPhone). They can differ slightly from the Health app's own totals.
- A free Apple developer account can install the app for 7 days at a time.
