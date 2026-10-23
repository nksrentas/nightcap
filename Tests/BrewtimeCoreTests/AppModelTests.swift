import Foundation
import Testing
@testable import BrewtimeCore

private final class FakeProcess: LaunchedProcess {
    var terminateCount = 0
    func terminate() { terminateCount += 1 }
}

private final class FakeLauncher: ProcessLaunching {
    var arguments: [[String]] = []
    var processes: [FakeProcess] = []

    func launch(executableURL: URL, arguments: [String]) throws -> any LaunchedProcess {
        self.arguments.append(arguments)
        let process = FakeProcess()
        processes.append(process)
        return process
    }
}

private struct LaunchFailure: Error {}

private struct FailingLauncher: ProcessLaunching {
    func launch(executableURL: URL, arguments: [String]) throws -> any LaunchedProcess {
        throw LaunchFailure()
    }
}

private final class TestClock {
    var now = Date(timeIntervalSince1970: 1_792_756_800)
    func advance(_ seconds: TimeInterval) { now += seconds }
}

@MainActor
private func makeModel(_ launcher: any ProcessLaunching, _ clock: TestClock) -> AppModel {
    let defaults = UserDefaults(suiteName: "BrewtimeTests.\(UUID().uuidString)")!
    return AppModel(
        caffeinate: CaffeinateController(launcher: launcher, appPID: 99),
        stats: StatsStore(defaults: defaults, now: { clock.now })
    )
}

@MainActor
@Test func toggleOnStartsCaffeinateAndCountsSession() throws {
    let launcher = FakeLauncher()
    let model = makeModel(launcher, TestClock())

    try model.toggle()

    #expect(model.isActive)
    #expect(model.stats.sessionsStarted == 1)
    #expect(model.stats.totalSeconds == 0)
    #expect(launcher.arguments == [["-d", "-i", "-m", "-s", "-w", "99"]])
}

@MainActor
@Test func toggleOffStopsCaffeinateAndRecordsElapsedTime() throws {
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
@Test func selectedDurationAppliesOnNextStart() throws {
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
@Test func failedStartLeavesModelInactiveAndCountsNothing() {
    let model = makeModel(FailingLauncher(), TestClock())

    #expect(throws: LaunchFailure.self) { try model.toggle() }
    #expect(!model.isActive)
    #expect(model.stats.sessionsStarted == 0)
}
