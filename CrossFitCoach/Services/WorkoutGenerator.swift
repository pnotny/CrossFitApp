import Foundation

// MARK: - Pomocné funkce s daty (ekvivalent weekdayIndex/dateMinusDays v generator.js)

enum DateUtils {
    static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    static func dateString(from date: Date) -> String {
        dayFormatter.string(from: date)
    }

    static func date(from dateString: String) -> Date {
        dayFormatter.date(from: dateString) ?? Date()
    }

    static func todayString() -> String {
        dateString(from: Date())
    }

    /// pondělí = 0 ... neděle = 6
    static func weekdayIndex(_ dateString: String) -> Int {
        let parsedDate = date(from: dateString)
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let jsDay = cal.component(.weekday, from: parsedDate) // ne=1..so=7
        let zeroBasedSunday = jsDay - 1 // ne=0..so=6
        return (zeroBasedSunday + 6) % 7
    }

    static func dateMinusDays(_ dateString: String, _ n: Int) -> String {
        let parsedDate = date(from: dateString)
        guard let shifted = Calendar(identifier: .gregorian).date(byAdding: .day, value: -n, to: parsedDate) else {
            return dateString
        }
        return self.dateString(from: shifted)
    }

    static func weekDatesAround(_ dateString: String) -> [String] {
        let idx = weekdayIndex(dateString)
        let monday = dateMinusDays(dateString, idx)
        var result: [String] = []
        for i in 0..<7 {
            let d = date(from: monday)
            if let shifted = Calendar(identifier: .gregorian).date(byAdding: .day, value: i, to: d) {
                result.append(self.dateString(from: shifted))
            }
        }
        return result
    }
}

/// Jednoduchý seedovatelný PRNG (xorshift64) — `SystemRandomNumberGenerator` ze
/// standardní knihovny se seedovat nedá, a bez toho by každé spuštění generátoru
/// (i se stejným profilem/dnem) vylosovalo jiné cviky. Používá se výhradně k tomu,
/// aby přepnutí jazyka znovu vyrenderovalo STEJNÝ trénink v jiném jazyce, místo aby
/// ho znovu (a jinak) vylosovalo — viz `Workout.variantSeed` a `generateWorkout`.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed == 0 ? 0x9E3779B97F4A7C15 : seed }
    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}

// MARK: - Generátor tréninků (port js/generator.js)

enum WorkoutGenerator {

    // MARK: Filtrování databáze

    static func equipmentOk(_ exercise: Exercise, _ profileEquipment: [Equipment]) -> Bool {
        exercise.equipment.allSatisfy { $0 == .none || profileEquipment.contains($0) }
    }

    static func patternAllowed(_ exercise: Exercise, _ excluded: [MovementPattern]) -> Bool {
        exercise.bypassesPatternExclusion || !excluded.contains(exercise.pattern)
    }

    /// Cviky vyhovující vybavení/vyloučeným vzorům a úrovni profilu. Cviky nad
    /// úrovní atleta se do běžného výběru nedostanou (viz ExerciseDifficulty) —
    /// výjimkou je max. jeden cvik přesně o úroveň výš, který se příležitostně
    /// přimíchá jako postupné seznámení s novou dovedností (s odpovídající
    /// výukovou lekcí, protože toWorkoutExercise vždy zobrazí popis podle
    /// AKTUÁLNÍ úrovně atleta, ne podle cviku).
    ///
    /// `excludeStandaloneCardio`: true pro EMOM/AMRAP/ForTime/Chipper bloky — cviky
    /// jako "swim" (viz Exercise.standaloneCardioOnly) tam nepatří, protože je
    /// nereálné je uprostřed WODu reálně zařadit. Samostatný monostrukturální
    /// ("Engine") den naopak false nechává, tam dává swim smysl.
    ///
    /// `history`/`dateString`: dokud se nezadá historie, žádná "programová"
    /// posloupnost se neuplatní (viz `SkillProgression`) — bez ní by beginner
    /// měl mezi ungatovanými clean/snatch/jerk druhy pořád úplně nahodilý výběr
    /// (jeden den muscle-snatch, druhý hang-power-clean, bez logiky). S historií
    /// se to zúží na aktuální krok řetězu dané rodiny, dokud ho nezažije dost
    /// odcvičených sessions (nebo neuplyne max. počet týdnů) a nepostoupí dál.
    static func filterPool(
        _ profile: AthleteProfile, categories: [MovementCategory]?, excludeStandaloneCardio: Bool = false,
        history: [Workout] = [], dateString: String = DateUtils.todayString(), using rng: inout SeededGenerator
    ) -> [Exercise] {
        let eligible = ExerciseDatabase.all.filter { ex in
            (categories == nil || categories!.contains(ex.category)) &&
            equipmentOk(ex, profile.equipment) &&
            patternAllowed(ex, profile.excludedPatterns) &&
            (!excludeStandaloneCardio || !ex.standaloneCardioOnly)
        }
        let tier = profile.level.tier
        var core = eligible.filter { ExerciseDifficulty.isCore($0, for: tier) }
        guard tier != .rx else { return core }
        core = SkillProgression.restrictToCurrentStep(core, history: history, today: dateString)
        let intro = ExerciseDifficulty.introductionCandidates(eligible, for: tier)
        guard !intro.isEmpty, Double.random(in: 0..<1, using: &rng) < 0.25, let pick = intro.randomElement(using: &rng) else { return core }
        return core + [pick]
    }

