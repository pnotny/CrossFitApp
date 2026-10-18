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
    @State private var showCalendar = false

    /// Uložené, ale (ještě) ne odjeté tréninky — plán, ne záznam.
    private var savedWorkouts: [Workout] { store.history.filter { !$0.isCompleted } }
    /// Skutečně odjeté/splněné tréninky — odškrtnuté na kartě Dnes.
    private var completedWorkouts: [Workout] { store.history.filter { $0.isCompleted } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text(store.t("history_title"))
                    .font(DF.display(28))
                    .foregroundColor(DT.fg)

                calendarEntryRow
                prSection

                workoutSection(
                    title: store.t("saved_workouts"),
                    workouts: savedWorkouts,
                    emptyIcon: "📝",
                    emptyText: store.t("no_saved_workouts")
                )
                workoutSection(
                    title: store.t("completed_workouts"),
                    workouts: completedWorkouts,
                    emptyIcon: "✅",
                    emptyText: store.t("no_completed_workouts")
                )
            }
            .padding(16)
        }
        .background(DT.bg)
        .sheet(item: $selectedWorkout) { HistoryWorkoutDetailView(workout: $0) }
        .sheet(isPresented: $showAddPr) { AddPrSheetView() }
        .sheet(isPresented: $showCalendar) { CalendarSheetView() }
    }

    private var calendarEntryRow: some View {
        Button { showCalendar = true } label: {
            HStack(spacing: 10) {
                Image(systemName: "calendar")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(DT.accentText)
                Text(store.t("training_calendar"))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(DT.fg)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(DT.fgFaint)
            }
        }
        .buttonStyle(.plain)
        .cardStyle()
    }

    private func workoutSection(title: String, workouts: [Workout], emptyIcon: String, emptyText: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 12, weight: .heavy))
                .trackedUppercase(0.3)
                .foregroundColor(DT.fgMuted)

            if workouts.isEmpty {
                EmptyStateView(icon: emptyIcon, text: emptyText)
            } else {
                VStack(spacing: 8) {
                    ForEach(workouts, id: \.date) { workout in
                        SwipeToDeleteRow(onDelete: { store.deleteWorkout(for: workout.date) }) {
                            Button { selectedWorkout = workout } label: {
                                historyRow(workout)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private var prSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(store.t("personal_records"))
                    .font(.system(size: 12, weight: .heavy))
                    .trackedUppercase(0.3)
                    .foregroundColor(DT.fgMuted)
                Spacer()
                Button { showAddPr = true } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(DT.accentText)
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
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(DT.fg)
                HStack(spacing: 6) {
                    BadgeView(text: workout.dayType.label(store.language), color: workout.dayType.color)
                    if let rpe = workout.rpe {
                        Text("RPE \(rpe)")
                            .font(.system(size: 12))
                            .foregroundColor(DT.fgMuted)
                    }
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(workout.totalMinutes) min").font(.system(size: 13, weight: .bold)).foregroundColor(DT.fg)
                Text("\(workout.estKcal) kcal").font(.system(size: 11)).foregroundColor(DT.fgMuted)
            }
            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(DT.fgFaint)
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
                Text(label).font(.system(size: 13, weight: .bold)).foregroundColor(DT.fg)
                Text(current.map { "\(Int($0)) kg" } ?? "—")
                    .font(.system(size: 12))
                    .foregroundColor(DT.fgMuted)
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
                .stroke(DT.accentText, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
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
                        BadgeView(text: workout.dayType.label(store.language), color: workout.dayType.color)
                        if let rpe = workout.rpe {
                            BadgeView(text: "RPE \(rpe)", outline: true)
                        }
                    }
                    Text("\(workout.totalMinutes) min · \(workout.estKcal) kcal")
                        .font(.system(size: 13))
                        .foregroundColor(DT.fgMuted)

                    HStack(spacing: 10) {
                        Button {
                            if let image = ShareCardRenderer.render(workout: workout, language: store.language) {
                                shareItem = ShareImageItem(image: image)
                            } else {
                                store.toast(store.t("card_export_failed"))
                            }
                        } label: {
                            Label(store.t("share"), systemImage: "square.and.arrow.up")
                        }
                        .buttonStyle(.dtSecondary)

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
                                    Text(workout.stravaActivityId != nil ? store.t("resend_to_strava_short") : store.t("to_strava"))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 13)
                            }
                            .background(Color(red: 0.98, green: 0.31, blue: 0.09))
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                            .disabled(exporting)
                            .font(.system(size: 13, weight: .heavy))
                            .trackedUppercase(0.2)
                        }
                    }

                    ForEach(Array(workout.blocks.enumerated()), id: \.offset) { _, block in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(block.title).font(.system(size: 15, weight: .heavy)).foregroundColor(DT.fg)
                                Spacer()
                                BadgeView(text: block.format.label(store.language), outline: true)
                            }
                            Text(block.scheme).font(.system(size: 12)).foregroundColor(DT.fgMuted)
                            ForEach(block.exercises, id: \.exerciseId) { ex in
                                HStack {
                                    Text(ex.name).font(.system(size: 13, weight: .bold)).foregroundColor(DT.fg)
                                    Spacer()
                                    if !ex.reps.isEmpty {
                                        Text(ex.reps).font(.system(size: 12, weight: .semibold)).foregroundColor(DT.accentText)
                                    }
                                }
                            }
                        }
                        .cardStyle()
                    }
                }
                .padding(20)
            }
            .background(DT.bg)
            .navigationTitle(workout.date)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button(store.t("done")) { dismiss() } }
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
                Picker(store.t("exercise"), selection: $selectedLift) {
                    ForEach(OneRepMaxes.liftLabels, id: \.key) { lift in
                        Text(lift.label).tag(lift.key)
                    }
                }
                TextField(store.t("weight_kg"), text: $valueText)
                    .keyboardType(.decimalPad)
            }
            .scrollContentBackground(.hidden)
            .background(DT.bg)
            .navigationTitle(store.t("new_pr"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(store.t("close")) { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(store.t("save")) {
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
