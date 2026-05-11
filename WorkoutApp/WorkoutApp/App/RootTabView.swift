import SwiftUI

struct RootTabView: View {
    @Environment(LocalAppState.self) private var state

    var body: some View {
        TabView {
            TodayView(state: state)
                .tabItem { Label("Today", systemImage: "figure.strengthtraining.traditional") }

            Text("Food")
                .tabItem { Label("Food", systemImage: "fork.knife") }

            Text("Grocery")
                .tabItem { Label("Grocery", systemImage: "cart") }

            Text("Plan")
                .tabItem { Label("Plan", systemImage: "book") }
        }
        .tint(AppTheme.accent)
    }
}
