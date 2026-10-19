import Foundation
import SwiftUI
import Combine

/// Centrální stav appky — obdoba `state` objektu + funkcí v js/app.js.
@MainActor
final class AppStore: ObservableObject {
    @Published var profile: AthleteProfile
    @Published var history: [Workout]
    @Published var viewDate: String {
        didSet { if oldValue != viewDate { loadOrGenerateWorkout() } }
    }
    @Published var currentWorkout: Workout?
    @Published var currentWorkoutSaved: Bool = false
    @Published var editMode: Bool = false
    @Published var stravaAuth: StravaAuth?
    @Published var theme: Storage.ThemeOption
    @Published var language: AppLanguage
    @Published var toastMessage: String?
    @Published var stravaExportInFlight: Bool = false
    @Published var prLog: [PrEntry]

    /// AI koučovací poznámky pro aktuálně zobrazený (dnešní) trénink, jedna na blok,
    /// stejný počet a pořadí jako `currentWorkout?.blocks`. Celé pole nil = nenačtené/
    /// ještě se načítá, žádný blok ještě nemá AI text. Jednotlivý prvek nil = tenhle
    /// konkrétní blok se (znovu) načítá — ostatní blok si mezitím drží svůj platný AI
    /// text beze změny/blikání (viz `refreshAICoachNote(forBlockIndex:)`).
    @Published var aiBlockNotes: [String?]?

    /// True, jen když se AI poznámky reálně nepodařilo získat (offline/chyba serveru/AI
    /// vrátila nečekaný výstup) — teprve pak UI ukáže statické `block.notes` z generátoru
    /// jako fallback. Dokud požadavek běží, zůstává false a karta raději nic nezobrazí,
    /// než aby na chvíli bliknula lokální text a hned ho přepsala AI poznámkou.
    @Published var aiNotesUnavailable: Bool = false

    // MARK: Přihlášení
    @Published var authUser: AuthUser?
    @Published var authServerUrl: String
    @Published var authInFlight: Bool = false
    @Published var authError: String?
    @Published var isRestoringSession: Bool = true

    private let storage = Storage.shared
    private var toastTask: Task<Void, Never>?
    private static let authTokenKey = "authToken"

    init() {
        profile = storage.getProfile()
        history = storage.getHistory()
        viewDate = DateUtils.todayString()
        theme = storage.getTheme()
        language = storage.getLanguage()
        stravaAuth = storage.getStravaAuth()
        prLog = storage.getPrLog()
        let savedServerUrl = storage.getAuthServerUrl()
        if !savedServerUrl.isEmpty {
            authServerUrl = savedServerUrl
        } else if let stravaUrl = storage.getStravaAuth()?.workerUrl, !stravaUrl.isEmpty {
            authServerUrl = stravaUrl
        } else {
            authServerUrl = AuthService.defaultServerURL
        }
        loadOrGenerateWorkout()
    }

    // MARK: Přihlášení

    /// Zavolat jednou při startu appky — ověří uložený session token na serveru,
    /// než appku zpřístupní (mandatorní login gate), a stáhne poslední stav
    /// uložený na serveru (pro případ, že se od posledního spuštění appky
    /// změnilo něco na jiném zařízení).
    func restoreSession() async {
        defer { isRestoringSession = false }
        guard let token = KeychainStore.get(forKey: Self.authTokenKey), !authServerUrl.isEmpty else { return }
        do {
            authUser = try await AuthService.shared.me(serverUrl: authServerUrl, token: token)
            await syncDown()
            if language == .en {
                Task { await warmExerciseTranslationsIfNeeded() }
            }
        } catch {
            KeychainStore.delete(forKey: Self.authTokenKey)
        }
    }

