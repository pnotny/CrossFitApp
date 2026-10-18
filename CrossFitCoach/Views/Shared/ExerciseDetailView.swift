import SwiftUI

/// Detail cviku s přepínáním úrovní — použito z Today (info tlačítko) i z Library.
struct ExerciseDetailView: View {
    @EnvironmentObject var store: AppStore
    let exercise: Exercise
    @State private var tier: LevelTier
    @Environment(\.dismiss) private var dismiss
    /// Cache originál (česky) → AI překlad (anglicky), jen pro tuhle obrazovku —
    /// dlouhodobá cache je v AppStore.translateTexts, tohle jen drží výsledek pro UI.
    @State private var translations: [String: String] = [:]

    init(exercise: Exercise, initialTier: LevelTier = .rx) {
        self.exercise = exercise
        _tier = State(initialValue: initialTier)
    }

    /// Anglický překlad daného (českého) textu, pokud appka běží v angličtině
    /// a překlad se podařilo načíst — jinak originál beze změny.
    private func tr(_ cs: String) -> String {
        guard store.language == .en else { return cs }
        return translations[cs] ?? cs
    }

    private func loadTranslationsIfNeeded() async {
        guard store.language == .en else { return }
        let info = exercise.levels.info(for: tier)
        let candidates = [info.desc, info.criteria, exercise.muscles.joined(separator: ", ")] + exercise.cues + exercise.mistakes
        let missing = candidates.filter { !$0.isEmpty && translations[$0] == nil }
        guard !missing.isEmpty else { return }
        let results = await store.translateTexts(missing)
        for (original, translated) in zip(missing, results) {
            translations[original] = translated
        }
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
                            BadgeView(text: exercise.category.label(store.language), outline: true)
                            BadgeView(text: exercise.pattern.label(store.language), outline: true)
                        }
                        ChipGrid {
                            ForEach(exercise.equipment, id: \.self) { eq in
                                BadgeView(text: eq.label(store.language), outline: true)
                            }
                        }
                    }

                    Picker(store.t("level"), selection: $tier) {
                        ForEach(LevelTier.allCases, id: \.self) { t in
                            Text(t.label).tag(t)
                        }
                    }
                    .pickerStyle(.segmented)

                    let info = exercise.levels.info(for: tier)
                    detailSection(title: store.t("level_description"), text: tr(info.desc))
                    detailSection(title: store.t("next_level_criteria"), text: tr(info.criteria))
                    detailSection(title: store.t("muscles_worked"), text: tr(exercise.muscles.joined(separator: ", ")))
                    detailListSection(title: store.t("coaching_cues"), items: exercise.cues.map(tr), symbol: "checkmark", color: .green)
                    detailListSection(title: store.t("common_mistakes"), items: exercise.mistakes.map(tr), symbol: "xmark", color: .red)
                }
                .padding(20)
            }
            .background(DT.bg)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(store.t("done")) { dismiss() }
                }
            }
            .task(id: tier) { await loadTranslationsIfNeeded() }
            .onChange(of: store.language) { _ in Task { await loadTranslationsIfNeeded() } }
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
