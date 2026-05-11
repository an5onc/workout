import SwiftUI

struct RootTabView: View {
    @Environment(LocalAppState.self) private var state

    var body: some View {
        TabView {
            TodayView(state: state)
                .tabItem { Label("Today", systemImage: "figure.strengthtraining.traditional") }

            FoodView(state: state)
                .tabItem { Label("Food", systemImage: "fork.knife") }

            GroceryView(state: state)
                .tabItem { Label("Grocery", systemImage: "cart") }

            PlanView()
                .tabItem { Label("Plan", systemImage: "book") }
        }
        .tint(AppTheme.accent)
    }
}
