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

    /// Anglický překlad daného (českého) textu. Vrací nil, dokud appka běží
    /// v angličtině a překlad ještě nemá (ani v lokálním stavu, ani v trvalé
    /// cache) — v tom okamžiku UI ukáže placeholder místo blikajícího
    /// "nejdřív česky, pak anglicky".
    private func tr(_ cs: String) -> String? {
        guard store.language == .en else { return cs }
        if let t = translations[cs] { return t }
        return store.cachedTranslation(cs)
    }

    /// Svaly se překládají jednotlivě (stejná slova se opakují napříč cviky, takže
    /// to sdílí cache mnohem lépe než překlad celého spojeného řetězce) a spojí
    /// se zpátky čárkou až pro zobrazení. Nil, dokud se nepřeloží úplně všechny.
    private func translatedMusclesText() -> String? {
        let parts = exercise.muscles.map { tr($0) }
        guard parts.allSatisfy({ $0 != nil }) else { return nil }
        return parts.compactMap { $0 }.joined(separator: ", ")
    }

    private func loadTranslationsIfNeeded() async {
        guard store.language == .en else { return }
        let info = exercise.levels.info(for: tier)
        let candidates = [info.desc, info.criteria] + exercise.muscles + exercise.cues + exercise.mistakes
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
                    detailSection(title: store.t("muscles_worked"), text: translatedMusclesText())
                    detailListSection(title: store.t("coaching_cues"), items: exercise.cues, translator: tr, symbol: "checkmark", color: .green)
                    detailListSection(title: store.t("common_mistakes"), items: exercise.mistakes, translator: tr, symbol: "xmark", color: .red)
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
    private func detailSection(title: String, text: String?) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .trackedUppercase(0.3)
                .font(.system(size: 11, weight: .heavy))
                .foregroundColor(DT.fgMuted)
            if let text {
                Text(text)
                    .font(.system(size: 15))
                    .foregroundColor(DT.fg)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                translationPlaceholder(width: 220, height: 15)
            }
        }
    }

    @ViewBuilder
    private func detailListSection(title: String, items: [String], translator: (String) -> String?, symbol: String, color: Color) -> some View {
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
                    if let translated = translator(item) {
                        Text(translated)
                            .font(.system(size: 14))
                            .foregroundColor(DT.fg)
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        translationPlaceholder(width: 180, height: 14)
                    }
                }
            }
        }
    }

    /// Jednoduchý placeholder pruh, dokud čekáme na AI překlad — ať appka nejdřív
    /// na okamžik neukáže český text, než ho vzápětí nahradí anglickým.
    private func translationPlaceholder(width: CGFloat, height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(DT.surface)
            .frame(width: width, height: height)
            .padding(.top, 2)
    }
}
