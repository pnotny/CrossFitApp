import SwiftUI

/// Proklikávatelná sekce "Vyloučené pohybové vzory" z Profilu.
struct ExcludedPatternsSheetView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var selected: [MovementPattern] = []

    private func toggle(_ pattern: MovementPattern) {
        if selected.contains(pattern) { selected.removeAll { $0 == pattern } } else { selected.append(pattern) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(store.t("excluded_patterns_hint"))
                            .font(.system(size: 12)).foregroundColor(DT.fgMuted)
                        ChipGrid {
                            ForEach(MovementPattern.allCases, id: \.self) { pattern in
                                ChipButton(label: pattern.label(store.language), isActive: selected.contains(pattern), danger: true) {
                                    toggle(pattern)
                                }
                            }
                        }
                    }
                    .cardStyle()
                }
                .padding(16)
            }
            .background(DT.bg)
            .navigationTitle(store.t("excluded_patterns"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(store.t("close")) { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(store.t("save")) {
                        var profile = store.profile
                        profile.excludedPatterns = selected
                        store.saveProfile(profile)
                        dismiss()
                    }
                }
            }
            .onAppear { selected = store.profile.excludedPatterns }
        }
    }
}
