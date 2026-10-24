import BrewtimeCore
import SwiftUI

/// Rendered as a native NSMenu by `.menuBarExtraStyle(.menu)`: toggles become checkmark items,
/// the picker a submenu, and plain text disabled info rows.
struct MenuContent: View {
    let model: AppModel
    @State private var launchError: String?

    var body: some View {
        Toggle("Keep Awake", isOn: Binding(get: { model.isActive }, set: { _ in toggle() }))

        Picker("Duration", selection: Bindable(model).selectedDuration) {
            ForEach(SessionDuration.allCases, id: \.self) { Text($0.label).tag($0) }
        }
        .disabled(model.isActive)

        if let start = model.stats.currentSessionStart {
            Text(sessionLine(start: start))
        }
        if let launchError {
            Text(launchError)
        }

        Divider()

        Section("Statistics") {
            Text("\(model.stats.sessionsStarted) sessions · \(model.stats.sessionsToday) today")
            Text("\(DurationFormat.string(fromSeconds: model.stats.totalSeconds)) awake · longest \(DurationFormat.string(fromSeconds: model.stats.longestSeconds))")
        }

        Divider()

        Button("Reset Statistics") { model.stats.reset() }
        Button("Quit Brewtime") { NSApplication.shared.terminate(nil) }
            .keyboardShortcut("q")
    }

    private func sessionLine(start: Date) -> String {
        let since = "Awake since \(start.formatted(date: .omitted, time: .shortened))"
        guard let seconds = model.selectedDuration.seconds else { return since }
        return since + " · until \(start.addingTimeInterval(TimeInterval(seconds)).formatted(date: .omitted, time: .shortened))"
    }

    private func toggle() {
        do {
            try model.toggle()
            launchError = nil
        } catch {
            launchError = "Couldn't start caffeinate"
        }
    }
}

private extension SessionDuration {
    var label: String {
        switch self {
        case .indefinitely: "Indefinitely"
        case .minutes15: "15 Minutes"
        case .minutes30: "30 Minutes"
        case .hour1: "1 Hour"
        case .hours2: "2 Hours"
        case .hours4: "4 Hours"
        }
    }
}