    static func yesterdayPatterns(_ history: [Workout], _ dateString: String) -> [MovementPattern] {
        let key = DateUtils.dateMinusDays(dateString, 1)
        guard let w = history.first(where: { $0.date == key }) else { return [] }
        return w.blocks.flatMap { $0.exercises.map { $0.pattern } }
    }

    /// Pohybové vzory z TĚŽKÝCH silových bloků (format == .strength) za posledních `daysBack`
    /// dní. Tvrdé vyloučení napříč celým dalším tréninkem (síla i metcon/EMOM), aby např. po
    /// těžkém dni na nohy hned příští den/dny nebyly zase dřepy.
    static func recentHeavyPatterns(_ history: [Workout], _ dateString: String, daysBack: Int) -> Set<MovementPattern> {
        var patterns = Set<MovementPattern>()
        for i in 1...daysBack {
            let key = DateUtils.dateMinusDays(dateString, i)
            guard let w = history.first(where: { $0.date == key }) else { continue }
            for block in w.blocks where block.format == .strength {
                for ex in block.exercises { patterns.insert(ex.pattern) }
            }
        }
        return patterns
    }

    /// Kombinuje včerejší vzory (lehké vyloučení) s vzory z nedávných těžkých silových bloků
    /// (silnější vyloučení, delší okno) — použij jako základ pro avoidPatterns v celém dni.
    static func recoveryAvoidPatterns(_ history: [Workout], _ dateString: String) -> Set<MovementPattern> {
        Set(yesterdayPatterns(history, dateString)).union(recentHeavyPatterns(history, dateString, daysBack: 2))
    }

    /// Zátěž svalových skupin za posledních `daysBack` dní (novější den = vyšší váha).
    static func recentMuscleLoad(_ history: [Workout], _ dateString: String, daysBack: Int) -> [String: Int] {
        var loadMap: [String: Int] = [:]
        for i in 1...daysBack {
            let key = DateUtils.dateMinusDays(dateString, i)
            guard let w = history.first(where: { $0.date == key }) else { continue }
            let weight = daysBack - i + 1
            for block in w.blocks {
                for ex in block.exercises {
                    guard let dbEx = ExerciseDatabase.all.first(where: { $0.id == ex.exerciseId }) else { continue }
                    for muscle in dbEx.muscles {
                        loadMap[muscle, default: 0] += weight
                    }
                }
            }
        }
        return loadMap
    }

    static func muscleOverlapScore(_ exercise: Exercise, _ loadMap: [String: Int]) -> Int {
        exercise.muscles.reduce(0) { $0 + (loadMap[$1] ?? 0) }
    }

    static func leastLoadedPick(_ candidates: [Exercise], _ muscleLoad: [String: Int]?, using rng: inout SeededGenerator) -> Exercise? {
        guard !candidates.isEmpty else { return nil }
        guard let muscleLoad, !muscleLoad.isEmpty else { return candidates.randomElement(using: &rng) }
        let scored = candidates.map { ($0, muscleOverlapScore($0, muscleLoad)) }
        let minScore = scored.map(\.1).min() ?? 0
        let best = scored.filter { $0.1 == minScore }.map(\.0)
        return best.randomElement(using: &rng)
    }

    static func pickExercises(_ pool: [Exercise], count: Int, avoidPatterns: [MovementPattern], muscleLoad: [String: Int]?, using rng: inout SeededGenerator) -> [Exercise] {
        var usedPatterns = Set<MovementPattern>()
        var usedIds = Set<String>()
        var result: [Exercise] = []

        for _ in 0..<count {
            var filtered = pool.filter { !usedIds.contains($0.id) && !usedPatterns.contains($0.pattern) && !avoidPatterns.contains($0.pattern) }
            if filtered.isEmpty { filtered = pool.filter { !usedIds.contains($0.id) && !usedPatterns.contains($0.pattern) } }
            if filtered.isEmpty { filtered = pool.filter { !usedIds.contains($0.id) } }
            if filtered.isEmpty { break }
            guard let pick = leastLoadedPick(filtered, muscleLoad, using: &rng) else { break }
            result.append(pick)
            usedIds.insert(pick.id)
            usedPatterns.insert(pick.pattern)
        }
        return result
    }

    // MARK: Výpočet zátěže (1RM % / standardy) + autoregulace

    static func roundToStep(_ value: Double, _ step: Double) -> Double {
        (value / step).rounded() * step
    }

    struct LoadResult {
        var weight: Double
        var unit: String
        var source: String
        var pct: Int?
        var autoregAdj: Int
    }