    /// Po přihlášení existujícího účtu stáhneme poslední stav ze serveru —
    /// typicky jde o jiné/nové zařízení, server má aktuálnější data.
    func login(serverUrl: String, username: String, password: String) async {
        authError = nil
        authInFlight = true
        defer { authInFlight = false }
        do {
            let (token, user) = try await AuthService.shared.login(serverUrl: serverUrl, username: username, password: password)
            persistSession(serverUrl: serverUrl, token: token, user: user)
            await syncDown()
            if language == .en {
                Task { await warmExerciseTranslationsIfNeeded() }
            }
        } catch {
            authError = error.localizedDescription
        }
    }

    /// Po založení nového účtu nahrajeme to, co už appka lokálně má (profil
    /// atd.), aby se nic neztratilo — na serveru zatím nic jiného není.
    func register(serverUrl: String, username: String, password: String) async {
        authError = nil
        authInFlight = true
        defer { authInFlight = false }
        do {
            let (token, user) = try await AuthService.shared.register(serverUrl: serverUrl, username: username, password: password)
            persistSession(serverUrl: serverUrl, token: token, user: user)
            syncUp()
            if language == .en {
                Task { await warmExerciseTranslationsIfNeeded() }
            }
        } catch {
            authError = error.localizedDescription
        }
    }

    func logout() {
        let serverUrl = authServerUrl
        if let token = KeychainStore.get(forKey: Self.authTokenKey) {
            Task { await AuthService.shared.logout(serverUrl: serverUrl, token: token) }
        }
        KeychainStore.delete(forKey: Self.authTokenKey)
        authUser = nil
    }

    private func persistSession(serverUrl: String, token: String, user: AuthUser) {
        authServerUrl = serverUrl
        storage.setAuthServerUrl(serverUrl)
        KeychainStore.set(token, forKey: Self.authTokenKey)
        authUser = user
        // Stejný Worker obsluhuje přihlašování i Strava export — pokud appka ještě
        // nemá vyplněné Worker URL pro Stravu, nabídneme stejnou adresu zadarmo.
        if stravaAuth == nil {
            storage.saveStravaAuth(StravaAuth(workerUrl: serverUrl, refreshToken: nil, athleteId: nil, athleteName: nil))
            stravaAuth = storage.getStravaAuth()
        }
    }

    // MARK: Synchronizace mezi zařízeními

    /// Pošle aktuální stav appky na server (fire-and-forget, appka na výsledek nečeká).
    /// Volá se po každé lokální změně, co se jinak ukládá do Storage.
    private func syncUp() {
        guard authUser != nil, let token = KeychainStore.get(forKey: Self.authTokenKey), !authServerUrl.isEmpty else { return }
        let state = SyncedState(profile: profile, history: history, prLog: prLog, theme: theme, strava: stravaAuth, language: language)
        let serverUrl = authServerUrl
        Task { await SyncService.shared.push(serverUrl: serverUrl, token: token, state: state) }
    }

    /// Stáhne stav ze serveru a přepíše jím lokální data i Storage. Tiše selže,
    /// pokud server nic nemá nebo je nedostupný — appka pak jede dál s tím, co má lokálně.
    private func syncDown() async {
        guard let token = KeychainStore.get(forKey: Self.authTokenKey), !authServerUrl.isEmpty else { return }
        guard let state = try? await SyncService.shared.pull(serverUrl: authServerUrl, token: token) else { return }
        if let p = state.profile { profile = p; storage.saveProfile(p) }
        if let h = state.history { history = h; storage.replaceHistory(h) }
        if let log = state.prLog { prLog = log; storage.replacePrLog(log) }
        if let t = state.theme { theme = t; storage.setTheme(t) }
        if let s = state.strava { stravaAuth = s; storage.saveStravaAuth(s) }
        if let lang = state.language { language = lang; storage.setLanguage(lang) }
        loadOrGenerateWorkout()
    }

    // MARK: Trénink pro aktuálně zobrazený den

