import SwiftUI

/// Proklikávatelná sekce "Týdenní plán" z Profilu — typ dne pro každý den týdne.
struct WeeklyTemplateSheetView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var weeklyTemplate: [DayType] = AthleteProfile.defaultWeeklyTemplate

    private static let dayLabelsCS = ["Po", "Út", "St", "Čt", "Pá", "So", "Ne"]
    private static let dayLabelsEN = ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(0..<7, id: \.self) { idx in
                            HStack {
                                Text(store.language == .en ? Self.dayLabelsEN[idx] : Self.dayLabelsCS[idx])
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(DT.fg)
                                    .frame(width: 32, alignment: .leading)
                                Spacer()
                                Picker("", selection: Binding(
                                    get: { idx < weeklyTemplate.count ? weeklyTemplate[idx] : .rest },
                                    set: { newValue in
                                        while weeklyTemplate.count < 7 { weeklyTemplate.append(.rest) }
                                        weeklyTemplate[idx] = newValue
                                    }
                                )) {
                                    ForEach(DayType.allCases, id: \.self) { day in
                                        Text(day.label(store.language)).tag(day)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(DT.accentText)
                            }
                        }
                    }
                    .cardStyle()
                }
                .padding(16)
            }
            .background(DT.bg)
            .navigationTitle(store.t("weekly_plan"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(store.t("close")) { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(store.t("save")) {
                        var profile = store.profile
                        profile.weeklyTemplate = weeklyTemplate
                        store.saveProfile(profile)
                        dismiss()
                    }
                }
            }
            .onAppear { weeklyTemplate = store.profile.weeklyTemplate }
        }
    }
}
