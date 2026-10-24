import Foundation
import Testing
@testable import NightcapCore

private final class FakeProcess: LaunchedProcess {
    var terminateCount = 0
    let exit: @MainActor () -> Void
    init(onExit: @escaping @MainActor () -> Void) { exit = onExit }
    func terminate() { terminateCount += 1 }
}

private final class FakeLauncher: ProcessLaunching {
    var arguments: [[String]] = []
    var processes: [FakeProcess] = []

    func launch(
        executableURL: URL,
        arguments: [String],
        onExit: @escaping @MainActor () -> Void
    ) throws -> any LaunchedProcess {
        self.arguments.append(arguments)
        let process = FakeProcess(onExit: onExit)
        processes.append(process)
        return process
    }
}

private struct LaunchFailure: Error {}

private struct FailingLauncher: ProcessLaunching {
    func launch(
        executableURL: URL,
        arguments: [String],
        onExit: @escaping @MainActor () -> Void
    ) throws -> any LaunchedProcess {
        throw LaunchFailure()
    }
}

private final class TestClock {
    var now = Date(timeIntervalSince1970: 1_792_756_800)
    func advance(_ seconds: TimeInterval) { now += seconds }
}

@MainActor
private func makeModel(_ launcher: any ProcessLaunching, _ clock: TestClock) -> AppModel {
    let defaults = freshDefaults()
    return AppModel(
        caffeinate: CaffeinateController(launcher: launcher, appPID: 99),
        stats: StatsStore(defaults: defaults, now: { clock.now })
    )
}

@MainActor
@Test(.isolatedDefaults) func toggleOnStartsCaffeinateAndCountsSession() throws {
    let launcher = FakeLauncher()
    let model = makeModel(launcher, TestClock())

    try model.toggle()

    #expect(model.isActive)
    #expect(model.stats.sessionsStarted == 1)
    #expect(model.stats.totalSeconds == 0)
    #expect(launcher.arguments == [["-d", "-i", "-m", "-s", "-w", "99"]])
}

@MainActor
@Test(.isolatedDefaults) func toggleOffStopsCaffeinateAndRecordsElapsedTime() throws {
    let launcher = FakeLauncher()
    let clock = TestClock()
    let model = makeModel(launcher, clock)
    try model.toggle()

    clock.advance(90)
    try model.toggle()

    #expect(!model.isActive)
    #expect(launcher.processes[0].terminateCount == 1)
    #expect(model.stats.sessionsStarted == 1)
    #expect(model.stats.totalSeconds == 90)
    #expect(model.stats.longestSeconds == 90)
}

@MainActor
@Test(.isolatedDefaults) func selectedDurationAppliesOnNextStart() throws {
    let launcher = FakeLauncher()
    let model = makeModel(launcher, TestClock())
    try model.toggle()

    model.selectedDuration = .hour1
    #expect(launcher.arguments.count == 1)

    try model.toggle()
    try model.toggle()

    #expect(launcher.arguments[1] == ["-d", "-i", "-m", "-s", "-w", "99", "-t", "3600"])
}

@Test func durationsMatchTheirCaffeinateTimeouts() {
    #expect(SessionDuration.allCases.map(\.seconds) == [nil, 900, 1800, 3600, 7200, 14400])
}

@MainActor
@Test(.isolatedDefaults) func caffeinateExitingOnItsOwnRecordsTheSessionOnce() throws {
    let launcher = FakeLauncher()
    let clock = TestClock()
    let defaults = freshDefaults()
    let caffeinate = CaffeinateController(launcher: launcher, appPID: 99)
    let model = AppModel(caffeinate: caffeinate, stats: StatsStore(defaults: defaults, now: { clock.now }))
    model.selectedDuration = .minutes15
    try model.toggle()

    clock.advance(900)
    launcher.processes[0].exit()

    #expect(!model.isActive)
    #expect(model.stats.sessionsStarted == 1)
    #expect(model.stats.totalSeconds == 900)
    #expect(model.stats.longestSeconds == 900)

    clock.advance(60)
    caffeinate.stop()
    launcher.processes[0].exit()

    #expect(launcher.processes[0].terminateCount == 0)
    #expect(model.stats.totalSeconds == 900)
    #expect(model.stats.longestSeconds == 900)
}

@MainActor
@Test(.isolatedDefaults) func exitAfterToggleOffRecordsNothingExtra() throws {
    let launcher = FakeLauncher()
    let clock = TestClock()
    let model = makeModel(launcher, clock)
    try model.toggle()
    clock.advance(90)
    try model.toggle()

    clock.advance(30)
    launcher.processes[0].exit()

    #expect(!model.isActive)
    #expect(model.stats.totalSeconds == 90)
}

@MainActor
@Test(.isolatedDefaults) func shutdownWhileActiveStopsCaffeinateAndRecordsTheSession() throws {
    let launcher = FakeLauncher()
    let clock = TestClock()
    let model = makeModel(launcher, clock)
    try model.toggle()

    clock.advance(45)
    model.shutdown()
    launcher.processes[0].exit()

    #expect(!model.isActive)
    #expect(launcher.processes[0].terminateCount == 1)
    #expect(model.stats.sessionsStarted == 1)
    #expect(model.stats.totalSeconds == 45)
    #expect(model.stats.longestSeconds == 45)
}

@MainActor
@Test(.isolatedDefaults) func shutdownWhileInactiveDoesNothing() throws {
    let launcher = FakeLauncher()
    let clock = TestClock()
    let model = makeModel(launcher, clock)
    try model.toggle()
    clock.advance(90)
    try model.toggle()

    clock.advance(30)
    model.shutdown()

    #expect(launcher.processes[0].terminateCount == 1)
    #expect(model.stats.totalSeconds == 90)
}

@MainActor
@Test(.isolatedDefaults) func failedStartLeavesModelInactiveAndCountsNothing() {
    let model = makeModel(FailingLauncher(), TestClock())

    #expect(throws: LaunchFailure.self) { try model.toggle() }
    #expect(!model.isActive)
    #expect(model.stats.sessionsStarted == 0)
}