    /// Náhledy (zatím neuložených) tréninků podle data, jen v paměti pro aktuální
    /// běh appky — bez tohohle by se při každém návratu na den bez uloženého
    /// tréninku losoval úplně nový trénink, takže by se při procházení historie
    /// "Pondělí" nikdy neshodovalo samo se sebou. Vymaže se, kdykoli se mění
    /// profil/jazyk/délka (viz `regenerateForCurrentProfile`), protože staré
    /// náhledy by pak už neodpovídaly.
    private var draftWorkoutsByDate: [String: Workout] = [:]

    func loadOrGenerateWorkout() {
        if let saved = storage.getWorkout(for: viewDate) {
            currentWorkout = saved
            currentWorkoutSaved = true
        } else if let draft = draftWorkoutsByDate[viewDate] {
            currentWorkout = draft
            currentWorkoutSaved = false
        } else {
            let generated = WorkoutGenerator.generateWorkout(profile: profile, dateString: viewDate, history: history, language: language)
            draftWorkoutsByDate[viewDate] = generated
            currentWorkout = generated
            currentWorkoutSaved = false
        }
        editMode = false
        refreshAICoachNotes()
    }

    func regenerate() {
        let generated = WorkoutGenerator.generateWorkout(profile: profile, dateString: viewDate, history: history, language: language)
        draftWorkoutsByDate[viewDate] = generated
        currentWorkout = generated
        currentWorkoutSaved = false
        toast(t("workout_regenerated"))
        refreshAICoachNotes()
    }

    /// Po uložení profilu / změně délky tréninku vždy přegeneruje, aby se nové údaje
    /// hned projevily (i když už pro daný den existuje uložený trénink z historie).
    /// Zahodí i náhledy ostatních dní — s novým profilem už neplatí. Nové parametry
    /// (vybavení, cíl, délka...) legitimně mění, JAKÉ cviky se vyberou, takže tu na
    /// rozdíl od `regenerateForLanguageChange` jde o úplně nový (náhodný) výběr.
    func regenerateForCurrentProfile() {
        draftWorkoutsByDate.removeAll()
        let generated = WorkoutGenerator.generateWorkout(profile: profile, dateString: viewDate, history: history, language: language)
        draftWorkoutsByDate[viewDate] = generated
        currentWorkout = generated
        currentWorkoutSaved = false
        editMode = false
        refreshAICoachNotes()
    }

    /// Jazyk nemění, JAKÉ cviky se vyberou — jen jak se to, co bylo vybráno dřív,
    /// napíše. Proto se tu (na rozdíl od `regenerateForCurrentProfile`) generátor
    /// spustí znovu se STEJNÝM `variantSeed`, jaký měl už vygenerovaný trénink —
    /// vyjde tak bit přesně stejný výběr cviků, jen přeložený text, místo aby se
    /// trénink při každém přepnutí jazyka znovu (a jinak) vylosoval.
    private func relabeled(_ workout: Workout) -> Workout {
        // Ručně upravený trénink (swap cviku, přepsané opakování/váha — viz `edited`)
        // se nepřegeneruje vůbec, jinak by přepnutí jazyka tiše smazalo tu úpravu.
        guard !workout.edited else { return workout }
        return WorkoutGenerator.generateWorkout(
            profile: profile, dateString: workout.date, history: history, language: language, seed: workout.variantSeed
        )
    }

    func regenerateForLanguageChange() {
        draftWorkoutsByDate = draftWorkoutsByDate.mapValues(relabeled)
        if let current = currentWorkout, !currentWorkoutSaved {
            let updated = relabeled(current)
            draftWorkoutsByDate[viewDate] = updated
            currentWorkout = updated
        }
        editMode = false
        refreshAICoachNotes()
    }

    // MARK: AI koučovací poznámky

    /// Zahodí VŠECHNY předchozí AI poznámky (celý trénink je jiný — nový den/profil/
    /// délka/regenerace) a zkusí načíst nové pro trénink, který je zrovna zobrazený
    /// na obrazovce Dnes (ať jde o dnešek, nebo libovolný jiný den z týdenního
    /// pruhu) — tiše selže a nechá statické poznámky z generátoru, pokud není
    /// síť/AI dostupná.
    private func refreshAICoachNotes() {
        aiBlockNotes = nil
        aiNotesUnavailable = false
        Task { @MainActor in await loadAICoachNotes() }
    }

