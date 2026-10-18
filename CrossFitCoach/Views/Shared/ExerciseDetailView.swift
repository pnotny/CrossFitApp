import SwiftUI

/// Detail cviku s přepínáním úrovní — použito z Today (info tlačítko) i z Library.
struct ExerciseDetailView: View {
    let exercise: Exercise
    @State private var tier: LevelTier
    @Environment(\.dismiss) private var dismiss

    init(exercise: Exercise, initialTier: LevelTier = .rx) {
        self.exercise = exercise
        _tier = State(initialValue: initialTier)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(exercise.name)
                            .font(DF.display(22, weight: .heavy))
                            .foregroundColor(DT.fg)
                        HStack(spacing: 6) {
                            BadgeView(text: exercise.category.label, outline: true)
                            BadgeView(text: exercise.pattern.label, outline: true)
                        }
                        ChipGrid {
                            ForEach(exercise.equipment, id: \.self) { eq in
                                BadgeView(text: eq.label, outline: true)
                            }
                        }
                    }

                    Picker("Úroveň", selection: $tier) {
                        ForEach(LevelTier.allCases, id: \.self) { t in
                            Text(t.label).tag(t)
                        }
                    }
                    .pickerStyle(.segmented)

                    let info = exercise.levels.info(for: tier)
                    detailSection(title: "Popis úrovně", text: info.desc)
                    detailSection(title: "Kritérium postupu na další úroveň", text: info.criteria)
                    detailSection(title: "Zapojené svaly", text: exercise.muscles.joined(separator: ", "))
                    detailListSection(title: "Coaching cues", items: exercise.cues, symbol: "checkmark", color: .green)
                    detailListSection(title: "Časté chyby", items: exercise.mistakes, symbol: "xmark", color: .red)
                }
                .padding(20)
            }
            .background(DT.bg)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Hotovo") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private func detailSection(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .trackedUppercase(0.3)
                .font(.system(size: 11, weight: .heavy))
                .foregroundColor(DT.fgMuted)
            Text(text)
                .font(.system(size: 15))
                .foregroundColor(DT.fg)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private func detailListSection(title: String, items: [String], symbol: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .trackedUppercase(0.3)
                .font(.system(size: 11, weight: .heavy))
                .foregroundColor(DT.fgMuted)
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: symbol)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(color)
                        .padding(.top, 3)
                    Text(item)
                        .font(.system(size: 14))
                        .foregroundColor(DT.fg)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}
