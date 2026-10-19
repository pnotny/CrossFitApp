import Foundation

/// Určuje, od jaké úrovně profilu se cvik běžně zařazuje do výběru bez omezení.
///
/// Databáze cviků (ExerciseDatabase) popisuje pro každý cvik 3 úrovně provedení
/// (beginner/intermediate/rx) — to řeší ŠKÁLOVÁNÍ (jak moc těžce/technicky se
/// cvik dělá). Tahle vrstva řeší VÝBĚR: jsou pohyby, které nemá smysl nabízet
/// začátečníkovi vůbec (muscle-up, handstand walk, plný snatch…), protože i
/// jejich "beginner" varianta je ve skutečnosti úplně jiný, průpravný pohyb
/// (např. beginner.desc u Bar Muscle-up = "nácvik high pull-upu", ne muscle-up
/// samotný). Takové cviky se objeví ve výběru až od uvedené minimální úrovně —
/// a pro úroveň přesně o stupeň nižší je generátor občas (viz
/// WorkoutGenerator.filterPool) zařadí jako postupné seznámení s novou
/// dovedností, kdy se díky existujícímu systému úrovní rovnou zobrazí jejich
/// průpravná varianta a kritérium postupu (Exercise.levels).
///
/// Cviky, které zde nejsou uvedené, jsou dostupné od úrovně beginner (jen se
/// liší váha/standard podle úrovně, ne samotný výběr).
enum ExerciseDifficulty {
    static let minimumTier: [String: LevelTier] = [
        // Olympic lifts — plné komplexy a technické drilly nad rámec beginnera.
        // Power/hang varianty (power-clean, hang-power-clean, hang-power-snatch,
        // power-snatch) jsou záměrně BEZ omezení — to jsou běžné vstupní varianty.
        "squat-clean": .intermediate,
        "clean-and-jerk": .intermediate,
        "snatch": .intermediate,
        "hang-snatch": .intermediate,
        "split-jerk": .intermediate,
        "snatch-balance": .intermediate,
        "muscle-snatch": .intermediate,
        "muscle-clean": .intermediate,
        "snatch-pull": .intermediate,
        "clean-pull": .intermediate,
        // Cluster = squat-clean + thruster v každém opakování — aspoň tak
        // náročné jako samotný squat-clean.
        "cluster": .intermediate,
        "zercher-squat": .intermediate,
        "deficit-deadlift": .intermediate,
        "good-morning": .intermediate,
        "overhead-lunge": .intermediate,

        // Gymnastika — dovednosti vyžadující specifickou techniku/sílu nad rámec
        // běžné síly; progresivní regrese (ring-row, box-step-up, knees-to-elbows…)
        // zůstávají bez omezení jako standardní vstupní body.
        "pistol-squat": .intermediate,
        "chest-to-bar-pull-up": .intermediate,
        "ring-dip": .intermediate,
        "strict-handstand-push-up": .intermediate,
        "toes-to-bar": .intermediate,
        "ghd-sit-up": .intermediate,
        "wall-walk": .intermediate,
        "rope-climb": .intermediate,
        "bar-muscle-up": .rx,
        "ring-muscle-up": .rx,
        "kipping-handstand-push-up": .rx,
        "handstand-walk": .rx,
        "butterfly-pull-up": .rx,

        // Strongman — vysoké riziko špatné techniky pod zátěží.
        "atlas-stone-to-shoulder": .intermediate,
        "tire-flip": .intermediate,
    ]

    static func rank(_ tier: LevelTier) -> Int {
        switch tier {
        case .beginner: return 0
        case .intermediate: return 1
        case .rx: return 2
        }
    }

    /// Cvik je pro danou úroveň běžnou, neomezenou součástí tréninku.
    static func isCore(_ exercise: Exercise, for tier: LevelTier) -> Bool {
        rank(minimumTier[exercise.id] ?? .beginner) <= rank(tier)
    }

    /// Cviky přesně o jednu úroveň výš — kandidáti na postupné seznámení s
    /// novou dovedností (viz filterPool), ne na běžný výběr.
    static func introductionCandidates(_ pool: [Exercise], for tier: LevelTier) -> [Exercise] {
        let nextRank = rank(tier) + 1
        return pool.filter { rank(minimumTier[$0.id] ?? .beginner) == nextRank }
    }
}
