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
                    TextField(store.t("full_name"), text: $name)
                } header: {
                    Text(store.t("personal_info"))
                }

                Section {
                    HStack {
                        Text(store.t("username"))
                        Spacer()
                        Text(store.authUser?.username ?? "—")
                            .foregroundColor(DT.fgMuted)
                    }
                } header: {
                    Text(store.t("account"))
                }

                Section {
                    Button(store.t("logout"), role: .destructive) {
                        dismiss()
                        store.logout()
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(DT.bg)
            .navigationTitle(store.t("account"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(store.t("close")) { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(store.t("save")) {
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