    /// Po výměně jednoho cviku (`swapExercise`): backend vždy vrací poznámky pro
    /// celý trénink najednou, ale model je generuje nedeterministicky, takže by se
    /// jinak "náhodou" přepsal i text bloku, který se vůbec nezměnil (např. swap
    /// v EMOM a text v navazujícím AMRAP se bez důvodu změní). Místo toho zneplatní
    /// (na statický fallback, bez blikání) jen poznámku konkrétního bloku a po
    /// odpovědi z AI do existujícího pole přepíše výhradně tenhle jeden index —
    /// poznámky ostatních bloků zůstanou beze změny.
    private func refreshAICoachNote(forBlockIndex index: Int) {
        if var notes = aiBlockNotes, index < notes.count {
            notes[index] = nil
            aiBlockNotes = notes
        }
        aiNotesUnavailable = false
        Task { @MainActor in await loadAICoachNotes(onlyApplyingBlockIndex: index) }
    }

    /// Krátký, jednorázový retry na přechodné selhání (např. přepnutí jazyka zároveň
    /// odpálí dávkový překlad celé databáze cviků — `warmExerciseTranslationsIfNeeded`
    /// — a obě volání si na free tier Workers AI chvíli "stojí v cestě", takže první
    /// pokus o dnešní AI poznámky občas vyprší). Teprve když selžou OBA pokusy, je to
    /// skutečná nedostupnost a UI smí spadnout na statické poznámky z generátoru.
    private func loadAICoachNotes(onlyApplyingBlockIndex: Int? = nil) async {
        guard let token = KeychainStore.get(forKey: Self.authTokenKey), !authServerUrl.isEmpty,
              let workout = currentWorkout, workout.date == viewDate else {
            aiNotesUnavailable = true
            return
        }
        let recentRpe = Array(history.compactMap { $0.rpe }.prefix(5))

        for attempt in 0..<2 {
            if attempt > 0 {
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                // Mezitím se mohlo přepnout na jiný den — druhý pokus by jinak
                // odpovídal na otázku, kterou už nikdo nepoložil.
                guard currentWorkout?.date == workout.date, viewDate == workout.date else { return }
            }
            do {
                let notes = try await AICoachService.shared.fetchBlockNotes(
                    serverUrl: authServerUrl, token: token, workout: workout, profile: profile, recentRpe: recentRpe, language: language
                )
                // Mezitím se mohlo přepnout na jiný den/trénink — odpověď už nic neříká
                // o aktuálně zobrazeném tréninku, tiše ji zahodíme (není to "nedostupnost").
                guard currentWorkout?.date == workout.date else { return }
                guard notes.count == workout.blocks.count else {
                    aiNotesUnavailable = true
                    return
                }
                if let index = onlyApplyingBlockIndex, var existing = aiBlockNotes, index < existing.count, index < notes.count {
                    existing[index] = notes[index]
                    aiBlockNotes = existing
                } else {
                    aiBlockNotes = notes.map { $0 as String? }
                }
                return
            } catch {
                // První pokus tiše zopakujeme (viz nahoře); až po druhém selhání
                // je to skutečná nedostupnost.
            }
        }
        aiNotesUnavailable = true
    }

    func saveCurrentWorkout() {
        guard let w = currentWorkout else { return }
        history = storage.saveWorkoutToHistory(w)
        currentWorkoutSaved = true
        toast(t("workout_saved_to_history"))
        syncUp()
    }

    func deleteCurrentWorkout() {
        history = storage.deleteWorkout(for: viewDate)
        loadOrGenerateWorkout()
        toast(t("workout_deleted"))
        syncUp()
    }

