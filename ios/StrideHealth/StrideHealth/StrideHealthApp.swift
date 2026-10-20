import SwiftUI
import OpenWearablesHealthSDK

@main
struct StrideHealthApp: App {
    @StateObject private var model: SyncModel

    init() {
        // The SDK registers its background tasks when first created, which iOS only
        // allows before launch finishes, so create it here rather than on first use.
        _ = OpenWearablesHealthSDK.shared
        _model = StateObject(wrappedValue: SyncModel())
    }

    var body: some Scene {
        WindowGroup {
            ContentView(model: model)
                .onOpenURL { model.open($0) }
        }
    }
}