    static func computeLoad(_ exercise: Exercise, _ profile: AthleteProfile, purpose: LoadPurpose, autoreg: [LoadPurpose: Int]) -> LoadResult? {
        guard exercise.loadable else { return nil }
        var pct: Double
        switch purpose {
        case .strength: pct = 0.85
        case .metcon: pct = 0.5
        case .technique: pct = 0.3
        }

        let adj = autoreg[purpose] ?? 0
        pct += Double(adj) / 100
        let bounds: (Double, Double) = {
            switch purpose {
            case .strength: return (0.65, 0.95)
            case .metcon: return (0.35, 0.65)
            case .technique: return (0.2, 0.4)
            }
        }()
        pct = max(bounds.0, min(bounds.1, pct))

        let step: Double = exercise.equipment.contains(.barbell) ? 2.5 : 1

        if let key = exercise.oneRMKey, let oneRM = profile.oneRM[key] {
            let weight = roundToStep(oneRM * exercise.variantMultiplier * pct, step)
            let liftLabel = OneRepMaxes.liftLabels.first(where: { $0.key == key })?.label ?? key
            return LoadResult(weight: weight, unit: "kg", source: "\(liftLabel) 1RM", pct: Int((pct * 100).rounded()), autoregAdj: adj)
        }
        if let standard = exercise.standard {
            // 4 odstupňované váhy (beginner/intermediate/advanced/RX) dopočítané
            // lineární interpolací mezi scaled a RX kotvami z databáze cviků —
            // advanced tak dostává citelně víc než intermediate, ne stejnou váhu jako RX.
            let blend = profile.level.standardBlend
            let table = LoadStandardValues(
                M: standard.scaled.M + (standard.rx.M - standard.scaled.M) * blend,
                F: standard.scaled.F + (standard.rx.F - standard.scaled.F) * blend
            )
            var weight = table.value(for: profile.gender)
            if purpose == .technique { weight *= 0.6 }
            weight *= 1 + max(-0.1, min(0.1, Double(adj) / 100))
            return LoadResult(weight: roundToStep(weight, step), unit: "kg", source: "\(profile.level.label) standard", pct: nil, autoregAdj: adj)
        }
        return nil
    }

    static func recentRpeAverage(_ history: [Workout], relevantFormats: Set<WorkoutFormat>, maxSessions: Int) -> Double? {
        var matches: [Int] = []
        for w in history {
            guard let rpe = w.rpe else { continue }
            if w.blocks.contains(where: { relevantFormats.contains($0.format) }) { matches.append(rpe) }
            if matches.count >= maxSessions { break }
        }
        guard !matches.isEmpty else { return nil }
        return Double(matches.reduce(0, +)) / Double(matches.count)
    }

    static func rpeToAdjustment(_ avgRpe: Double?) -> Int {
        guard let avgRpe else { return 0 }
        if avgRpe >= 9 { return -7 }
        if avgRpe >= 8 { return -3 }
        if avgRpe >= 6 { return 0 }
        if avgRpe >= 4 { return 3 }
        return 5
    }

    static func computeAutoreg(_ history: [Workout], _ profile: AthleteProfile) -> [LoadPurpose: Int] {
        guard profile.autoregEnabled else { return [.strength: 0, .metcon: 0] }
        let strengthAdj = rpeToAdjustment(recentRpeAverage(history, relevantFormats: [.strength], maxSessions: 3))
        let metconAdj = rpeToAdjustment(recentRpeAverage(history, relevantFormats: [.amrap, .emom, .forTime, .chipper], maxSessions: 3))
        return [.strength: strengthAdj, .metcon: metconAdj]
    }

    static func autoregNote(_ autoreg: [LoadPurpose: Int], _ purpose: LoadPurpose, _ language: AppLanguage = .cs) -> String {
        let adj = autoreg[purpose] ?? 0
        guard adj != 0 else { return "" }
        let sign = adj > 0 ? "+" : ""
        return language == .en
            ? " Autoregulated from recent RPE: \(sign)\(adj) % of 1RM."
            : " Autoregulace dle RPE posledních tréninků: \(sign)\(adj) % z 1RM."
    }

    static func toWorkoutExercise(_ exercise: Exercise, _ profile: AthleteProfile, purpose: LoadPurpose, reps: String, note: String, autoreg: [LoadPurpose: Int]) -> WorkoutExercise {
        let load = computeLoad(exercise, profile, purpose: purpose, autoreg: autoreg)
        let tier = profile.level.tier
        return WorkoutExercise(
            exerciseId: exercise.id, name: exercise.name, category: exercise.category, pattern: exercise.pattern,
            equipment: exercise.equipment, levelTier: tier, levelInfo: exercise.levels.info(for: tier),
            reps: reps, weight: load?.weight, unit: load?.unit, loadSource: load?.source, loadPct: load?.pct,
            autoregAdj: load?.autoregAdj, cues: exercise.cues, mistakes: exercise.mistakes, note: note
        )
    }

    static func clampInt(_ t: Int, _ lo: Int, _ hi: Int) -> Int { max(lo, min(hi, t)) }

