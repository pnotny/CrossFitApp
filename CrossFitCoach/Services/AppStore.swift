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
    @Published var toastMessage: String?
    @Published var stravaExportInFlight: Bool = false
    @Published var prLog: [PrEntry]

    /// AI koučovací poznámky pro aktuálně zobrazený (dnešní) trénink, jedna na blok,
    /// stejný počet a pořadí jako `currentWorkout?.blocks`. Nil = nenačtené/selhalo —
    /// UI v tom případě ukazuje statické `block.notes` z generátoru.
    @Published var aiBlockNotes: [String]?

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
        let state = SyncedState(profile: profile, history: history, prLog: prLog, theme: theme, strava: stravaAuth)
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
        loadOrGenerateWorkout()
    }

    // MARK: Trénink pro aktuálně zobrazený den

    func loadOrGenerateWorkout() {
        if let saved = storage.getWorkout(for: viewDate) {
            currentWorkout = saved
            currentWorkoutSaved = true
        } else {
            currentWorkout = WorkoutGenerator.generateWorkout(profile: profile, dateString: viewDate, history: history)
            currentWorkoutSaved = false
        }
        editMode = false
        refreshAICoachNotes()
    }

    func regenerate() {
        currentWorkout = WorkoutGenerator.generateWorkout(profile: profile, dateString: viewDate, history: history)
        currentWorkoutSaved = false
        toast("Trénink přegenerován")
        refreshAICoachNotes()
    }

    /// Po uložení profilu vždy přegeneruje, aby se nové údaje hned projevily
    /// (i když už pro daný den existuje uložený trénink z historie).
    func regenerateForCurrentProfile() {
        currentWorkout = WorkoutGenerator.generateWorkout(profile: profile, dateString: viewDate, history: history)
        currentWorkoutSaved = false
        editMode = false
        refreshAICoachNotes()
    }

    // MARK: AI koučovací poznámky

    /// Zahodí předchozí AI poznámky (už neodpovídají novému tréninku) a pro dnešní
    /// den (ne historii) se zkusí načíst nové — tiše selže a nechá statické poznámky
    /// z generátoru, pokud není síť/AI dostupná.
    private func refreshAICoachNotes() {
        aiBlockNotes = nil
        guard viewDate == DateUtils.todayString() else { return }
        Task { @MainActor in await loadAICoachNotes() }
    }

    private func loadAICoachNotes() async {
        guard let token = KeychainStore.get(forKey: Self.authTokenKey), !authServerUrl.isEmpty,
              let workout = currentWorkout, workout.date == viewDate else { return }
        let recentRpe = Array(history.compactMap { $0.rpe }.prefix(5))
        do {
            let notes = try await AICoachService.shared.fetchBlockNotes(
                serverUrl: authServerUrl, token: token, workout: workout, profile: profile, recentRpe: recentRpe
            )
            guard notes.count == workout.blocks.count, currentWorkout?.date == workout.date else { return }
            aiBlockNotes = notes
        } catch {
            // Tiché selhání — appka beze změny ukazuje statické poznámky z generátoru.
        }
    }

    func saveCurrentWorkout() {
        guard let w = currentWorkout else { return }
        history = storage.saveWorkoutToHistory(w)
        currentWorkoutSaved = true
        toast("Trénink uložen do historie")
        syncUp()
    }

    func deleteCurrentWorkout() {
        history = storage.deleteWorkout(for: viewDate)
        loadOrGenerateWorkout()
        toast("Trénink smazán")
        syncUp()
    }

    /// Smaže libovolný trénink z historie podle data — používá se třeba u
    /// potažení řádku v Historii doleva (bez ohledu na aktuálně zobrazený den).
    func deleteWorkout(for date: String) {
        history = storage.deleteWorkout(for: date)
        if date == viewDate {
            loadOrGenerateWorkout()
        }
        toast("Trénink smazán")
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
        toast(w.isCompleted ? "Trénink označen jako splněný 💪" : "Splnění zrušeno")
        syncUp()
    }

    func saveRpe(_ value: Int) {
        guard var w = currentWorkout else { return }
        w.rpe = value
        history = storage.saveWorkoutToHistory(w)
        currentWorkout = w
        currentWorkoutSaved = true
        toast("RPE uloženo — příští trénink se tomu přizpůsobí")
        syncUp()
    }

    func updateDuration(_ minutes: Int) {
        guard profile.timeAvailable != minutes else { return }
        profile.timeAvailable = minutes
        storage.saveProfile(profile)
        regenerateForCurrentProfile()
        syncUp()
    }

    func updateReps(blockIndex: Int, exerciseIndex: Int, reps: String) {
        guard var w = currentWorkout, blockIndex < w.blocks.count, exerciseIndex < w.blocks[blockIndex].exercises.count else { return }
        w.blocks[blockIndex].exercises[exerciseIndex].reps = reps
        currentWorkout = w
    }

    func updateWeight(blockIndex: Int, exerciseIndex: Int, weight: Double) {
        guard var w = currentWorkout, blockIndex < w.blocks.count, exerciseIndex < w.blocks[blockIndex].exercises.count else { return }
        w.blocks[blockIndex].exercises[exerciseIndex].weight = weight
        currentWorkout = w
    }

    func swapExercise(blockIndex: Int, exerciseIndex: Int, newExercise: Exercise) {
        guard var w = currentWorkout, blockIndex < w.blocks.count, exerciseIndex < w.blocks[blockIndex].exercises.count else { return }
        let current = w.blocks[blockIndex].exercises[exerciseIndex]
        let purpose: LoadPurpose = w.blocks[blockIndex].format == .strength ? .strength : .metcon
        let autoreg = WorkoutGenerator.computeAutoreg(history, profile)
        let load = WorkoutGenerator.computeLoad(newExercise, profile, purpose: purpose, autoreg: autoreg)
        let tier = profile.level.tier
        w.blocks[blockIndex].exercises[exerciseIndex] = WorkoutExercise(
            exerciseId: newExercise.id, name: newExercise.name, category: newExercise.category, pattern: newExercise.pattern,
            equipment: newExercise.equipment, levelTier: tier, levelInfo: newExercise.levels.info(for: tier),
            reps: current.reps, weight: load?.weight, unit: load?.unit, loadSource: load?.source, loadPct: load?.pct,
            autoregAdj: load?.autoregAdj, cues: newExercise.cues, mistakes: newExercise.mistakes, note: current.note
        )
        currentWorkout = w
        toast("Cvik vyměněn")
    }

    func swapCandidates(blockIndex: Int, exerciseIndex: Int) -> [Exercise] {
        guard let w = currentWorkout, blockIndex < w.blocks.count, exerciseIndex < w.blocks[blockIndex].exercises.count else { return [] }
        let block = w.blocks[blockIndex]
        let current = block.exercises[exerciseIndex]
        let usedIds = Set(block.exercises.map(\.exerciseId))
        let byPattern = WorkoutGenerator.filterPool(profile, categories: nil)
            .filter { $0.pattern == current.pattern && !usedIds.contains($0.id) }
        if !byPattern.isEmpty { return byPattern }
        return WorkoutGenerator.filterPool(profile, categories: [current.category]).filter { !usedIds.contains($0.id) }
    }

    // MARK: Profil

    func saveProfile(_ newProfile: AthleteProfile) {
        profile = newProfile
        storage.saveProfile(newProfile)
        regenerateForCurrentProfile()
        toast("Profil uložen")
        syncUp()
    }

    func loadTestProfile() {
        profile = .testProfile
        storage.saveProfile(profile)
        regenerateForCurrentProfile()
        toast("Testovací profil načten a uložen")
        syncUp()
    }

    // MARK: PR log

    func addPrEntry(lift: String, value: Double, date: String) {
        prLog = storage.addPrEntry(PrEntry(lift: lift, value: value, date: date))
        profile.oneRM[lift] = value
        storage.saveProfile(profile)
        toast("PR uložen")
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
                    self.toast("Strava připojena 🎉")
                    self.syncUp()
                case .failure(let error):
                    self.toast("Připojení Strava selhalo: \(error.localizedDescription)")
                }
            }
        }
    }

    func disconnectStrava() {
        storage.clearStravaAuth()
        stravaAuth = storage.getStravaAuth()
        toast("Strava odpojena")
        syncUp()
    }

    @discardableResult
    func exportCurrentWorkoutToStrava() async -> Bool {
        guard let w = currentWorkout else {
            toast("Nejdřív vygeneruj trénink")
            return false
        }
        return await exportWorkoutToStrava(w)
    }

    /// Exportuje libovolný (i historický) trénink na Strava — používá se jak pro dnešní
    /// trénink, tak pro export jednotlivých položek z Historie.
    @discardableResult
    func exportWorkoutToStrava(_ workout: Workout) async -> Bool {
        guard let auth = stravaAuth, auth.isConnected, let refreshToken = auth.refreshToken else {
            toast("Nejdřív připoj Strava v Profilu")
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
            toast("Odesláno na Strava 🎉")
            syncUp()
            return true
        } catch {
            toast("Export na Strava selhal: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: Motiv

    func cycleTheme() {
        let next: Storage.ThemeOption = theme == .auto ? .dark : (theme == .dark ? .light : .auto)
        theme = next
        storage.setTheme(next)
        let label = next == .auto ? "Automaticky" : (next == .dark ? "Tmavý" : "Světlý")
        toast("Motiv: \(label)")
        syncUp()
    }

    var colorScheme: ColorScheme? {
        switch theme {
        case .auto: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

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
