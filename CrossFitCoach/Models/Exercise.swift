import Foundation

// MARK: - Cvik (odpovídá položkám v data/exercises.js)

struct LevelInfo: Codable, Hashable {
    let desc: String
    let criteria: String
}

/// Nahrazuje JS objekt `{ beginner: {...}, intermediate: {...}, rx: {...} }`
/// pevnými poli místo slovníku s enum klíči (bezpečnější pro Codable).
struct ExerciseLevels: Codable, Hashable {
    let beginner: LevelInfo
    let intermediate: LevelInfo
    let rx: LevelInfo

    func info(for tier: LevelTier) -> LevelInfo {
        switch tier {
        case .beginner: return beginner
        case .intermediate: return intermediate
        case .rx: return rx
        }
    }
}

struct LoadStandardValues: Codable, Hashable {
    let M: Double
    let F: Double

    func value(for gender: Gender) -> Double {
        gender == .male ? M : F
    }
}

struct LoadStandard: Codable, Hashable {
    let rx: LoadStandardValues
    let scaled: LoadStandardValues
}

struct Exercise: Codable, Hashable, Identifiable {
    let id: String
    let name: String
    let category: MovementCategory
    let pattern: MovementPattern
    let muscles: [String]
    let equipment: [Equipment]
    let loadable: Bool
    /// Klíč do AthleteProfile.oneRM (např. "backSquat"), pokud existuje přímá vazba na 1RM.
    let oneRMKey: String?
    let variantMultiplier: Double
    let standard: LoadStandard?
    let levels: ExerciseLevels
    let cues: [String]
    let mistakes: [String]

    init(
        id: String, name: String, category: MovementCategory, pattern: MovementPattern,
        muscles: [String], equipment: [Equipment], loadable: Bool,
        oneRMKey: String? = nil, variantMultiplier: Double = 1,
        standard: LoadStandard? = nil, levels: ExerciseLevels,
        cues: [String], mistakes: [String]
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.pattern = pattern
        self.muscles = muscles
        self.equipment = equipment
        self.loadable = loadable
        self.oneRMKey = oneRMKey
        self.variantMultiplier = variantMultiplier
        self.standard = standard
        self.levels = levels
        self.cues = cues
        self.mistakes = mistakes
    }
}
