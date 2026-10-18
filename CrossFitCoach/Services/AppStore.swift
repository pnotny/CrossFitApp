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
        authServerUrl = savedServerUrl.isEmpty ? (storage.getStravaAuth()?.workerUrl ?? "") : savedServerUrl
        loadOrGenerateWorkout()
    }

    // MARK: Přihlášení

    /// Zavolat jednou při startu appky — ověří uložený session token na serveru,
    /// než appku zpřístupní (mandatorní login gate).
    func restoreSession() async {
        defer { isRestoringSession = false }
        guard let token = KeychainStore.get(forKey: Self.authTokenKey), !authServerUrl.isEmpty else { return }
        do {
            authUser = try await AuthService.shared.me(serverUrl: authServerUrl, token: token)
        } catch {
            KeychainStore.delete(forKey: Self.authTokenKey)
        }
    }

    func login(serverUrl: String, username: String, password: String) async {
        authError = nil
        authInFlight = true
        defer { authInFlight = false }
        do {
            let (token, user) = try await AuthService.shared.login(serverUrl: serverUrl, username: username, password: password)
            persistSession(serverUrl: serverUrl, token: token, user: user)
        } catch {
            authError = error.localizedDescription
        }
    }

    func register(serverUrl: String, username: String, password: String) async {
        authError = nil
        authInFlight = true
        defer { authInFlight = false }
        do {
            let (token, user) = try await AuthService.shared.register(serverUrl: serverUrl, username: username, password: password)
            persistSession(serverUrl: serverUrl, token: token, user: user)
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
    }

    func regenerate() {
        currentWorkout = WorkoutGenerator.generateWorkout(profile: profile, dateString: viewDate, history: history)
        currentWorkoutSaved = false
        toast("Trénink přegenerován")
    }

    /// Po uložení profilu vždy přegeneruje, aby se nové údaje hned projevily
    /// (i když už pro daný den existuje uložený trénink z historie).
    func regenerateForCurrentProfile() {
        currentWorkout = WorkoutGenerator.generateWorkout(profile: profile, dateString: viewDate, history: history)
        currentWorkoutSaved = false
        editMode = false
    }

    func saveCurrentWorkout() {
        guard let w = currentWorkout else { return }
        history = storage.saveWorkoutToHistory(w)
        currentWorkoutSaved = true
        toast("Trénink uložen do historie")
    }

    func deleteCurrentWorkout() {
        history = storage.deleteWorkout(for: viewDate)
        loadOrGenerateWorkout()
        toast("Trénink smazán")
    }

    func saveRpe(_ value: Int) {
        guard var w = currentWorkout else { return }
        w.rpe = value
        history = storage.saveWorkoutToHistory(w)
        currentWorkout = w
        currentWorkoutSaved = true
        toast("RPE uloženo — příští trénink se tomu přizpůsobí")
    }

    func updateDuration(_ minutes: Int) {
        guard profile.timeAvailable != minutes else { return }
        profile.timeAvailable = minutes
        storage.saveProfile(profile)
        regenerateForCurrentProfile()
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
    }

    func loadTestProfile() {
        profile = .testProfile
        storage.saveProfile(profile)
        regenerateForCurrentProfile()
        toast("Testovací profil načten a uložen")
    }

    // MARK: PR log

    func addPrEntry(lift: String, value: Double, date: String) {
        prLog = storage.addPrEntry(PrEntry(lift: lift, value: value, date: date))
        profile.oneRM[lift] = value
        storage.saveProfile(profile)
        toast("PR uložen")
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
