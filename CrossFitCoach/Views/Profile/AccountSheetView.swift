import SwiftUI

/// Proklikávatelná sekce "Účet" z Profilu — jméno/příjmení a odhlášení.
/// Prezentuje se jako sheet (ne push navigace), protože Profil je jedna
/// ze stránek swipovaného TabView bez vlastního NavigationStacku.
struct AccountSheetView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Jméno a příjmení", text: $name)
                } header: {
                    Text("Osobní údaje")
                }

                Section {
                    HStack {
                        Text("Uživatelské jméno")
                        Spacer()
                        Text(store.authUser?.username ?? "—")
                            .foregroundColor(DT.fgMuted)
                    }
                } header: {
                    Text("Účet")
                }

                Section {
                    Button("Odhlásit se", role: .destructive) {
                        dismiss()
                        store.logout()
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(DT.bg)
            .navigationTitle("Účet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Zavřít") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Uložit") {
                        var profile = store.profile
                        profile.name = name
                        store.saveProfile(profile)
                        dismiss()
                    }
                }
            }
            .onAppear { name = store.profile.name }
        }
    }
}
