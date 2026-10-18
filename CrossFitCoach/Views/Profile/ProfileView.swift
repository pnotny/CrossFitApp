import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var store: AppStore
    @State private var draft = AthleteProfile()
    @State private var oneRMText: [String: String] = [:]
    @State private var stravaWorkerUrl = ""
    @State private var showLevelUpConfirm = false
    @State private var levelUpDismissed = false

    private static let dayLabels = ["Po", "Út", "St", "Čt", "Pá", "So", "Ne"]
    private static let preferredFormatOptions: [WorkoutFormat] = [.emom, .amrap, .forTime, .chipper, .tabata, .intervals, .steady]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    basicsCard
                    if let suggestion = levelUpSuggestion {
                        levelUpCard(suggestion)
                    }
                    oneRMCard
                    equipmentCard
                    excludedPatternsCard
                    goalCard
                    preferredFormatsCard
                    autoregCard
                    weeklyTemplateCard
                    stravaCard
                    appearanceCard

                    HStack(spacing: 10) {
                        Button {
                            store.loadTestProfile()
                            loadDraft()
                        } label: {
                            Text("Testovací profil").frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)

                        Button {
                            store.saveProfile(draft)
                        } label: {
                            Text("Uložit profil").frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .font(.system(size: 15, weight: .bold))
                }
                .padding(16)
            }
            .navigationTitle("Profil")
            .background(Color(.systemGroupedBackground))
            .onAppear { loadDraft() }
        }
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

    // MARK: - Základní údaje

    private var basicsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Základní údaje").font(.system(size: 13, weight: .bold)).foregroundColor(.secondary)

            TextField("Jméno", text: $draft.name)
                .textFieldStyle(.roundedBorder)

            SegmentedPicker(options: Gender.allCases.map { ($0, $0.label) }, selection: $draft.gender)

            HStack {
                Text("Váha").font(.system(size: 14))
                Spacer()
                TextField("kg", value: $draft.bodyweight, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 70)
                    .textFieldStyle(.roundedBorder)
                Text("kg").font(.system(size: 13)).foregroundColor(.secondary)
            }

            Text("Úroveň").font(.system(size: 12, weight: .semibold)).foregroundColor(.secondary)
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
                Image(systemName: "arrow.up.circle.fill").foregroundColor(.accentColor)
                Text("Čas na posun?").font(.system(size: 14, weight: .bold))
            }
            Text("Trénuješ už \(store.history.count) tréninků na úrovni \(draft.level.label). Zvaž posun na \(next.label) — cviky i váhy se tomu přizpůsobí, ale nic se nezmění bez tvého potvrzení.")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
            HStack(spacing: 10) {
                Button("Teď ne") { levelUpDismissed = true }
                    .buttonStyle(.bordered)
                Button("Přejít na \(next.label)") { showLevelUpConfirm = true }
                    .buttonStyle(.borderedProminent)
            }
            .font(.system(size: 13, weight: .semibold))
        }
        .cardStyle()
        .alert("Přejít na \(next.label)?", isPresented: $showLevelUpConfirm) {
            Button("Zrušit", role: .cancel) {}
            Button("Přejít") {
                draft.level = next
                store.saveProfile(draft)
            }
        } message: {
            Text("Příští tréninky budou počítat s úrovní \(next.label) — náročnější cviky i vyšší pracovní váhy.")
        }
    }

    // MARK: - 1RM

    private var oneRMCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("1RM (osobní maxima)").font(.system(size: 13, weight: .bold)).foregroundColor(.secondary)
            ForEach(OneRepMaxes.liftLabels, id: \.key) { lift in
                HStack {
                    Text(lift.label).font(.system(size: 14))
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
                    Text("kg").font(.system(size: 13)).foregroundColor(.secondary)
                }
            }
        }
        .cardStyle()
    }

    // MARK: - Vybavení

    private var equipmentCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Dostupné vybavení").font(.system(size: 13, weight: .bold)).foregroundColor(.secondary)
            ChipGrid {
                ForEach(Equipment.allCases.filter { $0 != .none }, id: \.self) { eq in
                    ChipButton(label: eq.label, isActive: draft.equipment.contains(eq)) {
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
            Text("Vyloučené pohybové vzory").font(.system(size: 13, weight: .bold)).foregroundColor(.secondary)
            Text("Např. kvůli zranění nebo zákazu olympijských zdvihů.")
                .font(.system(size: 12)).foregroundColor(.secondary)
            ChipGrid {
                ForEach(MovementPattern.allCases, id: \.self) { pattern in
                    ChipButton(label: pattern.label, isActive: draft.excludedPatterns.contains(pattern), danger: true) {
                        toggle(pattern, in: \.excludedPatterns)
                    }
                }
            }
        }
        .cardStyle()
    }

    // MARK: - Cíl

    private var goalCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Hlavní cíl").font(.system(size: 13, weight: .bold)).foregroundColor(.secondary)
            SegmentedPicker(options: Goal.allCases.map { ($0, $0.label) }, selection: $draft.goal)
        }
        .cardStyle()
    }

    // MARK: - Oblíbené formáty metconu

    private var preferredFormatsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Oblíbené formáty metconu").font(.system(size: 13, weight: .bold)).foregroundColor(.secondary)
            ChipGrid {
                ForEach(Self.preferredFormatOptions, id: \.self) { format in
                    ChipButton(label: format.label, isActive: draft.preferredFormats.contains(format)) {
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
                    Text("Autoregulace zátěže (RPE)").font(.system(size: 14, weight: .semibold))
                    Text("Upraví zátěž podle hodnocení náročnosti posledních tréninků.")
                        .font(.system(size: 12)).foregroundColor(.secondary)
                }
            }
        }
        .cardStyle()
    }

    // MARK: - Týdenní šablona

    private var weeklyTemplateCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Týdenní plán").font(.system(size: 13, weight: .bold)).foregroundColor(.secondary)
            ForEach(0..<7, id: \.self) { idx in
                HStack {
                    Text(Self.dayLabels[idx])
                        .font(.system(size: 14, weight: .semibold))
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
                            Text(day.label).tag(day)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
        }
        .cardStyle()
    }

    // MARK: - Strava

    private var stravaCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Strava").font(.system(size: 13, weight: .bold)).foregroundColor(.secondary)
            if store.stravaAuth?.isConnected == true {
                HStack {
                    BadgeView(text: "Připojeno", color: .green)
                    Spacer()
                    Button("Odpojit", role: .destructive) { store.disconnectStrava() }
                }
            } else {
                Text("Zadej URL svého Cloudflare Worker proxy pro OAuth.")
                    .font(.system(size: 12)).foregroundColor(.secondary)
                TextField("https://strava-worker.example.workers.dev", text: $stravaWorkerUrl)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .keyboardType(.URL)
                Button {
                    store.connectStrava(workerUrl: stravaWorkerUrl)
                } label: {
                    Text("Připojit Strava").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(stravaWorkerUrl.isEmpty)
            }
        }
        .cardStyle()
    }

    // MARK: - Vzhled

    private var appearanceCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("Motiv").font(.system(size: 14, weight: .semibold))
                Text(themeLabel).font(.system(size: 12)).foregroundColor(.secondary)
            }
            Spacer()
            Button("Změnit") { store.cycleTheme() }
        }
        .cardStyle()
    }

    private var themeLabel: String {
        switch store.theme {
        case .auto: return "Automaticky"
        case .light: return "Světlý"
        case .dark: return "Tmavý"
        }
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
