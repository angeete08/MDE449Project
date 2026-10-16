import SwiftUI

struct ContentView: View {
    @ObservedObject var model: SyncModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    content
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle("Stride Health")
        }
        .tint(Color(red: 0.09, green: 0.24, blue: 0.21))
    }

    @ViewBuilder private var content: some View {
        switch model.phase {
        case .idle:
            Text("Send Apple Health averages to Stride")
                .font(.title2.bold())
            Text("Open Stride in your browser, choose Apple Health in Data settings, then select **Send sync request to iPhone**. Scan the code with the Camera app or tap the link on this iPhone.")
            Text("This app does nothing until it receives a sync request.")
                .foregroundStyle(.secondary)

        case .confirm(let request):
            Text("Allow this sync?")
                .font(.title2.bold())
            Text("Stride at **\(request.displayHost)** asks for the last \(request.days) days of:")
            VStack(alignment: .leading, spacing: 8) {
                Label("Steps", systemImage: "figure.walk")
                Label("Heart rate", systemImage: "heart")
                Label("Sleep", systemImage: "bed.double")
                Label("Workouts", systemImage: "figure.run")
            }
            Text("The samples are sent once to that server, which turns them into weekly averages for the Stride form and then discards them. Apple Health will ask which of these you allow.")
                .foregroundStyle(.secondary)
            if request.isPlainHTTP {
                Text("This connection is not encrypted. Only continue on your own Wi-Fi with a computer you trust.")
                    .foregroundStyle(.orange)
            }
            Button("Allow and sync") { model.start(request) }
                .buttonStyle(.borderedProminent)
            Button("Cancel", role: .cancel) { model.reset() }

        case .authorizing:
            ProgressView("Waiting for Apple Health permission…")

        case .sending, .finishing:
            ProgressView(model.phase == .finishing ? "Finishing…" : "Sending Apple Health data…")
            Text("\(model.sentCount) samples sent. Keep this app open until it finishes.")
                .foregroundStyle(.secondary)

        case .done(let summary):
            Label("Sent to Stride", systemImage: "checkmark.circle.fill")
                .font(.title2.bold())
                .foregroundStyle(.green)
            VStack(alignment: .leading, spacing: 8) {
                row("Average daily steps", summary.avgDailySteps.map { String(Int($0)) })
                row("Average heart rate", summary.avgHeartRate.map { String(format: "%.1f bpm", $0) })
                row("Average sleep", summary.avgSleepHours.map { String(format: "%.1f h", $0) })
                row("Workouts per week", summary.avgWorkoutsPerWeek.map { String(format: "%.1f", $0) })
            }
            Text("Return to Stride in your browser to review these values. Empty values had no data or were not allowed.")
                .foregroundStyle(.secondary)
            Button("Done") { model.reset() }

        case .failed(let message):
            Label("Sync not completed", systemImage: "exclamationmark.triangle.fill")
                .font(.title2.bold())
                .foregroundStyle(.orange)
            Text(message)
            Button("Close") { model.reset() }
        }
    }

    private func row(_ title: String, _ value: String?) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value ?? "No data").foregroundStyle(value == nil ? .secondary : .primary)
        }
    }
}
