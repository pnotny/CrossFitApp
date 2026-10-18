import SwiftUI

// MARK: - Týdenní pásek dní

struct WeekStripView: View {
    @EnvironmentObject var store: AppStore

    private static let dayLabels = ["Po", "Út", "St", "Čt", "Pá", "So", "Ne"]

    private var weekDates: [String] { DateUtils.weekDatesAround(store.viewDate) }

    var body: some View {
        HStack(spacing: 6) {
            ForEach(Array(weekDates.enumerated()), id: \.offset) { idx, date in
                let isSelected = date == store.viewDate
                let isToday = date == DateUtils.todayString()
                let hasSaved = store.history.contains { $0.date == date }
                Button {
                    store.viewDate = date
                } label: {
                    VStack(spacing: 4) {
                        Text(Self.dayLabels[idx])
                            .font(.system(size: 11, weight: .bold))
                        Text(date.split(separator: "-").last.map(String.init) ?? "")
                            .font(.system(size: 14, weight: .heavy))
                        Circle()
                            .fill(hasSaved ? Color.accentColor : .clear)
                            .frame(width: 5, height: 5)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(isSelected ? Color.accentColor : Color(.secondarySystemBackground))
                    .foregroundColor(isSelected ? .white : (isToday ? .accentColor : .primary))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Hero karta s přehledem tréninku

struct WorkoutHeroCard: View {
    @EnvironmentObject var store: AppStore
    let workout: Workout
    let onTimer: (WorkoutBlock) -> Void
    let onShare: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                BadgeView(text: workout.dayTypeLabel, color: workout.dayType.color)
                Spacer()
                if store.currentWorkoutSaved {
                    BadgeView(text: "Uloženo", outline: true)
                }
            }

            HStack(spacing: 18) {
                statColumn(value: "\(workout.totalMinutes)", unit: "min")
                statColumn(value: "\(workout.estKcal)", unit: "kcal")
                statColumn(value: "\(workout.blocks.count)", unit: "bloky")
            }

            HStack(spacing: 10) {
                Button {
                    store.regenerate()
                } label: {
                    Label("Přegenerovat", systemImage: "arrow.triangle.2.circlepath")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button(action: onShare) {
                    Label("Sdílet", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            .font(.system(size: 14, weight: .semibold))

            HStack(spacing: 10) {
                if store.currentWorkoutSaved {
                    Button(role: .destructive) {
                        store.deleteCurrentWorkout()
                    } label: {
                        Text("Smazat uložený trénink").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                } else {
                    Button {
                        store.saveCurrentWorkout()
                    } label: {
                        Text("Uložit do historie").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .font(.system(size: 14, weight: .semibold))
        }
        .cardStyle()
    }

    private func statColumn(value: String, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).font(.system(size: 20, weight: .heavy))
            Text(unit).font(.system(size: 11, weight: .semibold)).foregroundColor(.secondary)
        }
    }
}

// MARK: - Výběr délky tréninku

struct DurationPickerCard: View {
    @EnvironmentObject var store: AppStore
    private let options = [20, 30, 45, 60, 90]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Délka tréninku")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.secondary)
            HStack(spacing: 8) {
                ForEach(options, id: \.self) { minutes in
                    ChipButton(label: "\(minutes) min", isActive: store.profile.timeAvailable == minutes) {
                        store.updateDuration(minutes)
                    }
                }
            }
        }
        .cardStyle()
    }
}

// MARK: - RPE karta

struct RpeCard: View {
    @EnvironmentObject var store: AppStore
    let currentRpe: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Jak náročný byl trénink? (RPE)")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.secondary)
            Text("Pomáhá to autoregulaci zátěže v dalších trénincích.")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            HStack(spacing: 6) {
                ForEach(1...10, id: \.self) { value in
                    Button {
                        store.saveRpe(value)
                    } label: {
                        Text("\(value)")
                            .font(.system(size: 13, weight: .bold))
                            .frame(width: 26, height: 26)
                            .background(currentRpe == value ? Color.accentColor : Color(.secondarySystemBackground))
                            .foregroundColor(currentRpe == value ? .white : .primary)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .cardStyle()
    }
}

// MARK: - Karta blok tréninku

struct BlockCardView: View {
    @EnvironmentObject var store: AppStore
    let blockIndex: Int
    let block: WorkoutBlock
    let onTimer: () -> Void
    let onSelectExercise: (Exercise) -> Void
    let onSwap: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(block.title)
                        .font(.system(size: 16, weight: .bold))
                    HStack(spacing: 6) {
                        BadgeView(text: block.formatLabel, color: .accentColor)
                        Text(block.scheme)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    if let cap = block.timeCap {
                        Text(cap)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                if block.format != .rest {
                    Button(action: onTimer) {
                        Image(systemName: "timer")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .buttonStyle(.bordered)
                    .clipShape(Circle())
                }
            }

            if !block.notes.isEmpty {
                Text(block.notes)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.accentColor.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            VStack(spacing: 8) {
                ForEach(Array(block.exercises.enumerated()), id: \.offset) { exIdx, ex in
                    ExerciseRowView(
                        exercise: ex,
                        onTap: {
                            if let full = ExerciseDatabase.byId[ex.exerciseId] {
                                onSelectExercise(full)
                            }
                        },
                        onSwap: { onSwap(exIdx) },
                        onWeightChange: { weight in
                            store.updateWeight(blockIndex: blockIndex, exerciseIndex: exIdx, weight: weight)
                        }
                    )
                }
            }
        }
        .cardStyle()
    }
}

// MARK: - Řádek cviku

struct ExerciseRowView: View {
    let exercise: WorkoutExercise
    let onTap: () -> Void
    let onSwap: () -> Void
    let onWeightChange: (Double) -> Void

    private var weightText: String {
        guard let weight = exercise.weight, let unit = exercise.unit else { return "" }
        let formatted = weight == weight.rounded() ? String(Int(weight)) : String(format: "%.1f", weight)
        return "\(formatted) \(unit)"
    }

    /// Jasně ukazuje, z čeho se pracovní váha počítá — např. "85% Front Squat 1RM"
    /// nebo "RX standard", pokud uživatel pro daný cvik maximum nezadal.
    private var loadSourceText: String {
        guard let source = exercise.loadSource else { return "" }
        if let pct = exercise.loadPct { return "\(pct)% \(source)" }
        return source
    }

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onTap) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(exercise.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                    HStack(spacing: 6) {
                        if !exercise.reps.isEmpty {
                            Text(exercise.reps)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.accentColor)
                        }
                        if !weightText.isEmpty {
                            Text(weightText)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                        if !loadSourceText.isEmpty {
                            Text(loadSourceText)
                                .font(.system(size: 11))
                                .foregroundColor(Color(.tertiaryLabel))
                        }
                    }
                }
            }
            .buttonStyle(.plain)
            Spacer()
            Button(action: onSwap) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
                    .padding(8)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}