    static func pickMetconFormat(_ candidates: [WorkoutFormat], _ profile: AthleteProfile, using rng: inout SeededGenerator) -> WorkoutFormat {
        let preferred = candidates.filter { profile.preferredFormats.contains($0) }
        let pool = preferred.isEmpty ? candidates : preferred
        return pool.randomElement(using: &rng) ?? candidates[0]
    }

    static func strengthSetsScheme(_ level: AthleteLevel, _ language: AppLanguage = .cs) -> (sets: Int, reps: Int, label: String) {
        if language == .en {
            switch level {
            case .beginner: return (3, 5, "3 sets × 5 reps")
            case .intermediate: return (4, 4, "4 sets × 4 reps")
            case .advanced, .rx: return (5, 3, "5 sets × 3 reps")
            }
        }
        switch level {
        case .beginner: return (3, 5, "3 série × 5 opakování")
        case .intermediate: return (4, 4, "4 série × 4 opakování")
        case .advanced, .rx: return (5, 3, "5 sérií × 3 opakování")
        }
    }

    // MARK: Stavba jednotlivých typů dne

    static func buildStrengthDay(_ profile: AthleteProfile, _ dateString: String, _ history: [Workout], _ autoreg: [LoadPurpose: Int], _ language: AppLanguage = .cs, using rng: inout SeededGenerator) -> [WorkoutBlock] {
        let avoid = recoveryAvoidPatterns(history, dateString)
        let muscleLoad = recentMuscleLoad(history, dateString, daysBack: 7)
        let pool = filterPool(profile, categories: [.weightlifting], history: history, dateString: dateString, using: &rng).filter { [.squat, .hinge, .push, .olympic].contains($0.pattern) }
        let mainCandidates = pool.filter { !avoid.contains($0.pattern) }
        let mainPool = mainCandidates.isEmpty ? pool : mainCandidates
        let main = leastLoadedPick(mainPool, muscleLoad, using: &rng)

        let total = profile.timeAvailable
        let strengthMin = clampInt(Int((Double(total) * 0.4 / 5).rounded()) * 5, 12, 40)
        var blocks: [WorkoutBlock] = []
        var usedPatterns: [MovementPattern] = []

        if let main {
            let scheme = strengthSetsScheme(profile.level, language)
            let wEx = toWorkoutExercise(main, profile, purpose: .strength, reps: "\(scheme.sets) × \(scheme.reps)", note: scheme.label, autoreg: autoreg)
            usedPatterns.append(main.pattern)
            let weightLabel = wEx.weight != nil ? "\(formatWeight(wEx.weight!)) kg" : (language == .en ? "per standard" : "dle standardu")
            blocks.append(WorkoutBlock(
                title: language == .en ? "Block A · Strength" : "Blok A · Síla", format: .strength, formatLabel: WorkoutFormat.strength.label(language),
                durationMin: strengthMin, timeCap: nil, scheme: scheme.label, exercises: [wEx],
                notes: (language == .en
                    ? "Gradually build up to your working weight (\(weightLabel)), 2–3 min rest between sets."
                    : "Postupné navyšování na pracovní váhu (\(weightLabel)), 2–3 min odpočinek mezi sériemi.") + autoregNote(autoreg, .strength, language)
            ))
        }

        let metconMinutes = clampInt(total - (main != nil ? strengthMin : 0), 8, 60)
        let metconPool = filterPool(profile, categories: [.gymnastics, .monostructural, .strongman, .weightlifting], excludeStandaloneCardio: true, history: history, dateString: dateString, using: &rng)
            .filter { !usedPatterns.contains($0.pattern) || $0.category == .monostructural }
        blocks.append(contentsOf: buildMetconSegments(
            titlePrefix: language == .en ? "Block B · Metcon" : "Blok B · Metcon", formatCandidates: [.amrap, .emom, .forTime], pool: metconPool,
            profile: profile, totalMinutes: metconMinutes, baseAvoidPatterns: usedPatterns + Array(avoid), muscleLoad: muscleLoad, autoreg: autoreg, language: language, using: &rng
        ))
        return blocks
    }

