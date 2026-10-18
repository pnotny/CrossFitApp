import SwiftUI

@main
struct CrossFitCoachApp: App {
    @StateObject private var store = AppStore()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(store)
                .preferredColorScheme(store.colorScheme)
        }
    }
}
