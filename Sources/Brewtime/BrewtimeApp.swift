import AppKit
import BrewtimeCore
import SwiftUI

@main
struct BrewtimeApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate

    var body: some Scene {
        let model = appDelegate.model
        MenuBarExtra("Brewtime", systemImage: model.isActive ? "cup.and.heat.waves.fill" : "cup.and.saucer") {
            MenuContent(model: model)
        }
        .menuBarExtraStyle(.menu)
    }
}

/// Owns the model so quitting can record the running session before caffeinate is lost.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let model = AppModel(caffeinate: CaffeinateController(), stats: StatsStore(defaults: .standard))

    func applicationWillTerminate(_ notification: Notification) {
        model.shutdown()
    }
}
