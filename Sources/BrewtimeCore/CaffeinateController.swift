import Foundation

public protocol LaunchedProcess {
    func terminate()
}

public protocol ProcessLaunching {
    /// Launches the process; `onExit` runs on the main actor once it exits, for any reason.
    func launch(
        executableURL: URL,
        arguments: [String],
        onExit: @escaping @MainActor () -> Void
    ) throws -> any LaunchedProcess
}

extension Process: LaunchedProcess {}

public struct SystemProcessLauncher: ProcessLaunching {
    public init() {}

    public func launch(
        executableURL: URL,
        arguments: [String],
        onExit: @escaping @MainActor () -> Void
    ) throws -> any LaunchedProcess {
        let process = Process()
        process.executableURL = executableURL
        process.arguments = arguments
        process.terminationHandler = { _ in Task { @MainActor in onExit() } }
        try process.run()
        return process
    }
}

/// Keeps the Mac awake by running `caffeinate` tied to the app's lifetime (`-w <pid>`).
@MainActor
public final class CaffeinateController {
    static let executableURL = URL(fileURLWithPath: "/usr/bin/caffeinate")

    private let launcher: any ProcessLaunching
    private let appPID: Int32
    private var process: (any LaunchedProcess)?
    private var launchCount = 0

    public var isActive: Bool { process != nil }

    /// Called when caffeinate exits on its own (timeout elapsed or killed externally), never after `stop()`.
    public var onExit: (() -> Void)?

    public init(
        launcher: any ProcessLaunching = SystemProcessLauncher(),
        appPID: Int32 = ProcessInfo.processInfo.processIdentifier
    ) {
        self.launcher = launcher
        self.appPID = appPID
    }

    /// Starts caffeinate, for `seconds` when given, otherwise until stopped. Does nothing while active.
    public func start(seconds: Int? = nil) throws {
        guard process == nil else { return }
        var arguments = ["-d", "-i", "-m", "-s", "-w", String(appPID)]
        if let seconds {
            arguments += ["-t", String(seconds)]
        }
        launchCount += 1
        let launch = launchCount
        process = try launcher.launch(executableURL: Self.executableURL, arguments: arguments) { [weak self] in
            self?.processExited(launch)
        }
    }

    /// Terminates caffeinate. Does nothing while inactive.
    public func stop() {
        process?.terminate()
        process = nil
    }

    /// Ignores exits that `stop()` caused and exits of processes from earlier launches.
    private func processExited(_ launch: Int) {
        guard launch == launchCount, process != nil else { return }
        process = nil
        onExit?()
    }
}
