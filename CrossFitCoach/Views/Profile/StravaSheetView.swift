import SwiftUI

/// Proklikávatelná sekce "Strava" z Profilu.
struct StravaSheetView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var stravaWorkerUrl = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 12) {
                        if store.stravaAuth?.isConnected == true {
                            HStack {
                                BadgeView(text: store.t("connected"), color: .green)
                                Spacer()
                                Button(store.t("disconnect"), role: .destructive) { store.disconnectStrava() }
                                    .foregroundColor(DT.danger)
                            }
                        } else {
                            Text(store.t("strava_hint"))
                                .font(.system(size: 12)).foregroundColor(DT.fgMuted)
                            TextField("https://strava-worker.example.workers.dev", text: $stravaWorkerUrl)
                                .textFieldStyle(.roundedBorder)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .keyboardType(.URL)
                            Button {
                                store.connectStrava(workerUrl: stravaWorkerUrl)
                            } label: {
                                Text(store.t("connect_strava"))
                            }
                            .buttonStyle(.dtPrimary)
                            .disabled(stravaWorkerUrl.isEmpty)
                        }
                    }
                    .cardStyle()
                }
                .padding(16)
            }
            .background(DT.bg)
            .navigationTitle("Strava")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(store.t("close")) { dismiss() } }
            }
            .onAppear { stravaWorkerUrl = store.stravaAuth?.workerUrl ?? "" }
        }
    }
}
