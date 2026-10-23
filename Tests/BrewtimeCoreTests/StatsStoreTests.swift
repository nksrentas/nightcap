import Foundation
import os
import Testing
@testable import BrewtimeCore

private final class TestClock {
    var now: Date
    init(_ now: Date) { self.now = now }
    func advance(_ seconds: TimeInterval) { now += seconds }
}

private func freshDefaults() -> UserDefaults {
    UserDefaults(suiteName: "BrewtimeTests.\(UUID().uuidString)")!
}

private var utcCalendar: Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    return calendar
}

/// 2026-10-23 12:00:00 UTC.
private let noon = Date(timeIntervalSince1970: 1_792_756_800)

@MainActor
private func makeStore(_ defaults: UserDefaults, _ clock: TestClock) -> StatsStore {
    StatsStore(defaults: defaults, now: { clock.now }, calendar: utcCalendar)
}

@MainActor
private func recordSession(_ store: StatsStore, _ clock: TestClock, seconds: TimeInterval) {
    store.startSession()
    clock.advance(seconds)
    store.endSession()
}

@MainActor
@Test func newStoreIsZeroed() {
    let store = makeStore(freshDefaults(), TestClock(noon))

    #expect(store.sessionsStarted == 0)
    #expect(store.totalSeconds == 0)
    #expect(store.longestSeconds == 0)
    #expect(store.sessionsToday == 0)
    #expect(store.currentSessionStart == nil)
}

@MainActor
@Test func recordsCountTotalAndLongest() {
    let clock = TestClock(noon)
    let store = makeStore(freshDefaults(), clock)

    recordSession(store, clock, seconds: 60)
    recordSession(store, clock, seconds: 120)

    #expect(store.sessionsStarted == 2)
    #expect(store.totalSeconds == 180)
    #expect(store.longestSeconds == 120)
}

@MainActor
@Test func startCountsImmediatelyAndTracksCurrentStart() {
    let clock = TestClock(noon)
    let store = makeStore(freshDefaults(), clock)

    store.startSession()

    #expect(store.sessionsStarted == 1)
    #expect(store.sessionsToday == 1)
    #expect(store.currentSessionStart == noon)
    #expect(store.totalSeconds == 0)

    clock.advance(30)
    store.endSession()
    #expect(store.currentSessionStart == nil)
}

@MainActor
@Test func startWhileInProgressAndEndWithoutSessionAreNoOps() {
    let clock = TestClock(noon)
    let store = makeStore(freshDefaults(), clock)

    store.endSession()
    store.startSession()
    clock.advance(10)
    store.startSession()
    clock.advance(10)
    store.endSession()
    store.endSession()

    #expect(store.sessionsStarted == 1)
    #expect(store.totalSeconds == 20)
}

@MainActor
@Test func newStoreOnSameSuiteReadsPersistedValues() {
    let defaults = freshDefaults()
    let clock = TestClock(noon)
    let store = makeStore(defaults, clock)
    recordSession(store, clock, seconds: 60)
    recordSession(store, clock, seconds: 120)

    let reloaded = makeStore(defaults, clock)

    #expect(reloaded.sessionsStarted == 2)
    #expect(reloaded.totalSeconds == 180)
    #expect(reloaded.longestSeconds == 120)
    #expect(reloaded.sessionsToday == 2)
}

@MainActor
@Test func resetZeroesEverythingAndPersists() {
    let defaults = freshDefaults()
    let clock = TestClock(noon)
    let store = makeStore(defaults, clock)
    recordSession(store, clock, seconds: 60)
    store.startSession()

    store.reset()

    let reloaded = makeStore(defaults, clock)
    for stats in [store, reloaded] {
        #expect(stats.sessionsStarted == 0)
        #expect(stats.totalSeconds == 0)
        #expect(stats.longestSeconds == 0)
        #expect(stats.sessionsToday == 0)
        #expect(stats.currentSessionStart == nil)
    }
}

@MainActor
@Test func resetNotifiesObserversOfTheStats() {
    let clock = TestClock(noon)
    let store = makeStore(freshDefaults(), clock)
    recordSession(store, clock, seconds: 60)
    let changed = OSAllocatedUnfairLock(initialState: false)
    withObservationTracking {
        _ = store.totalSeconds
    } onChange: {
        changed.withLock { $0 = true }
    }

    store.reset()

    #expect(changed.withLock { $0 })
}

@MainActor
@Test func sessionsTodayCountsOnlySinceLocalMidnight() {
    // 2026-10-22 23:59:00 UTC, one minute before midnight.
    let clock = TestClock(noon - 12 * 3600 - 60)
    let store = makeStore(freshDefaults(), clock)

    recordSession(store, clock, seconds: 30)
    #expect(store.sessionsToday == 1)

    clock.advance(60)
    #expect(store.sessionsToday == 0)

    recordSession(store, clock, seconds: 30)
    recordSession(store, clock, seconds: 30)
    #expect(store.sessionsToday == 2)
    #expect(store.sessionsStarted == 3)

    clock.advance(24 * 3600)
    #expect(store.sessionsToday == 0)
}

@MainActor
@Test func midnightFollowsTheInjectedTimeZone() {
    var athens = Calendar(identifier: .gregorian)
    athens.timeZone = TimeZone(identifier: "Europe/Athens")!
    // 2026-10-22 22:30 UTC is 01:30 on 2026-10-23 in Athens (UTC+3).
    let clock = TestClock(noon - 13.5 * 3600)
    let store = StatsStore(defaults: freshDefaults(), now: { clock.now }, calendar: athens)
    recordSession(store, clock, seconds: 30)

    // 2026-10-23 20:00 UTC is still 2026-10-23 in Athens.
    clock.now = noon + 8 * 3600
    #expect(store.sessionsToday == 1)

    // 2026-10-23 21:30 UTC is 00:30 on 2026-10-24 in Athens.
    clock.now = noon + 9.5 * 3600
    #expect(store.sessionsToday == 0)
}