    static func buildGymnasticsDay(_ profile: AthleteProfile, _ dateString: String, _ history: [Workout], _ autoreg: [LoadPurpose: Int], _ language: AppLanguage = .cs, using rng: inout SeededGenerator) -> [WorkoutBlock] {
        let avoid = recoveryAvoidPatterns(history, dateString)
        let muscleLoad = recentMuscleLoad(history, dateString, daysBack: 7)
        let skillPool = filterPool(profile, categories: [.gymnastics], history: history, dateString: dateString, using: &rng).filter { !avoid.contains($0.pattern) }
        let skillCandidates = skillPool.isEmpty ? filterPool(profile, categories: [.gymnastics], history: history, dateString: dateString, using: &rng) : skillPool
        let skillPick = leastLoadedPick(skillCandidates, muscleLoad, using: &rng)

        let total = profile.timeAvailable
        let skillMin = clampInt(Int((Double(total) * 0.3 / 5).rounded()) * 5, 8, 25)
        var blocks: [WorkoutBlock] = []
        var usedPatterns: [MovementPattern] = []

        if let skillPick {
            usedPatterns.append(skillPick.pattern)
            let tier = profile.level.tier
            let info = skillPick.levels.info(for: tier)
            let wEx = toWorkoutExercise(skillPick, profile, purpose: .technique, reps: language == .en ? "5 × 3–5 quality reps" : "5 × 3–5 kvalitních opakování", note: language == .en ? "Technique practice" : "Technický nácvik", autoreg: autoreg)
            blocks.append(WorkoutBlock(
                title: language == .en ? "Block A · Skill" : "Blok A · Skill", format: .strength, formatLabel: language == .en ? "Technique" : "Technika",
                durationMin: skillMin, timeCap: nil, scheme: language == .en ? "5 sets, focus on quality" : "5 sérií, důraz na kvalitu", exercises: [wEx],
                notes: "\(language == .en ? "Criteria to advance" : "Kritérium postupu"): \(info.criteria)"
            ))
        }

        let emomMinutes = clampInt(total - (skillPick != nil ? skillMin : 0), 8, 65)
        let emomPool = filterPool(profile, categories: [.gymnastics, .monostructural, .weightlifting, .strongman], excludeStandaloneCardio: true, history: history, dateString: dateString, using: &rng)
        blocks.append(contentsOf: buildMetconSegments(
            titlePrefix: language == .en ? "Block B · EMOM" : "Blok B · EMOM", formatCandidates: [.emom, .amrap], pool: emomPool,
            profile: profile, totalMinutes: emomMinutes, baseAvoidPatterns: usedPatterns + Array(avoid), muscleLoad: muscleLoad, autoreg: autoreg, language: language, using: &rng
        ))
        return blocks
    }

    static func buildMonostructuralDay(_ profile: AthleteProfile, _ language: AppLanguage = .cs, using rng: inout SeededGenerator) -> [WorkoutBlock] {
        let pool = filterPool(profile, categories: [.monostructural], using: &rng)
        let total = clampInt(profile.timeAvailable, 12, 90)
        guard !pool.isEmpty else {
            return [WorkoutBlock(
                title: "Engine", format: .steady, formatLabel: WorkoutFormat.steady.label(language),
                durationMin: total, timeCap: nil, scheme: language == .en ? "Active recovery" : "Aktivní regenerace", exercises: [],
                notes: language == .en
                    ? "No monostructural equipment available — pick a light walk/easy spin as active recovery."
                    : "Nemáš k dispozici žádné monostrukturální vybavení — zvol volnou chůzi/lehký výklus jako aktivní regeneraci."
            )]
        }
        let candidateFormats: [WorkoutFormat] = total <= 20 ? [.tabata, .intervals] : [.intervals, .steady]
        let format = pickMetconFormat(candidateFormats, profile, using: &rng)
        guard let pick = pool.randomElement(using: &rng) else { return [] }
        var wEx = toWorkoutExercise(pick, profile, purpose: .metcon, reps: "", note: "", autoreg: [:])

        if format == .tabata {
            wEx.reps = language == .en ? "8 rounds × 20s work / 10s rest" : "8 kol × 20 s práce / 10 s odpočinek"
            return [WorkoutBlock(
                title: "Engine · Tabata", format: format, formatLabel: WorkoutFormat.tabata.label(language),
                durationMin: 4, timeCap: nil, scheme: "8 × (20s ON / 10s OFF)", exercises: [wEx],
                notes: language == .en ? "Max effort in every 20s interval." : "Maximální úsilí v každém 20s intervalu."
            )]
        }
        if format == .intervals {
            // Nad ~40 min je dost času i na objemovější variantu (víc kol, kratší
            // odpočinek — "15× 500 m" styl) místo běžných delších intervalů s
            // vydatnějším odpočinkem. Volba kostkou, ať se dny neopakují stejně.
            let highVolume = total >= 40 && Double.random(in: 0..<1, using: &rng) < 0.5
            if highVolume {
                let rounds = clampInt(Int((Double(total) / 4).rounded()), 10, 18)
                wEx.reps = language == .en ? "\(rounds) × 500 m / 60 s rest" : "\(rounds) × 500 m / 60 s odpočinek"
                return [WorkoutBlock(
                    title: language == .en ? "Engine · Intervals (high volume)" : "Engine · Intervaly (vysoký objem)",
                    format: format, formatLabel: WorkoutFormat.intervals.label(language),
                    durationMin: total, timeCap: nil,
                    scheme: language == .en ? "\(rounds) short intervals, short rest" : "\(rounds) krátkých intervalů, krátký odpočinek", exercises: [wEx],
                    notes: language == .en
                        ? "High volume, shorter rest — hold one consistent, repeatable pace across all rounds rather than going out too hard."
                        : "Vysoký objem, kratší odpočinek — držet jedno konzistentní, opakovatelné tempo napříč všemi koly místo prvních rychlých kol."
                )]
            }
            let rounds = clampInt(Int((Double(total) / 6).rounded()), 4, 14)
            wEx.reps = language == .en ? "\(rounds) × 500 m (or 90 s) / 90 s rest" : "\(rounds) × 500 m (nebo 90 s) / 90 s odpočinek"
            return [WorkoutBlock(
                title: "Engine · Intervaly", format: format, formatLabel: WorkoutFormat.intervals.label(language),
                durationMin: total, timeCap: nil, scheme: language == .en ? "\(rounds) intervals with steady rest" : "\(rounds) intervalů se stálým odpočinkem", exercises: [wEx],
                notes: language == .en ? "Keep a consistent pace/split across all rounds." : "Udržuj konzistentní tempo/split napříč všemi koly."
            )]
        }
        // Nad ~45 min se místo běžného steady state dá občas (kostkou) zařadit
        // dlouhý vytrvalostní blok — obdoba "dlouhého běhu", jen formulovaná
        // obecně přes vzdálenost/čas, ať sedí na běh/kolo/veslování stejně.
        let longSession = total >= 45 && Double.random(in: 0..<1, using: &rng) < 0.4
        if longSession {
            wEx.reps = language == .en ? "\(total) min continuous, zone 2 (~8–12 km if running/cycling/rowing)" : "\(total) min v jednom tahu, zóna 2 (~8–12 km při běhu/kole/veslování)"
            return [WorkoutBlock(
                title: language == .en ? "Engine · Long" : "Engine · Dlouhý",
                format: .steady, formatLabel: WorkoutFormat.steady.label(language),
                durationMin: total, timeCap: nil, scheme: language == .en ? "Long continuous effort" : "Dlouhý souvislý výkon", exercises: [wEx],
                notes: language == .en
                    ? "Long aerobic build — conversational pace the whole way, resist the urge to push harder in the middle."
                    : "Dlouhý aerobní blok — konverzační tempo po celou dobu, uprostřed neponičej síly zbytečným zrychlováním."
            )]
        }
        wEx.reps = language == .en ? "\(total) minutes at steady pace (zone 2–3)" : "\(total) minut v konstantním tempu (zóna 2–3)"
        return [WorkoutBlock(
            title: "Engine · Steady State", format: format, formatLabel: WorkoutFormat.steady.label(language),
            durationMin: total, timeCap: nil, scheme: language == .en ? "Steady pace" : "Souvislé tempo", exercises: [wEx],
            notes: language == .en ? "Sustainable, conversational pace the whole time." : "Udržitelné, konverzační tempo po celou dobu."
        )]
    }

