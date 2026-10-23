import BrewtimeCore
import SwiftUI

struct PanelView: View {
    let model: AppModel
    @State private var launchError: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle("Keep Mac awake", isOn: Binding(get: { model.isActive }, set: { _ in toggle() }))
                .toggleStyle(.switch)
                .font(.headline)

            Picker("Duration", selection: Bindable(model).selectedDuration) {
                ForEach(SessionDuration.allCases, id: \.self) { Text($0.label).tag($0) }
            }
            .disabled(model.isActive)

            if let start = model.stats.currentSessionStart {
                LabeledContent("Awake for") { Text(start, style: .timer).monospacedDigit() }
                if let seconds = model.selectedDuration.seconds {
                    LabeledContent("Remaining") {
                        Text(timerInterval: start...start.addingTimeInterval(TimeInterval(seconds)), countsDown: true)
                            .monospacedDigit()
                    }
                }
            }

            if let launchError {
                Text(launchError).font(.caption).foregroundStyle(.red)
            }

            Divider()

            Text("Stats").font(.headline)
            LabeledContent("Sessions started", value: "\(model.stats.sessionsStarted)")
            LabeledContent("Sessions today", value: "\(model.stats.sessionsToday)")
            LabeledContent("Total time awake", value: DurationFormat.string(fromSeconds: model.stats.totalSeconds))
            LabeledContent("Longest session", value: DurationFormat.string(fromSeconds: model.stats.longestSeconds))

            Divider()

            HStack {
                Button("Reset Stats") { model.stats.reset() }
                Spacer()
                Button("Quit") { NSApplication.shared.terminate(nil) }
                    .keyboardShortcut("q")
            }
        }
        .padding()
        .frame(width: 280)
    }

    private func toggle() {
        do {
            try model.toggle()
            launchError = nil
        } catch {
            launchError = "Could not start caffeinate: \(error.localizedDescription)"
        }
    }
}

private extension SessionDuration {
    var label: String {
        switch self {
        case .indefinitely: "Indefinitely"
        case .minutes15: "15 minutes"
        case .minutes30: "30 minutes"
        case .hour1: "1 hour"
        case .hours2: "2 hours"
        case .hours4: "4 hours"
        }
    }
}
