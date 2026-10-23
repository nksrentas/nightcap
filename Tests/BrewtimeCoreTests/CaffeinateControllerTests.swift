import Foundation
import Testing
@testable import BrewtimeCore

private final class FakeProcess: LaunchedProcess {
    var terminateCount = 0
    func terminate() { terminateCount += 1 }
}

private final class FakeLauncher: ProcessLaunching {
    var launches: [(executableURL: URL, arguments: [String])] = []
    var processes: [FakeProcess] = []

    func launch(executableURL: URL, arguments: [String]) throws -> any LaunchedProcess {
        launches.append((executableURL, arguments))
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

@MainActor
@Test func startLaunchesCaffeinateIndefinitely() throws {
    let launcher = FakeLauncher()
    let controller = CaffeinateController(launcher: launcher, appPID: 4242)

    try controller.start()

    #expect(controller.isActive)
    #expect(launcher.launches.count == 1)
    #expect(launcher.launches[0].executableURL.path == "/usr/bin/caffeinate")
    #expect(launcher.launches[0].arguments == ["-d", "-i", "-m", "-s", "-w", "4242"])
}

@MainActor
@Test func startWithDurationPassesTimeout() throws {
    let launcher = FakeLauncher()
    let controller = CaffeinateController(launcher: launcher, appPID: 7)

    try controller.start(seconds: 3600)

    #expect(launcher.launches[0].arguments == ["-d", "-i", "-m", "-s", "-w", "7", "-t", "3600"])
}

@MainActor
@Test func stopTerminatesProcess() throws {
    let launcher = FakeLauncher()
    let controller = CaffeinateController(launcher: launcher, appPID: 1)
    try controller.start()

    controller.stop()

    #expect(!controller.isActive)
    #expect(launcher.processes[0].terminateCount == 1)
}

@MainActor
@Test func startWhileActiveIsNoOp() throws {
    let launcher = FakeLauncher()
    let controller = CaffeinateController(launcher: launcher, appPID: 1)
    try controller.start()

    try controller.start(seconds: 60)

    #expect(launcher.launches.count == 1)
    #expect(controller.isActive)
}

@MainActor
@Test func stopWhileInactiveIsNoOp() throws {
    let launcher = FakeLauncher()
    let controller = CaffeinateController(launcher: launcher, appPID: 1)
    try controller.start()
    controller.stop()

    controller.stop()

    #expect(launcher.processes[0].terminateCount == 1)
    #expect(!controller.isActive)
}

@MainActor
@Test func failedLaunchLeavesControllerInactive() {
    let controller = CaffeinateController(launcher: FailingLauncher(), appPID: 1)

    #expect(throws: LaunchFailure.self) { try controller.start() }
    #expect(!controller.isActive)
}

@MainActor
@Test func canRestartAfterStop() throws {
    let launcher = FakeLauncher()
    let controller = CaffeinateController(launcher: launcher, appPID: 1)
    try controller.start()
    controller.stop()

    try controller.start(seconds: 900)

    #expect(controller.isActive)
    #expect(launcher.launches.count == 2)
    #expect(launcher.launches[1].arguments.suffix(2) == ["-t", "900"])
}
