import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            ActiveRunView()
                .tabItem { Label("Run", systemImage: "figure.run") }

            HistoryView()
                .tabItem { Label("History", systemImage: "clock") }
        }
    }
}
