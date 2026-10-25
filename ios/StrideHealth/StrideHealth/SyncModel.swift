import Foundation
import OpenWearablesHealthSDK

/// Weekly averages the Stride server computed from the uploaded samples.
struct HealthSummary: Decodable, Equatable {
    var avgDailySteps: Double?
    var avgHeartRate: Double?
    var avgSleepHours: Double?
    var avgWorkoutsPerWeek: Double?
    var days: Int?
}

/// Runs one sync request: HealthKit permission, the Open Wearables SDK upload, then the
/// Stride completion call. The SDK session is signed out afterwards so nothing keeps
/// syncing in the background to an expired request.
@MainActor
final class SyncModel: ObservableObject {
    enum Phase: Equatable {
        case idle
        case confirm(SyncRequest)
        case authorizing
        case sending
        case finishing
        case done(HealthSummary)
        case failed(String)
    }

    /// Health data Stride turns into weekly averages; nothing else is requested.
    static let types: [HealthDataType] = [.steps, .heartRate, .sleep, .workout]

    @Published private(set) var phase: Phase = .idle
    @Published private(set) var sentCount = 0

    private let sdk = OpenWearablesHealthSDK.shared
    private var watcher: Task<Void, Never>?

    var isBusy: Bool {
        switch phase {
        case .authorizing, .sending, .finishing: return true
        default: return false
        }
    }

    init() {
        sdk.onLog = { message in NSLog("[StrideHealth] %@", message) }
        // A request interrupted by the app being closed must not resume later.
        if sdk.isSyncActive || sdk.isSessionValid { sdk.signOut() }
    }

    func open(_ url: URL) {
        guard !isBusy else { return }
        if let request = SyncRequest(url: url) {
            phase = .confirm(request)
        } else {
            phase = .failed("This link is not a valid Stride sync request. Send a new one from Stride in your browser.")
        }
    }

    func reset() {
        guard !isBusy else { return }
        phase = .idle
    }

    func start(_ request: SyncRequest) {
        guard case .confirm = phase else { return }
        phase = .authorizing
        sentCount = 0
        sdk.configure(host: request.host.absoluteString)
        sdk.signIn(userId: request.id, accessToken: nil, refreshToken: nil, apiKey: request.id)
        sdk.requestAuthorization(types: Self.types) { [weak self] shown in
            Task { @MainActor in self?.authorized(shown, request) }
        }
    }

    private func authorized(_ shown: Bool, _ request: SyncRequest) {
        // HealthKit does not reveal read choices; `shown` only says the permission sheet worked.
        guard shown else { return fail("Apple Health access could not be requested on this iPhone.") }
        phase = .sending
        sdk.startBackgroundSync(syncDaysBack: request.days) { [weak self] started in
            Task { @MainActor in
                guard let self else { return }
                if started { self.watch(request) } else { self.fail("The sync could not start. Check that Apple Health is available and try again.") }
            }
        }
    }

    /// Polls the SDK until its initial export finishes or stops early.
    private func watch(_ request: SyncRequest) {
        watcher?.cancel()
        watcher = Task { [weak self] in
            let started = Date()
            var sawSending = false
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard let self else { return }
                let status = self.sdk.getSyncStatus()
                let sending = status["isSyncing"] as? Bool ?? false
                let done = status["initialExportDone"] as? Bool ?? false
                self.sentCount = max(self.sentCount, status["sentCount"] as? Int ?? 0)
                sawSending = sawSending || sending
                if done && !sending { return await self.finish(request) }
                if sawSending && !sending {
                    return self.fail("The upload stopped before it finished. Check that this iPhone and the computer running Stride are on the same Wi-Fi, then send a new request.")
                }
                let waited = Date().timeIntervalSince(started)
                if (!sawSending && waited > 60) || waited > 15 * 60 {
                    return self.fail("The sync did not finish. Send a new request from Stride and keep this app open.")
                }
            }
        }
    }

    private func finish(_ request: SyncRequest) async {
        phase = .finishing
        defer { sdk.signOut() }
        var call = URLRequest(url: request.host.appendingPathComponent("function/finish_health_sync"))
        call.httpMethod = "POST"
        call.setValue("application/json", forHTTPHeaderField: "Content-Type")
        call.httpBody = try? JSONSerialization.data(withJSONObject: ["sync_id": request.id])
        do {
            let (data, response) = try await URLSession.shared.data(for: call)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let result = try decoder.decode(Envelope.self, from: data).data?.result
            if let result, result.ok {
                phase = .done(result.summary ?? HealthSummary())
            } else {
                phase = .failed(result?.message ?? "Stride did not accept the data. Send a new request.")
            }
        } catch {
            phase = .failed("Your data was sent, but Stride at \(request.displayHost) could not be reached to finish. Send a new request.")
        }
    }

    private func fail(_ message: String) {
        watcher?.cancel()
        sdk.signOut()
        phase = .failed(message)
    }

    /// Jac's response envelope: `{"ok": true, "data": {"result": {...}}}`.
    private struct Envelope: Decodable {
        struct Payload: Decodable { let result: Outcome? }
        struct Outcome: Decodable {
            let ok: Bool
            let message: String?
            let summary: HealthSummary?
        }
        let data: Payload?
    }
}
