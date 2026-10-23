import Foundation

public protocol LaunchedProcess {
    func terminate()
}

public protocol ProcessLaunching {
    func launch(executableURL: URL, arguments: [String]) throws -> any LaunchedProcess
}

extension Process: LaunchedProcess {}

public struct SystemProcessLauncher: ProcessLaunching {
    public init() {}

    public func launch(executableURL: URL, arguments: [String]) throws -> any LaunchedProcess {
        let process = Process()
        process.executableURL = executableURL
        process.arguments = arguments
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

    public var isActive: Bool { process != nil }

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
        process = try launcher.launch(executableURL: Self.executableURL, arguments: arguments)
    }

    /// Terminates caffeinate. Does nothing while inactive.
    public func stop() {
        process?.terminate()
        process = nil
    }
}
