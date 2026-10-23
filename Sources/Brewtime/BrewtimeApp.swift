import BrewtimeCore
import SwiftUI

@main
struct BrewtimeApp: App {
    @State private var model = AppModel(caffeinate: CaffeinateController(), stats: StatsStore(defaults: .standard))

    var body: some Scene {
        MenuBarExtra("Brewtime", systemImage: model.isActive ? "cup.and.heat.waves.fill" : "cup.and.saucer") {
            PanelView(model: model)
        }
        .menuBarExtraStyle(.window)
    }
}
