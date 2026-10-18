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
                            .font(.system(size: 10, weight: .bold))
                            .trackedUppercase(0.2)
                        Text(date.split(separator: "-").last.map(String.init) ?? "")
                            .font(DF.display(15, weight: .heavy))
                        Circle()
                            .fill(hasSaved ? (isSelected ? DT.accentInk : DT.accentText) : .clear)
                            .frame(width: 4, height: 4)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(isSelected ? DT.accent : DT.surface)
                    .foregroundColor(isSelected ? DT.accentInk : (isToday ? DT.accentText : DT.fg))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
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
                completedToggle
            }

            HStack(spacing: 22) {
                statColumn(value: "\(workout.totalMinutes)", unit: "min")
                statColumn(value: "\(workout.estKcal)", unit: "kcal")
                statColumn(value: "\(workout.blocks.count)", unit: "bloky")
            }
            .padding(.vertical, 2)

            HStack(spacing: 10) {
                Button {
                    store.regenerate()
                } label: {
                    Label("Přegenerovat", systemImage: "arrow.triangle.2.circlepath")
                }
                .buttonStyle(.dtSecondary)

                Button(action: onShare) {
                    Label("Sdílet", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.dtSecondary)
            }

            if store.currentWorkoutSaved {
                Button(role: .destructive) {
                    store.deleteCurrentWorkout()
                } label: {
                    Text("Smazat uložený trénink")
                }
                .buttonStyle(.dtDestructive)
            } else {
                Button {
                    store.saveCurrentWorkout()
                } label: {
                    Text("Uložit trénink")
                }
                .buttonStyle(.dtPrimary)
            }
        }
        .padding(20)
        .background(DT.surfaceRaised)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            HStack(spacing: 0) {
                DT.accent.frame(width: 3)
                Spacer()
            }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        )
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(DT.line, lineWidth: 1))
    }

    /// Odškrtnutí "trénink jsem odjel" — nezávislé na uložení do historie.
    private var completedToggle: some View {
        Button {
            store.toggleWorkoutCompleted()
        } label: {
            HStack(spacing: 5) {
                Image(systemName: workout.isCompleted ? "checkmark.circle.fill" : "circle")
                Text(workout.isCompleted ? "Splněno" : "Označit splněno")
            }
            .font(.system(size: 11, weight: .heavy))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(workout.isCompleted ? DT.accent : DT.surface)
            .foregroundColor(workout.isCompleted ? DT.accentInk : DT.fgMuted)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func statColumn(value: String, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value).font(DF.display(26, weight: .heavy))
            Text(unit)
                .font(.system(size: 10, weight: .heavy))
                .trackedUppercase(0.4)
                .foregroundColor(DT.fgFaint)
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
                .font(.system(size: 12, weight: .heavy))
                .trackedUppercase(0.3)
                .foregroundColor(DT.fgMuted)
            // Horizontální ScrollView místo prosté HStack — 5 chipů (20–90 min) se na
            // užších telefonech nevejde do jednoho řádku a bez ní by celá karta
            // přetekla přes okraj obrazovky (viditelné hlavně u posledního chipu, 90 min).
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(options, id: \.self) { minutes in
                        ChipButton(label: "\(minutes) min", isActive: store.profile.timeAvailable == minutes) {
                            store.updateDuration(minutes)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
                .font(.system(size: 12, weight: .heavy))
                .trackedUppercase(0.3)
                .foregroundColor(DT.fgMuted)
            Text("Pomáhá to autoregulaci zátěže v dalších trénincích.")
                .font(.system(size: 12))
                .foregroundColor(DT.fgMuted)
            HStack(spacing: 6) {
                ForEach(1...10, id: \.self) { value in
                    Button {
                        store.saveRpe(value)
                    } label: {
                        Text("\(value)")
                            .font(.system(size: 13, weight: .heavy))
                            .frame(width: 26, height: 26)
                            .background(currentRpe == value ? DT.accent : DT.surfaceRaised)
                            .foregroundColor(currentRpe == value ? DT.accentInk : DT.fg)
                            .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
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

    /// AI poznámka pro tenhle blok, pokud se povedlo ji načíst — jinak nil
    /// a karta ukáže statickou `block.notes` z generátoru.
    private var aiNote: String? {
        guard let notes = store.aiBlockNotes, blockIndex < notes.count else { return nil }
        return notes[blockIndex]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(block.title)
                        .font(.system(size: 15, weight: .heavy))
                    Text("\(block.formatLabel) · \(block.scheme)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(DT.fgMuted)
                    if let cap = block.timeCap {
                        Text(cap)
                            .font(.system(size: 12))
                            .foregroundColor(DT.fgMuted)
                    }
                }
                Spacer()
                if block.format != .rest {
                    Button(action: onTimer) {
                        Image(systemName: "timer")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(DT.accentText)
                            .frame(width: 34, height: 34)
                            .background(DT.surfaceRaised)
                            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 9, style: .continuous).stroke(DT.line, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }

            let displayNotes = aiNote ?? block.notes
            if !displayNotes.isEmpty {
                HStack(alignment: .top, spacing: 6) {
                    if aiNote != nil {
                        Image(systemName: "sparkles")
                            .font(.system(size: 11))
                            .foregroundColor(DT.accentText)
                    }
                    Text(displayNotes)
                        .font(.system(size: 12))
                        .foregroundColor(DT.fgMuted)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(DT.accent.opacity(0.1))
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
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(DT.fg)
                    HStack(spacing: 6) {
                        if !exercise.reps.isEmpty {
                            Text(exercise.reps)
                                .font(.system(size: 12, weight: .heavy))
                                .foregroundColor(DT.accentText)
                        }
                        if !weightText.isEmpty {
                            Text(weightText)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(DT.fgMuted)
                        }
                        if !loadSourceText.isEmpty {
                            Text(loadSourceText)
                                .font(.system(size: 11))
                                .foregroundColor(DT.fgFaint)
                        }
                    }
                }
            }
            .buttonStyle(.plain)
            Spacer()
            Button(action: onSwap) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(DT.fgFaint)
                    .frame(width: 26, height: 26)
                    .background(DT.surfaceRaised)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}
