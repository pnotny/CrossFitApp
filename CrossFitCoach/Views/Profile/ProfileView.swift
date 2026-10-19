import SwiftUI

/// Profil jako krátký přehled s proklikávatelnými řádky do sheetů (stejný vzor
/// jako "Účet", viz AccountSheetView) — místo jedné nekonečné karty plné
/// nastavování, ať je hlavní stránka na první pohled přehledná.
struct ProfileView: View {
    @EnvironmentObject var store: AppStore
    @State private var showLevelUpConfirm = false
    @State private var levelUpDismissed = false
    @State private var showBasicsSheet = false
    @State private var showOneRMSheet = false
    @State private var showEquipmentSheet = false
    @State private var showExcludedPatternsSheet = false
    @State private var showSkillOverridesSheet = false
    @State private var showTrainingPreferencesSheet = false
    @State private var showWeeklyTemplateSheet = false
    @State private var showStravaSheet = false
    @State private var showAccountSheet = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text(store.t("profile_title"))
                    .font(DF.display(28))
                    .foregroundColor(DT.fg)

                if let suggestion = levelUpSuggestion {
                    levelUpCard(suggestion)
                }

                sectionHeader(store.t("training_section"))
                navigationRow(title: store.t("basics"), subtitle: basicsSubtitle) { showBasicsSheet = true }
                navigationRow(title: store.t("one_rm"), subtitle: oneRMSubtitle) { showOneRMSheet = true }
                navigationRow(title: store.t("available_equipment"), subtitle: equipmentSubtitle) { showEquipmentSheet = true }
                navigationRow(title: store.t("excluded_patterns"), subtitle: excludedPatternsSubtitle) { showExcludedPatternsSheet = true }
                navigationRow(title: store.t("skill_overrides"), subtitle: skillOverridesSubtitle) { showSkillOverridesSheet = true }
                navigationRow(title: store.t("training_preferences"), subtitle: store.profile.goal.label(store.language)) { showTrainingPreferencesSheet = true }
                navigationRow(title: store.t("weekly_plan"), subtitle: weeklyTemplateSubtitle) { showWeeklyTemplateSheet = true }
                autoregRow

                sectionHeader(store.t("app_section"))
                navigationRow(title: "Strava", subtitle: store.stravaAuth?.isConnected == true ? store.t("connected") : store.t("not_connected")) { showStravaSheet = true }
                appearanceCard
                languageCard
                navigationRow(title: store.t("account"), subtitle: store.authUser?.username ?? "—") { showAccountSheet = true }

                Button(store.t("test_profile")) { store.loadTestProfile() }
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundColor(DT.fgMuted)
                    .padding(.top, 4)
            }
            .padding(16)
        }
        .background(DT.bg)
        .sheet(isPresented: $showBasicsSheet) { BasicsSheetView() }
        .sheet(isPresented: $showOneRMSheet) { OneRMSheetView() }
        .sheet(isPresented: $showEquipmentSheet) { EquipmentSheetView() }
        .sheet(isPresented: $showExcludedPatternsSheet) { ExcludedPatternsSheetView() }
        .sheet(isPresented: $showSkillOverridesSheet) { SkillOverridesSheetView() }
        .sheet(isPresented: $showTrainingPreferencesSheet) { TrainingPreferencesSheetView() }
        .sheet(isPresented: $showWeeklyTemplateSheet) { WeeklyTemplateSheetView() }
        .sheet(isPresented: $showStravaSheet) { StravaSheetView() }
        .sheet(isPresented: $showAccountSheet) { AccountSheetView() }
    }

    // MARK: - Podtitulky řádků (krátký náhled aktuální hodnoty)

    private var basicsSubtitle: String {
        "\(store.profile.level.label) · \(formatValue(store.profile.bodyweight)) kg"
    }

    private var oneRMSubtitle: String {
        let set = OneRepMaxes.liftLabels.filter { store.profile.oneRM[$0.key] != nil }.count
        return "\(set)/\(OneRepMaxes.liftLabels.count)"
    }

    private var equipmentSubtitle: String {
        "\(store.profile.equipment.count) \(store.t("selected_count"))"
    }

    private var excludedPatternsSubtitle: String {
        store.profile.excludedPatterns.isEmpty ? store.t("none_excluded") : "\(store.profile.excludedPatterns.count) \(store.t("excluded_count"))"
    }

    private var skillOverridesSubtitle: String {
        let count = store.profile.skillOverrides?.count ?? 0
        return count == 0 ? store.t("default_setting") : "\(count) \(store.t("customized_count"))"
    }

    private var weeklyTemplateSubtitle: String {
        let activeDays = store.profile.weeklyTemplate.filter { $0 != .rest }.count
        return "\(activeDays)/7"
    }

    private func formatValue(_ v: Double) -> String {
        v == v.rounded() ? String(Int(v)) : String(format: "%.1f", v)
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .heavy))
            .trackedUppercase(0.3)
            .foregroundColor(DT.fgMuted)
            .padding(.top, 6)
    }

    /// Jeden tappable řádek s podtitulkem a šipkou — otevírá detail jako sheet.
    private func navigationRow(title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(.system(size: 14, weight: .bold)).foregroundColor(DT.fg)
                    Text(subtitle).font(.system(size: 12)).foregroundColor(DT.fgMuted).lineLimit(1)
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

    // MARK: - Posun na další úroveň (jen návrh, nikdy automaticky)

    /// Kolik odcvičených (uložených) tréninků typicky stačí, než má smysl
    /// zvážit posun na další úroveň — hrubý odhad, ne tvrdé kritérium.
    private static let levelUpThresholds: [AthleteLevel: Int] = [.beginner: 12, .intermediate: 24, .advanced: 36]

    private var levelUpSuggestion: AthleteLevel? {
        guard !levelUpDismissed, let next = store.profile.level.next else { return nil }
        guard let threshold = Self.levelUpThresholds[store.profile.level] else { return nil }
        return store.history.count >= threshold ? next : nil
    }

    private func levelUpCard(_ next: AthleteLevel) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.up.circle.fill").foregroundColor(DT.accentText)
                Text(store.t("level_up_question")).font(.system(size: 14, weight: .bold)).foregroundColor(DT.fg)
            }
            Text(store.language == .en
                ? "You've trained \(store.history.count) workouts at \(store.profile.level.label) level. Consider moving to \(next.label) — exercises and weights will adjust, but nothing changes without your confirmation."
                : "Trénuješ už \(store.history.count) tréninků na úrovni \(store.profile.level.label). Zvaž posun na \(next.label) — cviky i váhy se tomu přizpůsobí, ale nic se nezmění bez tvého potvrzení.")
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
                var profile = store.profile
                profile.level = next
                store.saveProfile(profile)
            }
        } message: {
            Text(store.language == .en
                ? "Future workouts will use \(next.label) level — harder exercises and higher working weights."
                : "Příští tréninky budou počítat s úrovní \(next.label) — náročnější cviky i vyšší pracovní váhy.")
        }
    }

    // MARK: - Autoregulace (lehký toggle, ukládá se hned)

    private var autoregRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(isOn: Binding(
                get: { store.profile.autoregEnabled },
                set: { newValue in
                    var profile = store.profile
                    profile.autoregEnabled = newValue
                    store.saveProfile(profile)
                }
            )) {
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
}
