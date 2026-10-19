import Foundation

// MARK: - Vygenerovaný trénink (odpovídá objektům z generator.js)

struct WorkoutExercise: Codable, Hashable {
    var exerciseId: String
    var name: String
    var category: MovementCategory
    var pattern: MovementPattern
    var equipment: [Equipment]
    var levelTier: LevelTier
    var levelInfo: LevelInfo
    var reps: String
    var weight: Double?
    var unit: String?
    var loadSource: String?
    var loadPct: Int?
    var autoregAdj: Int?
    var cues: [String]
    var mistakes: [String]
    var note: String
}

struct WorkoutBlock: Codable, Hashable {
    var title: String
    var format: WorkoutFormat
    var formatLabel: String
    var durationMin: Int
    var timeCap: String?
    var scheme: String
    var exercises: [WorkoutExercise]
    var notes: String
}

struct Workout: Codable, Hashable, Identifiable {
    var date: String // "yyyy-MM-dd"
    var dayType: DayType
    var dayTypeLabel: String
    var blocks: [WorkoutBlock]
    var estKcal: Int
    var generatedAt: Date
    var edited: Bool = false
    var rpe: Int?
    var stravaActivityId: Int?
    /// Optional, ne Bool s defaultem — starší uložené tréninky tenhle klíč v JSON
    /// nemají a synthetizovaný Decodable chybějící klíč u ne-optional typu
    /// odmítne (celá historie by se tím tiše vynulovala).
    var completed: Bool?
    /// Seed náhodnosti, se kterou generátor tenhle trénink vylosoval — Optional kvůli
    /// starším uloženým tréninkům bez tohoto pole (viz `completed` výše). Umožňuje
    /// přepnutí jazyka (`AppStore.regenerateForLanguageChange`) znovu spustit generátor
    /// se STEJNÝM seedem a dostat bit přesně stejný výběr cviků, jen přeložený text,
    /// místo aby se cviky při každém přepnutí jazyka znovu (a jinak) vylosovaly.
    var variantSeed: UInt64?
    /// True jen pro záznam, co v historii existuje VÝHRADNĚ jako vedlejší efekt
    /// zaškrtnutí "splněno" na kartě Dnes — uživatel nikdy sám nestiskl
    /// "Uložit trénink". Optional s bezpečným výchozím "ne" (nil = false), ať
    /// starší uložené tréninky (bez tohoto pole) nikdy omylem nespadnou pod
    /// auto-smazání při odškrtnutí "splněno" — viz
    /// `AppStore.toggleWorkoutCompleted`/`saveCurrentWorkout`.
    var completedOnlySave: Bool?

    var id: String { date }
    var totalMinutes: Int { blocks.reduce(0) { $0 + $1.durationMin } }
    var isCompleted: Bool { completed ?? false }
}

struct PrEntry: Codable, Hashable {
    var lift: String // klíč odpovídající poli v OneRepMaxes
    var value: Double
    var date: String
}

struct StravaAuth: Codable, Hashable {
    var workerUrl: String
    var refreshToken: String?
    var athleteId: String?
    var athleteName: String?

    var isConnected: Bool { !workerUrl.isEmpty && refreshToken != nil }
}
