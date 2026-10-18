import SwiftUI

struct RootTabView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView {
                TodayView()
                    .tabItem { Label("Dnes", systemImage: "calendar") }
                HistoryView()
                    .tabItem { Label("Historie", systemImage: "chart.line.uptrend.xyaxis") }
                LibraryView()
                    .tabItem { Label("Cviky", systemImage: "books.vertical") }
                ProfileView()
                    .tabItem { Label("Profil", systemImage: "person.crop.circle") }
            }

            if let message = store.toastMessage {
                ToastView(message: message)
                    .padding(.bottom, 70)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.22), value: store.toastMessage)
    }
}
