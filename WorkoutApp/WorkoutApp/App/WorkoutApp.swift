import SwiftUI

@main
struct WorkoutApp: App {
    @State private var appState = LocalAppState()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(appState)
        }
    }
}
