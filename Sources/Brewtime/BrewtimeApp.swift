import SwiftUI

@main
struct BrewtimeApp: App {
    var body: some Scene {
        MenuBarExtra("Brewtime", systemImage: "cup.and.saucer") {
            Button("Quit Brewtime") { NSApplication.shared.terminate(nil) }
                .keyboardShortcut("q")
        }
    }
}
