import SwiftUI

struct SwapContext: Identifiable {
    let id = UUID()
    let blockIndex: Int
    let exerciseIndex: Int
}

struct SwapSheetView: View {
    @EnvironmentObject var store: AppStore
    let context: SwapContext
    @Environment(\.dismiss) private var dismiss

    private var currentName: String {
        guard let w = store.currentWorkout, context.blockIndex < w.blocks.count,
              context.exerciseIndex < w.blocks[context.blockIndex].exercises.count else { return "" }
        return w.blocks[context.blockIndex].exercises[context.exerciseIndex].name
    }

    var body: some View {
        NavigationStack {
            List {
                let candidates = store.swapCandidates(blockIndex: context.blockIndex, exerciseIndex: context.exerciseIndex)
                if candidates.isEmpty {
                    Text(store.t("no_swap_candidates"))
                        .foregroundColor(DT.fgMuted)
                        .listRowBackground(DT.surface)
                } else {
                    ForEach(candidates) { ex in
                        Button {
                            store.swapExercise(blockIndex: context.blockIndex, exerciseIndex: context.exerciseIndex, newExercise: ex)
                            dismiss()
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(ex.name)
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(DT.fg)
                                    Text("\(ex.pattern.label(store.language)) · \(ex.category.label(store.language))")
                                        .font(.system(size: 12))
                                        .foregroundColor(DT.fgMuted)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(DT.fgFaint)
                            }
                        }
                        .listRowBackground(DT.surface)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(DT.bg)
            .navigationTitle("\(store.t("swap_title_prefix")) „\(currentName)“")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(store.t("close")) { dismiss() } }
            }
        }
    }
}
