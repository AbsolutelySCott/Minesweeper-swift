import SwiftUI

@main
struct MinesweeperApp: App {
    init() {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-resetGameState") {
            let domain = Bundle.main.bundleIdentifier ?? "com.scott.minesweeper"
            UserDefaults.standard.removePersistentDomain(forName: domain)
        }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            GameScreen()
                .preferredColorScheme(nil)
        }
    }
}