    static func buildChipperDay(_ profile: AthleteProfile, _ dateString: String, _ history: [Workout], _ autoreg: [LoadPurpose: Int], _ language: AppLanguage = .cs, using rng: inout SeededGenerator) -> [WorkoutBlock] {
        let avoid = recoveryAvoidPatterns(history, dateString)
        let muscleLoad = recentMuscleLoad(history, dateString, daysBack: 7)
        let pool = filterPool(profile, categories: [.gymnastics, .monostructural, .strongman, .weightlifting], excludeStandaloneCardio: true, history: history, dateString: dateString, using: &rng)
        let timeCap = clampInt(profile.timeAvailable, 15, 90)
        let count = clampInt(Int((Double(timeCap) / 6).rounded()), 4, 8)
        let picks = pickExercises(pool, count: count, avoidPatterns: Array(avoid), muscleLoad: muscleLoad, using: &rng)
        let baseReps = [50, 40, 35, 30, 25, 20, 15, 10]
        let exercises = picks.enumerated().map { i, ex in
            toWorkoutExercise(ex, profile, purpose: .metcon, reps: String(i < baseReps.count ? baseReps[i] : 15), note: "", autoreg: autoreg)
        }
        return [WorkoutBlock(
            title: "Chipper", format: .chipper, formatLabel: WorkoutFormat.chipper.label(language),
            durationMin: timeCap, timeCap: "\(timeCap) min", scheme: language == .en ? "For Time — go through the exercises in order, once each" : "For Time — projdi cviky v pořadí, jednou každý",
            exercises: exercises, notes: (language == .en
                ? "Long volume workout — pace yourself, don't start too fast."
                : "Dlouhý objemový trénink — rozlož síly, nezačínej zbytečně rychle.") + autoregNote(autoreg, .metcon, language)
        )]
    }

