import SwiftUI

/// Proklikávatelná sekce "1RM" z Profilu — osobní maxima pro dopočet zátěže.
struct OneRMSheetView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var oneRMText: [String: String] = [:]

    private func formatValue(_ v: Double) -> String {
        v == v.rounded() ? String(Int(v)) : String(format: "%.1f", v)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(OneRepMaxes.liftLabels, id: \.key) { lift in
                            HStack {
                                Text(lift.label).font(.system(size: 14)).foregroundColor(DT.fg)
                                Spacer()
                                TextField("kg", text: Binding(
                                    get: { oneRMText[lift.key] ?? "" },
                                    set: { oneRMText[lift.key] = $0 }
                                ))
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 70)
                                .textFieldStyle(.roundedBorder)
                                Text("kg").font(.system(size: 13)).foregroundColor(DT.fgMuted)
                            }
                        }
                    }
                    .cardStyle()
                }
                .padding(16)
            }
            .background(DT.bg)
            .navigationTitle(store.t("one_rm"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(store.t("close")) { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(store.t("save")) {
                        var profile = store.profile
                        for lift in OneRepMaxes.liftLabels {
                            let text = (oneRMText[lift.key] ?? "").replacingOccurrences(of: ",", with: ".")
                            profile.oneRM[lift.key] = Double(text)
                        }
                        store.saveProfile(profile)
                        dismiss()
                    }
                }
            }
            .onAppear {
                for lift in OneRepMaxes.liftLabels {
                    oneRMText[lift.key] = store.profile.oneRM[lift.key].map { formatValue($0) } ?? ""
                }
            }
        }
    }
}