    /// Smaže libovolný trénink z historie podle data — používá se třeba u
    /// potažení řádku v Historii doleva (bez ohledu na aktuálně zobrazený den).
    func deleteWorkout(for date: String) {
        history = storage.deleteWorkout(for: date)
        if date == viewDate {
            loadOrGenerateWorkout()
        }
        toast(t("workout_deleted"))
        syncUp()
    }

    /// Odškrtnutí "splnil jsem tenhle trénink" na kartě Dnes — nezávislé na tom,
    /// jestli je trénink jen uložený/naplánovaný (viz `saveCurrentWorkout`).
    func toggleWorkoutCompleted() {
        guard var w = currentWorkout else { return }
        w.completed = !(w.completed ?? false)
        history = storage.saveWorkoutToHistory(w)
        currentWorkout = w
        currentWorkoutSaved = true
        toast(w.isCompleted ? t("workout_marked_completed") : t("completion_cleared"))
        syncUp()
    }

    func saveRpe(_ value: Int) {
        guard var w = currentWorkout else { return }
        w.rpe = value
        history = storage.saveWorkoutToHistory(w)
        currentWorkout = w
        currentWorkoutSaved = true
        toast(t("rpe_saved"))
        syncUp()
    }

    func updateDuration(_ minutes: Int) {
        guard profile.timeAvailable != minutes else { return }
        profile.timeAvailable = minutes
        storage.saveProfile(profile)
        regenerateForCurrentProfile()
        syncUp()
    }

    /// Uloží upravený trénink do `currentWorkout` a (dokud není uložený do historie)
    /// i do `draftWorkoutsByDate`, ať se ruční úprava neztratí při odskoku na jiný
    /// den a návratu zpět — bez tohohle by `loadOrGenerateWorkout` načetl zpátky
    /// starý (neupravený) náhled z cache.
    private func updateCurrentWorkout(_ workout: Workout) {
        currentWorkout = workout
        if !currentWorkoutSaved { draftWorkoutsByDate[viewDate] = workout }
    }

    func updateReps(blockIndex: Int, exerciseIndex: Int, reps: String) {
        guard var w = currentWorkout, blockIndex < w.blocks.count, exerciseIndex < w.blocks[blockIndex].exercises.count else { return }
        w.blocks[blockIndex].exercises[exerciseIndex].reps = reps
        w.edited = true
        updateCurrentWorkout(w)
    }

    func updateWeight(blockIndex: Int, exerciseIndex: Int, weight: Double) {
        guard var w = currentWorkout, blockIndex < w.blocks.count, exerciseIndex < w.blocks[blockIndex].exercises.count else { return }
        w.blocks[blockIndex].exercises[exerciseIndex].weight = weight
        w.edited = true
        updateCurrentWorkout(w)
    }

