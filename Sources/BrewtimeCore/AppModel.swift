import Foundation
import Observation

/// How long a session keeps the Mac awake.
public enum SessionDuration: CaseIterable {
    case indefinitely, minutes15, minutes30, hour1, hours2, hours4

    /// The caffeinate timeout, or nil to stay awake until toggled off.
    public var seconds: Int? {
        switch self {
        case .indefinitely: nil
        case .minutes15: 15 * 60
        case .minutes30: 30 * 60
        case .hour1: 3600
        case .hours2: 2 * 3600
        case .hours4: 4 * 3600
        }
    }
}

/// Ties caffeinate to the usage stats: each session on/off pair is one recorded session.
@Observable
@MainActor
public final class AppModel {
    public var selectedDuration: SessionDuration = .indefinitely
    public private(set) var isActive = false
    public let stats: StatsStore
    private let caffeinate: CaffeinateController

    public init(caffeinate: CaffeinateController, stats: StatsStore) {
        self.caffeinate = caffeinate
        self.stats = stats
    }

    /// Starts caffeinate for the selected duration, or stops it and records the session.
    public func toggle() throws {
        if isActive {
            caffeinate.stop()
            stats.endSession()
            isActive = false
        } else {
            try caffeinate.start(seconds: selectedDuration.seconds)
            stats.startSession()
            isActive = true
        }
    }
}
