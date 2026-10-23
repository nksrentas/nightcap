import Foundation
import Observation

/// Usage stats for caffeinate sessions, persisted in a UserDefaults suite at whole-second precision.
@Observable
@MainActor
public final class StatsStore {
    private enum Key {
        static let sessionsStarted = "stats.sessionsStarted"
        static let totalSeconds = "stats.totalSeconds"
        static let longestSeconds = "stats.longestSeconds"
        static let todayStart = "stats.todayStart"
        static let todayCount = "stats.todayCount"
    }

    private let defaults: UserDefaults
    private let now: () -> Date
    private let calendar: Calendar

    public private(set) var sessionsStarted: Int
    public private(set) var totalSeconds: Int
    public private(set) var longestSeconds: Int
    /// Start of the session in progress; kept in memory only, so a crash never leaves a stale one behind.
    public private(set) var currentSessionStart: Date?
    private var todayStart: Date?
    private var todayCount: Int

    /// Sessions started since local midnight.
    public var sessionsToday: Int {
        todayStart == calendar.startOfDay(for: now()) ? todayCount : 0
    }

    public init(defaults: UserDefaults, now: @escaping () -> Date = Date.init, calendar: Calendar = .current) {
        self.defaults = defaults
        self.now = now
        self.calendar = calendar
        sessionsStarted = defaults.integer(forKey: Key.sessionsStarted)
        totalSeconds = defaults.integer(forKey: Key.totalSeconds)
        longestSeconds = defaults.integer(forKey: Key.longestSeconds)
        todayStart = defaults.object(forKey: Key.todayStart) as? Date
        todayCount = defaults.integer(forKey: Key.todayCount)
    }

    /// Counts a new session as started now. Does nothing while a session is in progress.
    public func startSession() {
        guard currentSessionStart == nil else { return }
        let start = now()
        let day = calendar.startOfDay(for: start)
        todayCount = todayStart == day ? todayCount + 1 : 1
        todayStart = day
        sessionsStarted += 1
        currentSessionStart = start
        save()
    }

    /// Adds the session in progress to the totals. Does nothing when no session is in progress.
    public func endSession() {
        guard let start = currentSessionStart else { return }
        let seconds = max(0, Int(now().timeIntervalSince(start)))
        totalSeconds += seconds
        longestSeconds = max(longestSeconds, seconds)
        currentSessionStart = nil
        save()
    }

    /// Zeroes every stat and forgets the session in progress.
    public func reset() {
        sessionsStarted = 0
        totalSeconds = 0
        longestSeconds = 0
        todayStart = nil
        todayCount = 0
        currentSessionStart = nil
        save()
    }

    private func save() {
        defaults.set(sessionsStarted, forKey: Key.sessionsStarted)
        defaults.set(totalSeconds, forKey: Key.totalSeconds)
        defaults.set(longestSeconds, forKey: Key.longestSeconds)
        defaults.set(todayStart, forKey: Key.todayStart)
        defaults.set(todayCount, forKey: Key.todayCount)
    }
}
