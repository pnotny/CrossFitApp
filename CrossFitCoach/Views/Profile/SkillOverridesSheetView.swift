import SwiftUI

/// Proklikávatelná sekce "Úroveň technických dovedností" z Profilu — manuální
/// přeskočení řetězu dovedností (viz `SkillProgression`).
struct SkillOverridesSheetView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var overrides: [String: String] = [:]

    private func skillChainLabel(_ chainId: String) -> String {
        store.t("skill_chain_\(chainId.replacingOccurrences(of: "-", with: "_"))")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(store.t("skill_overrides_hint"))
                            .font(.system(size: 12)).foregroundColor(DT.fgMuted)
                        ForEach(SkillProgression.chains, id: \.id) { chain in
                            HStack {
                                Text(skillChainLabel(chain.id))
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(DT.fg)
                                Spacer()
                                Picker("", selection: Binding(
                                    get: { overrides[chain.id] ?? chain.steps[0] },
                                    set: { newValue in
                                        if newValue == chain.steps[0] {
                                            overrides.removeValue(forKey: chain.id)
                                        } else {
                                            overrides[chain.id] = newValue
                                        }
                                    }
                                )) {
                                    ForEach(chain.steps, id: \.self) { stepId in
                                        Text(ExerciseDatabase.byId[stepId]?.name ?? stepId).tag(stepId)
                                    }
                                }
                            }
                        }
                    }
                    .cardStyle()
                }
                .padding(16)
            }
            .background(DT.bg)
            .navigationTitle(store.t("skill_overrides"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(store.t("close")) { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(store.t("save")) {
                        var profile = store.profile
                        profile.skillOverrides = overrides.isEmpty ? nil : overrides
                        store.saveProfile(profile)
                        dismiss()
                    }
                }
            }
            .onAppear { overrides = store.profile.skillOverrides ?? [:] }
        }
    }
}
