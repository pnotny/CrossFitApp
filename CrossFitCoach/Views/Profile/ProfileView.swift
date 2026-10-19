import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var store: AppStore
    @State private var draft = AthleteProfile()
    @State private var oneRMText: [String: String] = [:]
    @State private var stravaWorkerUrl = ""
    @State private var showLevelUpConfirm = false
    @State private var levelUpDismissed = false
    @State private var showAccountSheet = false

    private static let dayLabelsCS = ["Po", "Út", "St", "Čt", "Pá", "So", "Ne"]
    private static let dayLabelsEN = ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
    private static let preferredFormatOptions: [WorkoutFormat] = [.emom, .amrap, .forTime, .chipper, .tabata, .intervals, .steady]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text(store.t("profile_title"))
                    .font(DF.display(28))
                    .foregroundColor(DT.fg)

                basicsCard
                if let suggestion = levelUpSuggestion {
                    levelUpCard(suggestion)
                }
                oneRMCard
                equipmentCard
                excludedPatternsCard
                skillOverridesCard
                goalCard
                preferredFormatsCard
                autoregCard
                weeklyTemplateCard
                stravaCard
                appearanceCard
                languageCard
                accountCard

                HStack(spacing: 10) {
                    Button {
                        store.loadTestProfile()
                        loadDraft()
                    } label: {
                        Text(store.t("test_profile"))
                    }
                    .buttonStyle(.dtSecondary)

                    Button {
                        store.saveProfile(draft)
                    } label: {
                        Text(store.t("save_profile"))
                    }
                    .buttonStyle(.dtPrimary)
                }
            }
            .padding(16)
        }
        .background(DT.bg)
        .onAppear { loadDraft() }
        .sheet(isPresented: $showAccountSheet) { AccountSheetView() }
    }

    private func loadDraft() {
        draft = store.profile
        stravaWorkerUrl = store.stravaAuth?.workerUrl ?? ""
        for lift in OneRepMaxes.liftLabels {
            oneRMText[lift.key] = draft.oneRM[lift.key].map { formatValue($0) } ?? ""
        }
    }

    private func formatValue(_ v: Double) -> String {
        v == v.rounded() ? String(Int(v)) : String(format: "%.1f", v)
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .heavy))
            .trackedUppercase(0.3)
            .foregroundColor(DT.fgMuted)
    }

    // MARK: - Základní údaje

    private var basicsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(store.t("basics"))

            SegmentedPicker(options: Gender.allCases.map { ($0, $0.label(store.language)) }, selection: $draft.gender)

            HStack {
                Text(store.t("bodyweight")).font(.system(size: 14)).foregroundColor(DT.fg)
                Spacer()
                TextField("kg", value: $draft.bodyweight, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 70)
                    .textFieldStyle(.roundedBorder)
                Text("kg").font(.system(size: 13)).foregroundColor(DT.fgMuted)
            }

            Text(store.t("level")).font(.system(size: 11, weight: .heavy)).trackedUppercase(0.2).foregroundColor(DT.fgMuted)
            SegmentedPicker(options: AthleteLevel.allCases.map { ($0, $0.label) }, selection: $draft.level)
        }
        .cardStyle()
    }

    // MARK: - Posun na další úroveň (jen návrh, nikdy automaticky)

    /// Kolik odcvičených (uložených) tréninků typicky stačí, než má smysl
    /// zvážit posun na další úroveň — hrubý odhad, ne tvrdé kritérium.
    private static let levelUpThresholds: [AthleteLevel: Int] = [.beginner: 12, .intermediate: 24, .advanced: 36]

    private var levelUpSuggestion: AthleteLevel? {
        guard !levelUpDismissed, draft.level == store.profile.level, let next = draft.level.next else { return nil }
        guard let threshold = Self.levelUpThresholds[draft.level] else { return nil }
        return store.history.count >= threshold ? next : nil
    }

    private func levelUpCard(_ next: AthleteLevel) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.up.circle.fill").foregroundColor(DT.accentText)
                Text(store.t("level_up_question")).font(.system(size: 14, weight: .bold)).foregroundColor(DT.fg)
            }
            Text(store.language == .en
                ? "You've trained \(store.history.count) workouts at \(draft.level.label) level. Consider moving to \(next.label) — exercises and weights will adjust, but nothing changes without your confirmation."
                : "Trénuješ už \(store.history.count) tréninků na úrovni \(draft.level.label). Zvaž posun na \(next.label) — cviky i váhy se tomu přizpůsobí, ale nic se nezmění bez tvého potvrzení.")
                .font(.system(size: 13))
                .foregroundColor(DT.fgMuted)
            HStack(spacing: 10) {
                Button(store.t("not_now")) { levelUpDismissed = true }
                    .buttonStyle(.dtSecondary)
                Button("\(store.t("move_to")) \(next.label)") { showLevelUpConfirm = true }
                    .buttonStyle(.dtPrimary)
            }
        }
        .cardStyle()
        .alert("\(store.t("move_to")) \(next.label)?", isPresented: $showLevelUpConfirm) {
            Button(store.t("cancel"), role: .cancel) {}
            Button(store.t("move")) {
                draft.level = next
                store.saveProfile(draft)
            }
        } message: {
            Text(store.language == .en
                ? "Future workouts will use \(next.label) level — harder exercises and higher working weights."
                : "Příští tréninky budou počítat s úrovní \(next.label) — náročnější cviky i vyšší pracovní váhy.")
        }
    }

    // MARK: - 1RM

    private var oneRMCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(store.t("one_rm"))
            ForEach(OneRepMaxes.liftLabels, id: \.key) { lift in
                HStack {
                    Text(lift.label).font(.system(size: 14)).foregroundColor(DT.fg)
                    Spacer()
                    TextField("kg", text: Binding(
                        get: { oneRMText[lift.key] ?? "" },
                        set: { newValue in
                            oneRMText[lift.key] = newValue
                            draft.oneRM[lift.key] = Double(newValue.replacingOccurrences(of: ",", with: "."))
                        }
                    ))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 70)
                    .textFieldStyle(.roundedBorder)
                    Text("kg").font(.system(size: 13)).foregroundColor(DT.fgMuted)
                }
            }
        }
        .cardStyle()
    }

    // MARK: - Vybavení

    private var equipmentCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(store.t("available_equipment"))
            ChipGrid {
                ForEach(Equipment.allCases.filter { $0 != .none }, id: \.self) { eq in
                    ChipButton(label: eq.label(store.language), isActive: draft.equipment.contains(eq)) {
                        toggle(eq, in: \.equipment)
                    }
                }
            }
        }
        .cardStyle()
    }

    // MARK: - Vyloučené vzory pohybu

    private var excludedPatternsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(store.t("excluded_patterns"))
            Text(store.t("excluded_patterns_hint"))
                .font(.system(size: 12)).foregroundColor(DT.fgMuted)
            ChipGrid {
                ForEach(MovementPattern.allCases, id: \.self) { pattern in
                    ChipButton(label: pattern.label(store.language), isActive: draft.excludedPatterns.contains(pattern), danger: true) {
                        toggle(pattern, in: \.excludedPatterns)
                    }
                }
            }
        }
        .cardStyle()
    }

    private func skillChainLabel(_ chainId: String) -> String {
        store.t("skill_chain_\(chainId.replacingOccurrences(of: "-", with: "_"))")
    }

    private var skillOverridesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(store.t("skill_overrides"))
            Text(store.t("skill_overrides_hint"))
                .font(.system(size: 12)).foregroundColor(DT.fgMuted)
            ForEach(SkillProgression.chains, id: \.id) { chain in
                HStack {
                    Text(skillChainLabel(chain.id))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(DT.fg)
                    Spacer()
                    Picker("", selection: Binding(
                        get: { draft.skillOverrides?[chain.id] ?? chain.steps[0] },
                        set: { newValue in
                            var overrides = draft.skillOverrides ?? [:]
                            if newValue == chain.steps[0] {
                                overrides.removeValue(forKey: chain.id)
                            } else {
                                overrides[chain.id] = newValue
                            }
                            draft.skillOverrides = overrides.isEmpty ? nil : overrides
                        }
                    )) {
                        ForEach(chain.steps, id: \.self) { stepId in
                            Text(ExerciseDatabase.byId[stepId]?.name ?? stepId).tag(stepId)
                        }
                    }
                }
            }
        }
        .cardStyle()
    }

    // MARK: - Cíl

    private var goalCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(store.t("main_goal"))
            SegmentedPicker(options: Goal.allCases.map { ($0, $0.label(store.language)) }, selection: $draft.goal)
        }
        .cardStyle()
    }

    // MARK: - Oblíbené formáty metconu

    private var preferredFormatsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(store.t("preferred_formats"))
            ChipGrid {
                ForEach(Self.preferredFormatOptions, id: \.self) { format in
                    ChipButton(label: format.label(store.language), isActive: draft.preferredFormats.contains(format)) {
                        toggle(format, in: \.preferredFormats)
                    }
                }
            }
        }
        .cardStyle()
    }

    // MARK: - Autoregulace

    private var autoregCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(isOn: $draft.autoregEnabled) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(store.t("autoreg_title")).font(.system(size: 14, weight: .bold)).foregroundColor(DT.fg)
                    Text(store.t("autoreg_hint"))
                        .font(.system(size: 12)).foregroundColor(DT.fgMuted)
                }
            }
            .tint(DT.accent)
        }
        .cardStyle()
    }

    // MARK: - Týdenní šablona

    private var weeklyTemplateCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(store.t("weekly_plan"))
            ForEach(0..<7, id: \.self) { idx in
                HStack {
                    Text(store.language == .en ? Self.dayLabelsEN[idx] : Self.dayLabelsCS[idx])
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(DT.fg)
                        .frame(width: 32, alignment: .leading)
                    Spacer()
                    Picker("", selection: Binding(
                        get: { idx < draft.weeklyTemplate.count ? draft.weeklyTemplate[idx] : .rest },
                        set: { newValue in
                            while draft.weeklyTemplate.count < 7 { draft.weeklyTemplate.append(.rest) }
                            draft.weeklyTemplate[idx] = newValue
                        }
                    )) {
                        ForEach(DayType.allCases, id: \.self) { day in
                            Text(day.label(store.language)).tag(day)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(DT.accentText)
                }
            }
        }
        .cardStyle()
    }

    // MARK: - Strava

    private var stravaCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Strava")
            if store.stravaAuth?.isConnected == true {
                HStack {
                    BadgeView(text: store.t("connected"), color: .green)
                    Spacer()
                    Button(store.t("disconnect"), role: .destructive) { store.disconnectStrava() }
                        .foregroundColor(DT.danger)
                }
            } else {
                Text(store.t("strava_hint"))
                    .font(.system(size: 12)).foregroundColor(DT.fgMuted)
                TextField("https://strava-worker.example.workers.dev", text: $stravaWorkerUrl)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .keyboardType(.URL)
                Button {
                    store.connectStrava(workerUrl: stravaWorkerUrl)
                } label: {
                    Text(store.t("connect_strava"))
                }
                .buttonStyle(.dtPrimary)
                .disabled(stravaWorkerUrl.isEmpty)
            }
        }
        .cardStyle()
    }

    // MARK: - Vzhled

    private var appearanceCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(store.t("theme")).font(.system(size: 14, weight: .bold)).foregroundColor(DT.fg)
                Text(themeLabel).font(.system(size: 12)).foregroundColor(DT.fgMuted)
            }
            Spacer()
            Button(store.t("change")) { store.cycleTheme() }
                .font(.system(size: 13, weight: .heavy))
                .foregroundColor(DT.accentText)
        }
        .cardStyle()
    }

    private var themeLabel: String {
        switch store.theme {
        case .auto: return store.t("theme_auto")
        case .light: return store.t("theme_light")
        case .dark: return store.t("theme_dark")
        }
    }

    // MARK: - Jazyk

    private var languageCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(store.t("language")).font(.system(size: 14, weight: .bold)).foregroundColor(DT.fg)
                Text(store.language.label).font(.system(size: 12)).foregroundColor(DT.fgMuted)
            }
            Spacer()
            Button(store.t("change")) { store.cycleLanguage() }
                .font(.system(size: 13, weight: .heavy))
                .foregroundColor(DT.accentText)
        }
        .cardStyle()
    }

    // MARK: Účet

    private var accountCard: some View {
        Button { showAccountSheet = true } label: {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(store.t("account")).font(.system(size: 14, weight: .bold)).foregroundColor(DT.fg)
                    Text(store.authUser?.username ?? "—").font(.system(size: 12)).foregroundColor(DT.fgMuted)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(DT.fgFaint)
            }
        }
        .buttonStyle(.plain)
        .cardStyle()
    }

    // MARK: - Pomocné

    private func toggle<T: Equatable>(_ value: T, in keyPath: WritableKeyPath<AthleteProfile, [T]>) {
        if draft[keyPath: keyPath].contains(value) {
            draft[keyPath: keyPath].removeAll { $0 == value }
        } else {
            draft[keyPath: keyPath].append(value)
        }
    }
}