    static func buildMetconBlock(title: String, format: WorkoutFormat, picks: [Exercise], profile: AthleteProfile, minutes: Int, autoreg: [LoadPurpose: Int], language: AppLanguage = .cs) -> WorkoutBlock {
        var exercises = picks.map { toWorkoutExercise($0, profile, purpose: .metcon, reps: "", note: "", autoreg: autoreg) }
        let note = autoregNote(autoreg, .metcon, language)

        if format == .emom {
            for i in exercises.indices {
                exercises[i].reps = language == .en
                    ? (exercises[i].category == .monostructural ? "12–15 cals" : (exercises[i].category == .gymnastics ? "8–12 reps" : "5–6 reps"))
                    : (exercises[i].category == .monostructural ? "12–15 kalorií" : (exercises[i].category == .gymnastics ? "8–12 opakování" : "5–6 opakování"))
                exercises[i].note = language == .en ? "Minute \(i + 1) of every cycle" : "Minuta \(i + 1) z každého cyklu"
            }
            return WorkoutBlock(
                title: title, format: .emom, formatLabel: WorkoutFormat.emom.label(language), durationMin: minutes, timeCap: nil,
                scheme: language == .en ? "EMOM \(minutes) min — rotate \(exercises.count) exercises each minute" : "EMOM \(minutes) min — střídej \(exercises.count) cviky po minutách", exercises: exercises,
                notes: (language == .en
                    ? "Aim to finish the work in the first half of the minute, leaving time to rest."
                    : "Cílem je zvládnout práci vždy v první polovině minuty a mít prostor na odpočinek.") + note
            )
        }
        if format == .forTime {
            for i in exercises.indices {
                exercises[i].reps = language == .en
                    ? (exercises[i].category == .monostructural ? "15 cals" : "15 reps")
                    : (exercises[i].category == .monostructural ? "15 kalorií" : "15 opakování")
            }
            let cap = "\(minutes) min"
            let names = exercises.map(\.name).joined(separator: ", ")
            return WorkoutBlock(
                title: title, format: .forTime, formatLabel: WorkoutFormat.forTime.label(language), durationMin: minutes, timeCap: cap,
                scheme: language == .en ? "3 rounds For Time — \(names)" : "3 kola For Time — \(names)", exercises: exercises,
                notes: "\(language == .en ? "Time cap" : "Time cap") \(cap). \(language == .en ? "Note your finish time to track progress." : "Piš si čas dokončení pro sledování progresu.")\(note)"
            )
        }
        for i in exercises.indices {
            exercises[i].reps = language == .en
                ? (exercises[i].category == .monostructural ? "12 cals" : "10 reps")
                : (exercises[i].category == .monostructural ? "12 kalorií" : "10 opakování")
        }
        return WorkoutBlock(
            title: title, format: .amrap, formatLabel: WorkoutFormat.amrap.label(language), durationMin: minutes, timeCap: nil,
            scheme: "AMRAP \(minutes) min", exercises: exercises,
            notes: (language == .en
                ? "As many complete rounds as possible in the time, technique before speed."
                : "Co nejvíce kompletních kol v daném čase, technika před rychlostí.") + note
        )
    }

    /// Dlouhý metcon/EMOM v jedné neměnné sadě cviků je mentálně vyčerpávající — nad ~22 min
    /// proto rozdělíme na 2–4 kratší segmenty (~15 min každý) s vlastním výběrem cviků.
    static func buildMetconSegments(
        titlePrefix: String, formatCandidates: [WorkoutFormat], pool: [Exercise], profile: AthleteProfile,
        totalMinutes: Int, baseAvoidPatterns: [MovementPattern], muscleLoad: [String: Int], autoreg: [LoadPurpose: Int],
        exercisesPerSegment: Int = 3, language: AppLanguage = .cs, using rng: inout SeededGenerator
    ) -> [WorkoutBlock] {
        let format = pickMetconFormat(formatCandidates, profile, using: &rng)
        let numSegments = totalMinutes > 22 ? clampInt(Int((Double(totalMinutes) / 15).rounded()), 2, 4) : 1
        let segMinutes = clampInt(Int((Double(totalMinutes) / Double(numSegments) / 5).rounded()) * 5, 8, 20)

        var blocks: [WorkoutBlock] = []
        var cumulativePatterns = baseAvoidPatterns
        var cumulativeIds: [String] = []

        for i in 0..<numSegments {
            var segPool = pool.filter { !cumulativeIds.contains($0.id) }
            if segPool.count < exercisesPerSegment { segPool = pool }
            let picks = pickExercises(segPool, count: exercisesPerSegment, avoidPatterns: cumulativePatterns, muscleLoad: muscleLoad, using: &rng)
            let label = numSegments > 1 ? "\(titlePrefix) · \(i + 1)/\(numSegments)" : titlePrefix
            var block = buildMetconBlock(title: label, format: format, picks: picks, profile: profile, minutes: segMinutes, autoreg: autoreg, language: language)
            if numSegments > 1 {
                block.notes += language == .en
                    ? " Short rest (2–3 min) and a new set of exercises for different muscle groups."
                    : " Krátký odpočinek (2–3 min) a nová sada cviků na jiné partie."
            }
            blocks.append(block)
            for p in picks { cumulativePatterns.append(p.pattern); cumulativeIds.append(p.id) }
        }
        return blocks
    }

    static func estimateCalories(_ blocks: [WorkoutBlock], bodyweight: Double) -> Int {
        var total = 0.0
        for b in blocks {
            total += b.format.met * 3.5 * bodyweight / 200 * Double(b.durationMin)
        }
        return Int(total.rounded())
    }

