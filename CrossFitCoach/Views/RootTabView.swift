import SwiftUI

/// Vlastní tab bar + .page TabView místo systémového — SwiftUI's systémový tab bar
/// (.tabItem) swipe mezi záložkami nepodporuje, takže pro přepínání tažením prstem
/// (Dnes/Historie/Cviky/Profil) musí obsah jet ve stránkovaném TabView a tab bar si
/// appka kreslí sama, napojený na stejný `selection`.
struct RootTabView: View {
    @EnvironmentObject var store: AppStore
    @State private var selection = 0

    private struct Tab {
        let title: String
        let icon: String
    }

    private static let tabs: [Tab] = [
        Tab(title: "Dnes", icon: "calendar"),
        Tab(title: "Historie", icon: "chart.line.uptrend.xyaxis"),
        Tab(title: "Cviky", icon: "books.vertical"),
        Tab(title: "Profil", icon: "person.crop.circle"),
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                TabView(selection: $selection) {
                    TodayView().tag(0)
                    HistoryView().tag(1)
                    LibraryView().tag(2)
                    ProfileView().tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                tabBar
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

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(Array(Self.tabs.enumerated()), id: \.offset) { idx, tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { selection = idx }
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 21, weight: selection == idx ? .semibold : .regular))
                        Text(tab.title)
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundColor(selection == idx ? .accentColor : .secondary)
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
        .background(.bar)
        .overlay(alignment: .top) {
            Divider()
        }
    }
}