    func swapExercise(blockIndex: Int, exerciseIndex: Int, newExercise: Exercise) {
        guard var w = currentWorkout, blockIndex < w.blocks.count, exerciseIndex < w.blocks[blockIndex].exercises.count else { return }
        let current = w.blocks[blockIndex].exercises[exerciseIndex]
        // Blok A má format == .strength na SILOVÉM i na GYMNASTICKÉM dni (skill
        // nácvik tam taky běží jako "Blok A", viz buildGymnasticsDay) — bez
        // rozlišení kategorie by swap v gymnastickém skill bloku počítal váhu
        // jako silový cvik (76–90 % 1RM) místo technického nácviku (~30 %).
        let purpose: LoadPurpose = w.blocks[blockIndex].format == .strength
            ? (current.category == .weightlifting ? .strength : .technique)
            : .metcon
        let autoreg = WorkoutGenerator.computeAutoreg(history, profile)
        // Při záměně hlavního silového cviku musí %1RM odpovídat skutečnému
        // rep scheme bloku (viz WorkoutGenerator.strengthPercent), a to rep
        // scheme se navíc teď cyklí (strengthSessionVariantIndex), ne jen
        // funkce úrovně — jinak by swap spadl na jiné % než blok skutečně má.
        let repsPerSet: Int? = purpose == .strength
            ? WorkoutGenerator.strengthSetsScheme(profile.level, WorkoutGenerator.strengthSessionVariantIndex(history)).reps
            : nil
        let load = WorkoutGenerator.computeLoad(newExercise, profile, purpose: purpose, autoreg: autoreg, repsPerSet: repsPerSet)
        let tier = profile.level.tier
        w.blocks[blockIndex].exercises[exerciseIndex] = WorkoutExercise(
            exerciseId: newExercise.id, name: newExercise.name, category: newExercise.category, pattern: newExercise.pattern,
            equipment: newExercise.equipment, levelTier: tier, levelInfo: newExercise.levels.info(for: tier),
            reps: current.reps, weight: load?.weight, unit: load?.unit, loadSource: load?.source, loadPct: load?.pct,
            autoregAdj: load?.autoregAdj, cues: newExercise.cues, mistakes: newExercise.mistakes, note: current.note
        )
        // Ruční zásah uživatele — `regenerateForLanguageChange` tenhle trénink
        // kvůli přepnutí jazyka znovu nevygeneruje (tím by o swap zase přišel),
        // viz `edited`.
        w.edited = true
        updateCurrentWorkout(w)
        toast(t("exercise_swapped"))
        refreshAICoachNote(forBlockIndex: blockIndex)
    }

    func swapCandidates(blockIndex: Int, exerciseIndex: Int) -> [Exercise] {
        guard let w = currentWorkout, blockIndex < w.blocks.count, exerciseIndex < w.blocks[blockIndex].exercises.count else { return [] }
        let block = w.blocks[blockIndex]
        let current = block.exercises[exerciseIndex]
        let usedIds = Set(block.exercises.map(\.exerciseId))
        // Jen výběr kandidátů pro UI, ne skutečná generace tréninku — náhodnost tu
        // nijak nevadí, stačí nový seed pro každé zavolání.
        var rng = SeededGenerator(seed: UInt64.random(in: UInt64.min...UInt64.max))
        // EMOM/AMRAP/ForTime/Chipper blok nenabídne jako náhradu cvik, který patří
        // jen do samostatného Engine dne (swim) — mimo Engine blok (steady/
        // intervaly/tabata) by to bylo stejně nereálné jako ve WorkoutGeneratoru.
        let isEngineBlock: Bool = [.steady, .intervals, .tabata].contains(block.format)
        // Hlavní silový cvik (Blok A na silovém dni) se při generování vybírá ze
        // ŠIRŠÍHO poolu — libovolný squat/hinge/push/olympic cvik z celé
        // .weightlifting kategorie (viz buildStrengthDay), ne jen přesná shoda
        // pattern aktuálního cviku. Bez tohohle rozlišení swap v den s
        // olympic-pattern hlavním cvikem (clean/snatch…) nikdy nenabídl
        // deadlift/front squat/back squat (hinge/squat pattern) jako alternativu,
        // přestože by při normální generaci byly stejně "na stole".
        if block.format == .strength, current.category == .weightlifting {
            let broad = WorkoutGenerator.filterPool(profile, categories: [.weightlifting], using: &rng)
                .filter { [.squat, .hinge, .push, .olympic].contains($0.pattern) && !usedIds.contains($0.id) }
            if !broad.isEmpty { return broad }
        }
        let byPattern = WorkoutGenerator.filterPool(profile, categories: nil, excludeStandaloneCardio: !isEngineBlock, using: &rng)
            .filter { $0.pattern == current.pattern && !usedIds.contains($0.id) }
        if !byPattern.isEmpty { return byPattern }
        return WorkoutGenerator.filterPool(profile, categories: [current.category], excludeStandaloneCardio: !isEngineBlock, using: &rng).filter { !usedIds.contains($0.id) }
    }

    // MARK: Profil

    func saveProfile(_ newProfile: AthleteProfile) {
        profile = newProfile
        storage.saveProfile(newProfile)
        regenerateForCurrentProfile()
        toast(t("profile_saved"))
        syncUp()
    }