    /// Pár variant odpočinkové poznámky (mobilita + mentální/spánková regenerace),
    /// aby odpočinkový den nebyl pořád slovo od slova stejný. Výběr přes `rng`, ať
    /// je deterministický pro stejný den/seed (viz `generateWorkout`).
    static func restDayNotes(_ language: AppLanguage, using rng: inout SeededGenerator) -> String {
        let variantsCS = [
            "Lehké strečování, mobilita kyčlí a ramen, procházka. Žádná intenzivní zátěž. Věnuj pozornost i regeneraci mimo tělo — 5–10 minut klidného dýchání nebo krátká meditace pomůžou nervové soustavě se restartovat, a dostatek spánku (7–9 hodin) je pro regeneraci svalů důležitější než jakýkoli trénink.",
            "Dnes žádný trénink — jen pohyb pro radost: procházka, lehké jízdní kolo nebo klidné plavání. Doplň tekutiny a bílkoviny a dej si čas na kvalitní spánek. Zkus pár minut mindfulness nebo dechového cvičení (např. 4-7-8 dýchání) — pomáhá snížit stres a urychlit regeneraci nervové soustavy.",
            "Odpočinkový den je součást tréninku, ne jeho přerušení. Mobilita kyčlí/ramen, lehké strečování, procházka v přírodě. Zkus večer odložit telefon o něco dřív a věnovat 10 minut tichu nebo meditaci — regenerace hlavy je stejně důležitá jako regenerace svalů."
        ]
        let variantsEN = [
            "Light stretching, hip and shoulder mobility, a walk. No intense load. Give recovery outside the gym some attention too — 5–10 minutes of calm breathing or a short meditation help reset your nervous system, and 7–9 hours of sleep matters more for muscle recovery than any workout.",
            "No training today — just movement for joy: a walk, an easy bike ride, or relaxed swimming. Rehydrate, get enough protein, and protect your sleep. Try a few minutes of mindfulness or breathwork (e.g. 4-7-8 breathing) — it lowers stress and speeds up nervous-system recovery.",
            "A rest day is part of training, not a break from it. Hip/shoulder mobility, light stretching, a walk outside. Try putting your phone down a little earlier tonight and spending 10 minutes in silence or meditating — recovering your mind matters as much as recovering your muscles."
        ]
        let variants = language == .en ? variantsEN : variantsCS
        return variants[Int.random(in: 0..<variants.count, using: &rng)]
    }

    // MARK: Veřejné API

    /// `seed`: nil = úplně nový (náhodný) výběr cviků, jako při prvním vygenerování
    /// dne nebo explicitním "Přegenerovat". Když se předá seed z dřívějšího
    /// `Workout.variantSeed`, generátor se stejným profilem/dnem/historií vylosuje
    /// BIT PŘESNĚ stejné cviky znovu — používá se při přepnutí jazyka, kdy se má
    /// změnit jen text, ne obsah tréninku (viz `AppStore.regenerateForLanguageChange`).
    static func generateWorkout(profile: AthleteProfile, dateString: String, history: [Workout], language: AppLanguage = .cs, seed: UInt64? = nil) -> Workout {
        let resolvedSeed = seed ?? UInt64.random(in: UInt64.min...UInt64.max)
        var rng = SeededGenerator(seed: resolvedSeed)

        let dayIdx = DateUtils.weekdayIndex(dateString)
        let dayType = dayIdx < profile.weeklyTemplate.count ? profile.weeklyTemplate[dayIdx] : .rest

        if dayType == .rest {
            return Workout(
                date: dateString, dayType: .rest, dayTypeLabel: DayType.rest.label(language),
                blocks: [WorkoutBlock(
                    title: language == .en ? "Rest" : "Odpočinek", format: .rest, formatLabel: WorkoutFormat.rest.label(language),
                    durationMin: 20, timeCap: nil, scheme: language == .en ? "Mobility / recovery" : "Mobilita / regenerace", exercises: [],
                    notes: restDayNotes(language, using: &rng)
                )],
                estKcal: 60, generatedAt: Date(), edited: false, rpe: nil, variantSeed: resolvedSeed
            )
        }

        let autoreg = computeAutoreg(history, profile)
        let blocks: [WorkoutBlock]
        switch dayType {
        case .strength: blocks = buildStrengthDay(profile, dateString, history, autoreg, language, using: &rng)
        case .gymnastics: blocks = buildGymnasticsDay(profile, dateString, history, autoreg, language, using: &rng)
        case .monostructural: blocks = buildMonostructuralDay(profile, language, using: &rng)
        case .chipper: blocks = buildChipperDay(profile, dateString, history, autoreg, language, using: &rng)
        case .rest: blocks = [] // nedosažitelné, ošetřeno výše
        }

        return Workout(
            date: dateString, dayType: dayType, dayTypeLabel: dayType.label(language), blocks: blocks,
            estKcal: estimateCalories(blocks, bodyweight: profile.bodyweight),
            generatedAt: Date(), edited: false, rpe: nil, variantSeed: resolvedSeed
        )
    }

    static func formatWeight(_ w: Double) -> String {
        w == w.rounded() ? String(Int(w)) : String(format: "%.1f", w)
    }
}
