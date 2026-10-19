import SwiftUI

/// Proklikávatelná sekce "Dostupné vybavení" z Profilu.
struct EquipmentSheetView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var selected: [Equipment] = []

    private func toggle(_ eq: Equipment) {
        if selected.contains(eq) { selected.removeAll { $0 == eq } } else { selected.append(eq) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 12) {
                        ChipGrid {
                            ForEach(Equipment.allCases.filter { $0 != .none }, id: \.self) { eq in
                                ChipButton(label: eq.label(store.language), isActive: selected.contains(eq)) {
                                    toggle(eq)
                                }
                            }
                        }
                    }
                    .cardStyle()
                }
                .padding(16)
            }
            .background(DT.bg)
            .navigationTitle(store.t("available_equipment"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(store.t("close")) { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(store.t("save")) {
                        var profile = store.profile
                        profile.equipment = selected
                        store.saveProfile(profile)
                        dismiss()
                    }
                }
            }
            .onAppear { selected = store.profile.equipment }
        }
    }
}
