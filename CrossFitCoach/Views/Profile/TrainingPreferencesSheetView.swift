import SwiftUI

/// Proklikávatelná sekce "Cíl a formáty" z Profilu — hlavní tréninkový cíl
/// a oblíbené formáty metconu.
struct TrainingPreferencesSheetView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var goal: Goal = .condition
    @State private var preferredFormats: [WorkoutFormat] = []

    private static let preferredFormatOptions: [WorkoutFormat] = [.emom, .amrap, .forTime, .chipper, .tabata, .intervals, .steady]

    private func toggle(_ format: WorkoutFormat) {
        if preferredFormats.contains(format) { preferredFormats.removeAll { $0 == format } } else { preferredFormats.append(format) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 12) {
                        sectionHeader(store.t("main_goal"))
                        SegmentedPicker(options: Goal.allCases.map { ($0, $0.label(store.language)) }, selection: $goal)
                    }
                    .cardStyle()

                    VStack(alignment: .leading, spacing: 12) {
                        sectionHeader(store.t("preferred_formats"))
                        ChipGrid {
                            ForEach(Self.preferredFormatOptions, id: \.self) { format in
                                ChipButton(label: format.label(store.language), isActive: preferredFormats.contains(format)) {
                                    toggle(format)
                                }
                            }
                        }
                    }
                    .cardStyle()
                }
                .padding(16)
            }
            .background(DT.bg)
            .navigationTitle(store.t("training_preferences"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(store.t("close")) { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(store.t("save")) {
                        var profile = store.profile
                        profile.goal = goal
                        profile.preferredFormats = preferredFormats
                        store.saveProfile(profile)
                        dismiss()
                    }
                }
            }
            .onAppear {
                goal = store.profile.goal
                preferredFormats = store.profile.preferredFormats
            }
        }
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .heavy))
            .trackedUppercase(0.3)
            .foregroundColor(DT.fgMuted)
    }
}
