import SwiftUI
import UIKit

private struct ShareImageItem: Identifiable {
    let id = UUID()
    let image: UIImage
}

struct HistoryView: View {
    @EnvironmentObject var store: AppStore
    @State private var selectedWorkout: Workout?
    @State private var showAddPr = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    prSection

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Historie tréninků")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.secondary)

                        if store.history.isEmpty {
                            EmptyStateView(icon: "📅", text: "Zatím žádné uložené tréninky.")
                        } else {
                            VStack(spacing: 8) {
                                ForEach(store.history, id: \.date) { workout in
                                    Button { selectedWorkout = workout } label: {
                                        historyRow(workout)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .cardStyle()
                }
                .padding(16)
            }
            .navigationTitle("Historie")
            .background(Color(.systemGroupedBackground))
            .sheet(item: $selectedWorkout) { HistoryWorkoutDetailView(workout: $0) }
            .sheet(isPresented: $showAddPr) { AddPrSheetView() }
        }
    }

    private var prSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Osobní rekordy (1RM)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.secondary)
                Spacer()
                Button { showAddPr = true } label: {
                    Image(systemName: "plus.circle.fill")
                }
            }

            ForEach(OneRepMaxes.liftLabels, id: \.key) { lift in
                PrRowView(label: lift.label, current: store.profile.oneRM[lift.key], entries: store.prLog.filter { $0.lift == lift.key })
            }
        }
        .cardStyle()
    }

    private func historyRow(_ workout: Workout) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(workout.date)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                HStack(spacing: 6) {
                    BadgeView(text: workout.dayTypeLabel, color: workout.dayType.color)
                    if let rpe = workout.rpe {
                        Text("RPE \(rpe)")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(workout.totalMinutes) min").font(.system(size: 13, weight: .semibold))
                Text("\(workout.estKcal) kcal").font(.system(size: 11)).foregroundColor(.secondary)
            }
            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(Color(.tertiaryLabel))
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Řádek 1RM se sparkline

private struct PrRowView: View {
    let label: String
    let current: Double?
    let entries: [PrEntry]

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.system(size: 13, weight: .semibold))
                Text(current.map { "\(Int($0)) kg" } ?? "—")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            Spacer()
            SparklineView(values: entries.map { $0.value })
                .frame(width: 80, height: 28)
        }
        .padding(.vertical, 2)
    }
}

private struct SparklineView: View {
    let values: [Double]

    var body: some View {
        GeometryReader { geo in
            if values.count >= 2 {
                let minV = values.min() ?? 0
                let maxV = values.max() ?? 1
                let range = max(maxV - minV, 1)
                Path { path in
                    for (idx, value) in values.enumerated() {
                        let x = geo.size.width * CGFloat(idx) / CGFloat(values.count - 1)
                        let y = geo.size.height * (1 - CGFloat((value - minV) / range))
                        if idx == 0 { path.move(to: CGPoint(x: x, y: y)) } else { path.addLine(to: CGPoint(x: x, y: y)) }
                    }
                }
                .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
            } else {
                Color.clear
            }
        }
    }
}

// MARK: - Detail historického tréninku (read-only)

struct HistoryWorkoutDetailView: View {
    let workout: Workout
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var shareItem: ShareImageItem?
    @State private var exporting = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        BadgeView(text: workout.dayTypeLabel, color: workout.dayType.color)
                        if let rpe = workout.rpe {
                            BadgeView(text: "RPE \(rpe)", outline: true)
                        }
                    }
                    Text("\(workout.totalMinutes) min · \(workout.estKcal) kcal")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)

                    HStack(spacing: 10) {
                        Button {
                            if let image = ShareCardRenderer.render(workout: workout) {
                                shareItem = ShareImageItem(image: image)
                            } else {
                                store.toast("Export karty se nepodařil")
                            }
                        } label: {
                            Label("Sdílet", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)

                        if store.stravaAuth?.isConnected == true {
                            Button {
                                exporting = true
                                Task {
                                    await store.exportWorkoutToStrava(workout)
                                    exporting = false
                                }
                            } label: {
                                HStack {
                                    if exporting { ProgressView().tint(.white) }
                                    Text(workout.stravaActivityId != nil ? "Znovu na Strava" : "Na Strava")
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(Color(red: 0.98, green: 0.31, blue: 0.09))
                            .disabled(exporting)
                        }
                    }
                    .font(.system(size: 14, weight: .semibold))

                    ForEach(Array(workout.blocks.enumerated()), id: \.offset) { _, block in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(block.title).font(.system(size: 15, weight: .bold))
                                Spacer()
                                BadgeView(text: block.formatLabel, outline: true)
                            }
                            Text(block.scheme).font(.system(size: 12)).foregroundColor(.secondary)
                            ForEach(block.exercises, id: \.exerciseId) { ex in
                                HStack {
                                    Text(ex.name).font(.system(size: 13, weight: .semibold))
                                    Spacer()
                                    if !ex.reps.isEmpty {
                                        Text(ex.reps).font(.system(size: 12)).foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                        .cardStyle()
                    }
                }
                .padding(20)
            }
            .navigationTitle(workout.date)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Hotovo") { dismiss() } }
            }
            .sheet(item: $shareItem) { item in
                ActivityShareSheet(items: [item.image])
            }
        }
    }
}

// MARK: - Přidání PR

struct AddPrSheetView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var selectedLift = OneRepMaxes.liftLabels[0].key
    @State private var valueText = ""
    @State private var date = DateUtils.todayString()

    var body: some View {
        NavigationStack {
            Form {
                Picker("Cvik", selection: $selectedLift) {
                    ForEach(OneRepMaxes.liftLabels, id: \.key) { lift in
                        Text(lift.label).tag(lift.key)
                    }
                }
                TextField("Váha (kg)", text: $valueText)
                    .keyboardType(.decimalPad)
            }
            .navigationTitle("Nový PR")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Zavřít") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Uložit") {
                        if let value = Double(valueText.replacingOccurrences(of: ",", with: ".")), value > 0 {
                            store.addPrEntry(lift: selectedLift, value: value, date: date)
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}
