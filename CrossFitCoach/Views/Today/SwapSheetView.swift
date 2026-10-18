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
                    Text("Žádná vhodná náhrada s aktuálním vybavením.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(candidates) { ex in
                        Button {
                            store.swapExercise(blockIndex: context.blockIndex, exerciseIndex: context.exerciseIndex, newExercise: ex)
                            dismiss()
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(ex.name)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.primary)
                                    Text("\(ex.pattern.label) · \(ex.category.label)")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(Color(.tertiaryLabel))
                            }
                        }
                    }
                }
            }
            .navigationTitle("Vyměnit „\(currentName)“")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Zavřít") { dismiss() } }
            }
        }
    }
}
