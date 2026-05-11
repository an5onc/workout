import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            Text("Today")
                .tabItem { Label("Today", systemImage: "figure.strengthtraining.traditional") }

            Text("Food")
                .tabItem { Label("Food", systemImage: "fork.knife") }

            Text("Grocery")
                .tabItem { Label("Grocery", systemImage: "cart") }

            Text("Plan")
                .tabItem { Label("Plan", systemImage: "book") }
        }
    }
}
