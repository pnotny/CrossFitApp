import SwiftUI

/// Proklikávatelná sekce "Základní údaje" z Profilu — pohlaví, váha, úroveň.
struct BasicsSheetView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var gender: Gender = .male
    @State private var bodyweight: Double = 80
    @State private var level: AthleteLevel = .intermediate

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 12) {
                        SegmentedPicker(options: Gender.allCases.map { ($0, $0.label(store.language)) }, selection: $gender)

                        HStack {
                            Text(store.t("bodyweight")).font(.system(size: 14)).foregroundColor(DT.fg)
                            Spacer()
                            TextField("kg", value: $bodyweight, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 70)
                                .textFieldStyle(.roundedBorder)
                            Text("kg").font(.system(size: 13)).foregroundColor(DT.fgMuted)
                        }

                        Text(store.t("level")).font(.system(size: 11, weight: .heavy)).trackedUppercase(0.2).foregroundColor(DT.fgMuted)
                        SegmentedPicker(options: AthleteLevel.allCases.map { ($0, $0.label) }, selection: $level)
                    }
                    .cardStyle()
                }
                .padding(16)
            }
            .background(DT.bg)
            .navigationTitle(store.t("basics"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(store.t("close")) { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(store.t("save")) {
                        var profile = store.profile
                        profile.gender = gender
                        profile.bodyweight = bodyweight
                        profile.level = level
                        store.saveProfile(profile)
                        dismiss()
                    }
                }
            }
            .onAppear {
                gender = store.profile.gender
                bodyweight = store.profile.bodyweight
                level = store.profile.level
            }
        }
    }
}
