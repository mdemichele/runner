import SwiftUI

@main
struct RunnerApp: App {
    @StateObject private var runManager = RunManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(runManager)
        }
    }
}
