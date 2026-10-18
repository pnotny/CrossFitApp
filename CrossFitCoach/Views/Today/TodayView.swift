import SwiftUI
import UIKit

private struct ShareImageItem: Identifiable {
    let id = UUID()
    let image: UIImage
}

struct TodayView: View {
    @EnvironmentObject var store: AppStore
    @State private var selectedExercise: Exercise?
    @State private var swapContext: SwapContext?
    @State private var timerConfig: TimerConfig?
    @State private var shareItem: ShareImageItem?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    WeekStripView()

                    if let workout = store.currentWorkout {
                        WorkoutHeroCard(
                            workout: workout,
                            onTimer: { block in presentTimer(for: block, workout: workout) },
                            onShare: { presentShare(for: workout) }
                        )

                        DurationPickerCard()

                        ForEach(Array(workout.blocks.enumerated()), id: \.offset) { blockIdx, block in
                            BlockCardView(
                                blockIndex: blockIdx,
                                block: block,
                                onTimer: { presentTimer(for: block, workout: workout) },
                                onSelectExercise: { selectedExercise = $0 },
                                onSwap: { exIdx in swapContext = SwapContext(blockIndex: blockIdx, exerciseIndex: exIdx) }
                            )
                        }

                        if store.currentWorkoutSaved {
                            RpeCard(currentRpe: workout.rpe)
                        }

                        if store.stravaAuth?.isConnected == true {
                            Button {
                                Task { await store.exportCurrentWorkoutToStrava() }
                            } label: {
                                HStack {
                                    if store.stravaExportInFlight {
                                        ProgressView().tint(.white)
                                    }
                                    Text(workout.stravaActivityId != nil ? "Znovu odeslat na Strava" : "Odeslat na Strava")
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 13)
                            }
                            .background(Color(red: 0.98, green: 0.31, blue: 0.09))
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                            .disabled(store.stravaExportInFlight || !store.currentWorkoutSaved)
                            .font(.system(size: 13, weight: .heavy))
                            .trackedUppercase(0.2)
                        }
                    } else {
                        EmptyStateView(icon: "🏋️", text: "Trénink se připravuje…")
                    }
                }
                .padding(16)
            }
            .navigationTitle("Dnes")
            .background(DT.bg)
        }
        .sheet(item: $selectedExercise) { ex in
            ExerciseDetailView(exercise: ex)
        }
        .sheet(item: $swapContext) { ctx in
            SwapSheetView(context: ctx)
        }
        .sheet(item: $timerConfig) { config in
            TimerSheetView(config: config)
        }
        .sheet(item: $shareItem) { item in
            ActivityShareSheet(items: [item.image])
        }
    }

    private func presentTimer(for block: WorkoutBlock, workout: Workout) {
        timerConfig = TimerConfig(
            title: block.title,
            formatLabel: block.formatLabel,
            format: block.format,
            dayType: workout.dayType,
            durationMin: block.durationMin,
            timeCapLabel: block.timeCap,
            exercises: block.exercises.map { $0.name }
        )
    }

    private func presentShare(for workout: Workout) {
        if let image = ShareCardRenderer.render(workout: workout) {
            shareItem = ShareImageItem(image: image)
        } else {
            store.toast("Export karty se nepodařil")
        }
    }
}

extension TimerConfig: Identifiable {
    var id: String { "\(title)-\(durationMin)-\(formatLabel)" }
}
