import SwiftUI

@main
struct CrossFitCoachApp: App {
    @StateObject private var store = AppStore()

    var body: some Scene {
        WindowGroup {
            AuthGateView()
                .environmentObject(store)
                .preferredColorScheme(store.colorScheme)
        }
    }
}

/// Appka vyžaduje platné přihlášení — bez něj se zobrazí jen LoginView.
private struct AuthGateView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        Group {
            if store.isRestoringSession {
                ZStack {
                    DT.bg.ignoresSafeArea()
                    ProgressView()
                }
            } else if store.authUser != nil {
                RootTabView()
            } else {
                LoginView()
            }
        }
        .task { await store.restoreSession() }
    }
}
