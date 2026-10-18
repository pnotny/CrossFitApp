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

// MARK: - Generátor tréninků (port js/generator.js)

enum WorkoutGenerator {

    // MARK: Filtrování databáze

    static func equipmentOk(_ exercise: Exercise, _ profileEquipment: [Equipment]) -> Bool {
        exercise.equipment.allSatisfy { $0 == .none || profileEquipment.contains($0) }
    }

    static func patternAllowed(_ exercise: Exercise, _ excluded: [MovementPattern]) -> Bool {
        !excluded.contains(exercise.pattern)
    }

    static func filterPool(_ profile: AthleteProfile, categories: [MovementCategory]?) -> [Exercise] {
        ExerciseDatabase.all.filter { ex in
            (categories == nil || categories!.contains(ex.category)) &&
            equipmentOk(ex, profile.equipment) &&
            patternAllowed(ex, profile.excludedPatterns)
        }
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

    static func leastLoadedPick(_ candidates: [Exercise], _ muscleLoad: [String: Int]?) -> Exercise? {
        guard !candidates.isEmpty else { return nil }
        guard let muscleLoad, !muscleLoad.isEmpty else { return candidates.randomElement() }
        let scored = candidates.map { ($0, muscleOverlapScore($0, muscleLoad)) }
        let minScore = scored.map(\.1).min() ?? 0
        let best = scored.filter { $0.1 == minScore }.map(\.0)
        return best.randomElement()
    }

    static func pickExercises(_ pool: [Exercise], count: Int, avoidPatterns: [MovementPattern], muscleLoad: [String: Int]?) -> [Exercise] {
        var usedPatterns = Set<MovementPattern>()
        var usedIds = Set<String>()
        var result: [Exercise] = []

        for _ in 0..<count {
            var filtered = pool.filter { !usedIds.contains($0.id) && !usedPatterns.contains($0.pattern) && !avoidPatterns.contains($0.pattern) }
            if filtered.isEmpty { filtered = pool.filter { !usedIds.contains($0.id) && !usedPatterns.contains($0.pattern) } }
            if filtered.isEmpty { filtered = pool.filter { !usedIds.contains($0.id) } }
            if filtered.isEmpty { break }
            guard let pick = leastLoadedPick(filtered, muscleLoad) else { break }
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
            return LoadResult(weight: weight, unit: "kg", source: "1RM", pct: Int((pct * 100).rounded()), autoregAdj: adj)
        }
        if let standard = exercise.standard {
            let tier = profile.level.tier
            let table: LoadStandardValues
            switch tier {
            case .beginner: table = standard.scaled
            case .rx: table = standard.rx
            case .intermediate: table = LoadStandardValues(M: (standard.rx.M + standard.scaled.M) / 2, F: (standard.rx.F + standard.scaled.F) / 2)
            }
            var weight = table.value(for: profile.gender)
            if purpose == .technique { weight *= 0.6 }
            weight *= 1 + max(-0.1, min(0.1, Double(adj) / 100))
            let sourceLabel = tier == .rx ? "RX standard" : "Scaled standard"
            return LoadResult(weight: roundToStep(weight, step), unit: "kg", source: sourceLabel, pct: nil, autoregAdj: adj)
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

    static func autoregNote(_ autoreg: [LoadPurpose: Int], _ purpose: LoadPurpose) -> String {
        let adj = autoreg[purpose] ?? 0
        guard adj != 0 else { return "" }
        let sign = adj > 0 ? "+" : ""
        return " Autoregulace dle RPE posledních tréninků: \(sign)\(adj) % z 1RM."
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

    static func pickMetconFormat(_ candidates: [WorkoutFormat], _ profile: AthleteProfile) -> WorkoutFormat {
        let preferred = candidates.filter { profile.preferredFormats.contains($0) }
        let pool = preferred.isEmpty ? candidates : preferred
        return pool.randomElement() ?? candidates[0]
    }

    static func strengthSetsScheme(_ level: AthleteLevel) -> (sets: Int, reps: Int, label: String) {
        switch level {
        case .beginner: return (3, 5, "3 série × 5 opakování")
        case .intermediate: return (4, 4, "4 série × 4 opakování")
        case .advanced, .rx: return (5, 3, "5 sérií × 3 opakování")
        }
    }

    // MARK: Stavba jednotlivých typů dne

    static func buildStrengthDay(_ profile: AthleteProfile, _ dateString: String, _ history: [Workout], _ autoreg: [LoadPurpose: Int]) -> [WorkoutBlock] {
        let avoid = recoveryAvoidPatterns(history, dateString)
        let muscleLoad = recentMuscleLoad(history, dateString, daysBack: 7)
        let pool = filterPool(profile, categories: [.weightlifting]).filter { [.squat, .hinge, .push, .olympic].contains($0.pattern) }
        let mainCandidates = pool.filter { !avoid.contains($0.pattern) }
        let mainPool = mainCandidates.isEmpty ? pool : mainCandidates
        let main = leastLoadedPick(mainPool, muscleLoad)

        let total = profile.timeAvailable
        let strengthMin = clampInt(Int((Double(total) * 0.4 / 5).rounded()) * 5, 12, 30)
        var blocks: [WorkoutBlock] = []
        var usedPatterns: [MovementPattern] = []

        if let main {
            let scheme = strengthSetsScheme(profile.level)
            let wEx = toWorkoutExercise(main, profile, purpose: .strength, reps: "\(scheme.sets) × \(scheme.reps)", note: scheme.label, autoreg: autoreg)
            usedPatterns.append(main.pattern)
            let weightLabel = wEx.weight != nil ? "\(formatWeight(wEx.weight!)) kg" : "dle standardu"
            blocks.append(WorkoutBlock(
                title: "Blok A · Síla", format: .strength, formatLabel: WorkoutFormat.strength.label,
                durationMin: strengthMin, timeCap: nil, scheme: scheme.label, exercises: [wEx],
                notes: "Postupné navyšování na pracovní váhu (\(weightLabel)), 2–3 min odpočinek mezi sériemi.\(autoregNote(autoreg, .strength))"
            ))
        }

        let metconMinutes = clampInt(total - (main != nil ? strengthMin : 0), 8, 40)
        let metconPool = filterPool(profile, categories: [.gymnastics, .monostructural, .strongman, .weightlifting])
            .filter { !usedPatterns.contains($0.pattern) || $0.category == .monostructural }
        blocks.append(contentsOf: buildMetconSegments(
            titlePrefix: "Blok B · Metcon", formatCandidates: [.amrap, .emom, .forTime], pool: metconPool,
            profile: profile, totalMinutes: metconMinutes, baseAvoidPatterns: usedPatterns + Array(avoid), muscleLoad: muscleLoad, autoreg: autoreg
        ))
        return blocks
    }

    static func buildGymnasticsDay(_ profile: AthleteProfile, _ dateString: String, _ history: [Workout], _ autoreg: [LoadPurpose: Int]) -> [WorkoutBlock] {
        let avoid = recoveryAvoidPatterns(history, dateString)
        let muscleLoad = recentMuscleLoad(history, dateString, daysBack: 7)
        let skillPool = filterPool(profile, categories: [.gymnastics]).filter { !avoid.contains($0.pattern) }
        let skillCandidates = skillPool.isEmpty ? filterPool(profile, categories: [.gymnastics]) : skillPool
        let skillPick = leastLoadedPick(skillCandidates, muscleLoad)

        let total = profile.timeAvailable
        let skillMin = clampInt(Int((Double(total) * 0.3 / 5).rounded()) * 5, 8, 18)
        var blocks: [WorkoutBlock] = []
        var usedPatterns: [MovementPattern] = []

        if let skillPick {
            usedPatterns.append(skillPick.pattern)
            let tier = profile.level.tier
            let info = skillPick.levels.info(for: tier)
            let wEx = toWorkoutExercise(skillPick, profile, purpose: .technique, reps: "5 × 3–5 kvalitních opakování", note: "Technický nácvik", autoreg: autoreg)
            blocks.append(WorkoutBlock(
                title: "Blok A · Skill", format: .strength, formatLabel: "Technika",
                durationMin: skillMin, timeCap: nil, scheme: "5 sérií, důraz na kvalitu", exercises: [wEx],
                notes: "Kritérium postupu: \(info.criteria)"
            ))
        }

        let emomMinutes = clampInt(total - (skillPick != nil ? skillMin : 0), 8, 40)
        let emomPool = filterPool(profile, categories: [.gymnastics, .monostructural, .weightlifting, .strongman])
        blocks.append(contentsOf: buildMetconSegments(
            titlePrefix: "Blok B · EMOM", formatCandidates: [.emom, .amrap], pool: emomPool,
            profile: profile, totalMinutes: emomMinutes, baseAvoidPatterns: usedPatterns + Array(avoid), muscleLoad: muscleLoad, autoreg: autoreg
        ))
        return blocks
    }

    static func buildMonostructuralDay(_ profile: AthleteProfile) -> [WorkoutBlock] {
        let pool = filterPool(profile, categories: [.monostructural])
        let total = clampInt(profile.timeAvailable, 12, 90)
        guard !pool.isEmpty else {
            return [WorkoutBlock(
                title: "Engine", format: .steady, formatLabel: WorkoutFormat.steady.label,
                durationMin: total, timeCap: nil, scheme: "Aktivní regenerace", exercises: [],
                notes: "Nemáš k dispozici žádné monostrukturální vybavení — zvol volnou chůzi/lehký výklus jako aktivní regeneraci."
            )]
        }
        let candidateFormats: [WorkoutFormat] = total <= 20 ? [.tabata, .intervals] : [.intervals, .steady]
        let format = pickMetconFormat(candidateFormats, profile)
        guard let pick = pool.randomElement() else { return [] }
        var wEx = toWorkoutExercise(pick, profile, purpose: .metcon, reps: "", note: "", autoreg: [:])

        if format == .tabata {
            wEx.reps = "8 kol × 20 s práce / 10 s odpočinek"
            return [WorkoutBlock(
                title: "Engine · Tabata", format: format, formatLabel: WorkoutFormat.tabata.label,
                durationMin: 4, timeCap: nil, scheme: "8 × (20s ON / 10s OFF)", exercises: [wEx],
                notes: "Maximální úsilí v každém 20s intervalu."
            )]
        }
        if format == .intervals {
            let rounds = clampInt(Int((Double(total) / 6).rounded()), 4, 14)
            wEx.reps = "\(rounds) × 500 m (nebo 90 s) / 90 s odpočinek"
            return [WorkoutBlock(
                title: "Engine · Intervaly", format: format, formatLabel: WorkoutFormat.intervals.label,
                durationMin: total, timeCap: nil, scheme: "\(rounds) intervalů se stálým odpočinkem", exercises: [wEx],
                notes: "Udržuj konzistentní tempo/split napříč všemi koly."
            )]
        }
        wEx.reps = "\(total) minut v konstantním tempu (zóna 2–3)"
        return [WorkoutBlock(
            title: "Engine · Steady State", format: format, formatLabel: WorkoutFormat.steady.label,
            durationMin: total, timeCap: nil, scheme: "Souvislé tempo", exercises: [wEx],
            notes: "Udržitelné, konverzační tempo po celou dobu."
        )]
    }

    static func buildChipperDay(_ profile: AthleteProfile, _ dateString: String, _ history: [Workout], _ autoreg: [LoadPurpose: Int]) -> [WorkoutBlock] {
        let avoid = recoveryAvoidPatterns(history, dateString)
        let muscleLoad = recentMuscleLoad(history, dateString, daysBack: 7)
        let pool = filterPool(profile, categories: [.gymnastics, .monostructural, .strongman, .weightlifting])
        let timeCap = clampInt(profile.timeAvailable, 15, 60)
        let count = clampInt(Int((Double(timeCap) / 6).rounded()), 4, 8)
        let picks = pickExercises(pool, count: count, avoidPatterns: Array(avoid), muscleLoad: muscleLoad)
        let baseReps = [50, 40, 35, 30, 25, 20, 15, 10]
        let exercises = picks.enumerated().map { i, ex in
            toWorkoutExercise(ex, profile, purpose: .metcon, reps: String(i < baseReps.count ? baseReps[i] : 15), note: "", autoreg: autoreg)
        }
        return [WorkoutBlock(
            title: "Chipper", format: .chipper, formatLabel: WorkoutFormat.chipper.label,
            durationMin: timeCap, timeCap: "\(timeCap) min", scheme: "For Time — projdi cviky v pořadí, jednou každý",
            exercises: exercises, notes: "Dlouhý objemový trénink — rozlož síly, nezačínej zbytečně rychle.\(autoregNote(autoreg, .metcon))"
        )]
    }

    static func buildMetconBlock(title: String, format: WorkoutFormat, picks: [Exercise], profile: AthleteProfile, minutes: Int, autoreg: [LoadPurpose: Int]) -> WorkoutBlock {
        var exercises = picks.map { toWorkoutExercise($0, profile, purpose: .metcon, reps: "", note: "", autoreg: autoreg) }
        let note = autoregNote(autoreg, .metcon)

        if format == .emom {
            for i in exercises.indices {
                exercises[i].reps = exercises[i].category == .monostructural ? "12–15 kalorií"
                    : (exercises[i].category == .gymnastics ? "8–12 opakování" : "5–6 opakování")
                exercises[i].note = "Minuta \(i + 1) z každého cyklu"
            }
            return WorkoutBlock(
                title: title, format: .emom, formatLabel: WorkoutFormat.emom.label, durationMin: minutes, timeCap: nil,
                scheme: "EMOM \(minutes) min — střídej \(exercises.count) cviky po minutách", exercises: exercises,
                notes: "Cílem je zvládnout práci vždy v první polovině minuty a mít prostor na odpočinek.\(note)"
            )
        }
        if format == .forTime {
            for i in exercises.indices {
                exercises[i].reps = exercises[i].category == .monostructural ? "15 kalorií" : "15 opakování"
            }
            let cap = "\(minutes) min"
            let names = exercises.map(\.name).joined(separator: ", ")
            return WorkoutBlock(
                title: title, format: .forTime, formatLabel: WorkoutFormat.forTime.label, durationMin: minutes, timeCap: cap,
                scheme: "3 kola For Time — \(names)", exercises: exercises,
                notes: "Time cap \(cap). Piš si čas dokončení pro sledování progresu.\(note)"
            )
        }
        for i in exercises.indices {
            exercises[i].reps = exercises[i].category == .monostructural ? "12 kalorií" : "10 opakování"
        }
        return WorkoutBlock(
            title: title, format: .amrap, formatLabel: WorkoutFormat.amrap.label, durationMin: minutes, timeCap: nil,
            scheme: "AMRAP \(minutes) min", exercises: exercises,
            notes: "Co nejvíce kompletních kol v daném čase, technika před rychlostí.\(note)"
        )
    }

    /// Dlouhý metcon/EMOM v jedné neměnné sadě cviků je mentálně vyčerpávající — nad ~22 min
    /// proto rozdělíme na 2–4 kratší segmenty (~15 min každý) s vlastním výběrem cviků.
    static func buildMetconSegments(
        titlePrefix: String, formatCandidates: [WorkoutFormat], pool: [Exercise], profile: AthleteProfile,
        totalMinutes: Int, baseAvoidPatterns: [MovementPattern], muscleLoad: [String: Int], autoreg: [LoadPurpose: Int],
        exercisesPerSegment: Int = 3
    ) -> [WorkoutBlock] {
        let format = pickMetconFormat(formatCandidates, profile)
        let numSegments = totalMinutes > 22 ? clampInt(Int((Double(totalMinutes) / 15).rounded()), 2, 4) : 1
        let segMinutes = clampInt(Int((Double(totalMinutes) / Double(numSegments) / 5).rounded()) * 5, 8, 20)

        var blocks: [WorkoutBlock] = []
        var cumulativePatterns = baseAvoidPatterns
        var cumulativeIds: [String] = []

        for i in 0..<numSegments {
            var segPool = pool.filter { !cumulativeIds.contains($0.id) }
            if segPool.count < exercisesPerSegment { segPool = pool }
            let picks = pickExercises(segPool, count: exercisesPerSegment, avoidPatterns: cumulativePatterns, muscleLoad: muscleLoad)
            let label = numSegments > 1 ? "\(titlePrefix) · \(i + 1)/\(numSegments)" : titlePrefix
            var block = buildMetconBlock(title: label, format: format, picks: picks, profile: profile, minutes: segMinutes, autoreg: autoreg)
            if numSegments > 1 { block.notes += " Krátký odpočinek (2–3 min) a nová sada cviků na jiné partie." }
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

    // MARK: Veřejné API

    static func generateWorkout(profile: AthleteProfile, dateString: String, history: [Workout]) -> Workout {
        let dayIdx = DateUtils.weekdayIndex(dateString)
        let dayType = dayIdx < profile.weeklyTemplate.count ? profile.weeklyTemplate[dayIdx] : .rest

        if dayType == .rest {
            return Workout(
                date: dateString, dayType: .rest, dayTypeLabel: DayType.rest.label,
                blocks: [WorkoutBlock(
                    title: "Odpočinek", format: .rest, formatLabel: WorkoutFormat.rest.label,
                    durationMin: 20, timeCap: nil, scheme: "Mobilita / regenerace", exercises: [],
                    notes: "Lehké strečování, mobilita kyčlí a ramen, procházka. Žádná intenzivní zátěž."
                )],
                estKcal: 60, generatedAt: Date(), edited: false, rpe: nil
            )
        }

        let autoreg = computeAutoreg(history, profile)
        let blocks: [WorkoutBlock]
        switch dayType {
        case .strength: blocks = buildStrengthDay(profile, dateString, history, autoreg)
        case .gymnastics: blocks = buildGymnasticsDay(profile, dateString, history, autoreg)
        case .monostructural: blocks = buildMonostructuralDay(profile)
        case .chipper: blocks = buildChipperDay(profile, dateString, history, autoreg)
        case .rest: blocks = [] // nedosažitelné, ošetřeno výše
        }

        return Workout(
            date: dateString, dayType: dayType, dayTypeLabel: dayType.label, blocks: blocks,
            estKcal: estimateCalories(blocks, bodyweight: profile.bodyweight),
            generatedAt: Date(), edited: false, rpe: nil
        )
    }

    static func formatWeight(_ w: Double) -> String {
        w == w.rounded() ? String(Int(w)) : String(format: "%.1f", w)
    }
}