    func loadTestProfile() {
        profile = .testProfile
        storage.saveProfile(profile)
        regenerateForCurrentProfile()
        toast(t("test_profile_loaded"))
        syncUp()
    }

    // MARK: PR log

    func addPrEntry(lift: String, value: Double, date: String) {
        prLog = storage.addPrEntry(PrEntry(lift: lift, value: value, date: date))
        profile.oneRM[lift] = value
        storage.saveProfile(profile)
        toast(t("pr_saved"))
        syncUp()
    }

    // MARK: Strava

    func connectStrava(workerUrl: String) {
        storage.saveStravaAuth(StravaAuth(workerUrl: workerUrl, refreshToken: nil, athleteId: nil, athleteName: nil))
        StravaService.shared.connect(workerUrl: workerUrl) { [weak self] result in
            Task { @MainActor in
                guard let self else { return }
                switch result {
                case .success(let auth):
                    self.storage.saveStravaAuth(auth)
                    self.stravaAuth = auth
                    self.toast(self.t("strava_connected"))
                    self.syncUp()
                case .failure(let error):
                    self.toast("\(self.t("strava_connect_failed")): \(error.localizedDescription)")
                }
            }
        }
    }

    func disconnectStrava() {
        storage.clearStravaAuth()
        stravaAuth = storage.getStravaAuth()
        toast(t("strava_disconnected"))
        syncUp()
    }

    @discardableResult
    func exportCurrentWorkoutToStrava() async -> Bool {
        guard let w = currentWorkout else {
            toast(t("generate_workout_first"))
            return false
        }
        return await exportWorkoutToStrava(w)
    }

    /// Exportuje libovolný (i historický) trénink na Strava — používá se jak pro dnešní
    /// trénink, tak pro export jednotlivých položek z Historie.
    @discardableResult
    func exportWorkoutToStrava(_ workout: Workout) async -> Bool {
        guard let auth = stravaAuth, auth.isConnected, let refreshToken = auth.refreshToken else {
            toast(t("connect_strava_first"))
            return false
        }
        stravaExportInFlight = true
        defer { stravaExportInFlight = false }
        do {
            let refreshed = try await StravaService.shared.refreshAccessToken(workerUrl: auth.workerUrl, refreshToken: refreshToken)
            var updatedAuth = auth
            updatedAuth.refreshToken = refreshed.refreshToken
            storage.saveStravaAuth(updatedAuth)
            stravaAuth = updatedAuth

            let activityId = try await StravaService.shared.exportWorkout(workerUrl: auth.workerUrl, accessToken: refreshed.accessToken, workout: workout)
            var updated = workout
            updated.stravaActivityId = activityId
            history = storage.saveWorkoutToHistory(updated)
            if currentWorkout?.date == updated.date {
                currentWorkout = updated
                currentWorkoutSaved = true
            }
            toast(t("sent_to_strava"))
            syncUp()
            return true
        } catch {
            toast("\(t("strava_export_failed")): \(error.localizedDescription)")
            return false
        }
    }

    // MARK: Motiv

    func cycleTheme() {
        let next: Storage.ThemeOption = theme == .auto ? .dark : (theme == .dark ? .light : .auto)
        theme = next
        storage.setTheme(next)
        let label = next == .auto ? t("theme_auto") : (next == .dark ? t("theme_dark") : t("theme_light"))
        toast("\(t("theme")): \(label)")
        syncUp()
    }

