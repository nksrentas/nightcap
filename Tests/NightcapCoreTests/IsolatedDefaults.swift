import Foundation
import Testing

/// Gives each test its own defaults suite and deletes it afterwards.
/// The suite name is an absolute path, so its plist lives in the temp directory
/// instead of ~/Library/Preferences, where cfprefsd leaves even removed domains behind as empty files.
struct IsolatedDefaults: TestTrait, TestScoping {
    @TaskLocal static var suiteName: String?

    func provideScope(for test: Test, testCase: Test.Case?, performing function: () async throws -> Void) async throws {
        let name = FileManager.default.temporaryDirectory.appendingPathComponent("NightcapTests.\(UUID().uuidString)").path
        defer {
            let defaults = UserDefaults(suiteName: name)!
            defaults.removePersistentDomain(forName: name)
            defaults.synchronize()
            try? FileManager.default.removeItem(atPath: name + ".plist")
        }
        try await Self.$suiteName.withValue(name, operation: function)
    }
}

extension Trait where Self == IsolatedDefaults {
    static var isolatedDefaults: Self { IsolatedDefaults() }
}

/// The current test's defaults suite; the test must carry the `.isolatedDefaults` trait.
func freshDefaults() -> UserDefaults {
    guard let name = IsolatedDefaults.suiteName else {
        preconditionFailure("freshDefaults() needs @Test(.isolatedDefaults)")
    }
    return UserDefaults(suiteName: name)!
}