    var colorScheme: ColorScheme? {
        switch theme {
        case .auto: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    // MARK: AI překlad (cviky — cues/mistakes/svaly)

    /// Vrátí anglický překlad pro každý vstupní (český) text, s lokální cache —
    /// stejný text se tak přes AI posílá jen jednou za appku, ne při každém zobrazení.
    /// Tiše selže na originál (česky), pokud AI/síť nejsou dostupné.
    func translateTexts(_ texts: [String]) async -> [String] {
        guard let token = KeychainStore.get(forKey: Self.authTokenKey), !authServerUrl.isEmpty, !texts.isEmpty else { return texts }
        var cache = storage.getTranslationCache()
        let missing = Array(Set(texts.filter { !$0.isEmpty && cache[$0] == nil }))
        if !missing.isEmpty, let fetched = try? await AICoachService.shared.translate(serverUrl: authServerUrl, token: token, texts: missing), fetched.count == missing.count {
            for (original, translated) in zip(missing, fetched) { cache[original] = translated }
            storage.setTranslationCache(cache)
        }
        return texts.map { cache[$0] ?? $0 }
    }

    /// Synchronní (bez síťového volání) nahlédnutí do trvalé cache — použij na
    /// začátku zobrazení, ať se už jednou přeložený text neprobliskne nejdřív
    /// česky, než doběhne network round-trip.
    func cachedTranslation(_ cs: String) -> String? {
        storage.getTranslationCache()[cs]
    }

    private var isWarmingTranslations = false

    /// Přeloží celou databázi cviků (svaly, cues, mistakes, popisy úrovní) na pozadí,
    /// po dávkách, a výsledek uloží do trvalé cache — ať pak otevření libovolného
    /// cviku v angličtině je okamžité, místo aby appka překládala "za pochodu"
    /// při prvním zobrazení každého cviku zvlášť. Bezpečné spustit opakovaně
    /// (přeskočí už přeložené texty) a neběží dvakrát souběžně.
    func warmExerciseTranslationsIfNeeded() async {
        guard !isWarmingTranslations else { return }
        guard let token = KeychainStore.get(forKey: Self.authTokenKey), !authServerUrl.isEmpty else { return }
        isWarmingTranslations = true
        defer { isWarmingTranslations = false }

        // Krátké zpoždění: tahle dávka běží jen na pozadí a nikam nespěchá, zatímco
        // dnešní AI koučovací poznámky jsou vidět hned na obrazovce — ať jim (zvlášť
        // po přepnutí jazyka, kdy se obě volání spustí ve stejnou chvíli) na malém
        // free tier Workers AI neberou šanci na první pokus.
        try? await Task.sleep(nanoseconds: 2_000_000_000)

        var allTexts: Set<String> = []
        for ex in ExerciseDatabase.all {
            allTexts.formUnion(ex.muscles)
            allTexts.formUnion(ex.cues)
            allTexts.formUnion(ex.mistakes)
            for info in [ex.levels.beginner, ex.levels.intermediate, ex.levels.rx] {
                allTexts.insert(info.desc)
                allTexts.insert(info.criteria)
            }
        }

        var cache = storage.getTranslationCache()
        let missing = allTexts.filter { !$0.isEmpty && cache[$0] == nil }
        guard !missing.isEmpty else { return }

        for batch in Array(missing).chunked(into: 50) {
            guard let fetched = try? await AICoachService.shared.translate(serverUrl: authServerUrl, token: token, texts: batch), fetched.count == batch.count else { continue }
            for (original, translated) in zip(batch, fetched) { cache[original] = translated }
            storage.setTranslationCache(cache)
        }
    }

    // MARK: Jazyk

    func cycleLanguage() {
        language = language == .cs ? .en : .cs
        storage.setLanguage(language)
        regenerateForLanguageChange()
        syncUp()
        if language == .en {
            Task { await warmExerciseTranslationsIfNeeded() }
        }
    }

    /// Zkratka pro statické UI texty — `L.t(key, language)`.
    func t(_ key: String) -> String { L.t(key, language) }

    // MARK: Toast

    func toast(_ message: String) {
        toastTask?.cancel()
        toastMessage = message
        toastTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_200_000_000)
            if !Task.isCancelled { toastMessage = nil }
        }
    }
}

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [self] }
        return stride(from: 0, to: count, by: size).map { Array(self[$0..<Swift.min($0 + size, count)]) }
    }
}
