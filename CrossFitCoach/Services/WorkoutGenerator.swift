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
        core = SkillProgression.restrictToCurrentStep(core, history: history, today: dateString, overrides: profile.skillOverrides ?? [:])
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

    /// `coveragePriority`: povinné svalové skupiny (viz `MuscleCoverage`), které
    /// tento týden ještě nebyly zasažené — pokud mezi kandidáty existuje aspoň
    /// jeden, co některou z nich zasahuje, výběr se na ně zúží ještě PŘED
    /// vyvažováním zátěže. Prázdná množina (default) = bez vlivu.
    ///
    /// Tolerance okolo minima (ne tvrdá přesná shoda) řeší reálně nahlášený bug:
    /// s přesnou shodou minima se "nejméně zatížená" množina kandidátů často
    /// zhroutila na jediný prvek (svalová zátěž se mezi stisky "přegenerovat"
    /// nijak nemění, protože vychází jen z historie, ne ze seedu) — výsledek byl
    /// naprosto deterministický výběr i s čerstvým náhodným seedem, takže
    /// "Přegenerovat" u některých cviků (typicky v metcon/EMOM blocích se
    /// zúženým poolem) viditelně nic neměnilo. Tolerance udrží víc kandidátů v
    /// užší množině, takže i "přegenerovat" se stejnou historií reálně zamíchá.
    static func leastLoadedPick(_ candidates: [Exercise], _ muscleLoad: [String: Int]?, coveragePriority: Set<MuscleGroup> = [], using rng: inout SeededGenerator) -> Exercise? {
        guard !candidates.isEmpty else { return nil }
        var pool = candidates
        if !coveragePriority.isEmpty {
            let covering = candidates.filter { !MuscleCoverage.groups(for: $0).isDisjoint(with: coveragePriority) }
            if !covering.isEmpty { pool = covering }
        }
        guard let muscleLoad, !muscleLoad.isEmpty else { return pool.randomElement(using: &rng) }
        let scored = pool.map { ($0, muscleOverlapScore($0, muscleLoad)) }
        let minScore = scored.map(\.1).min() ?? 0
        let maxScore = scored.map(\.1).max() ?? minScore
        let tolerance = max(1, (maxScore - minScore) / 3)
        let best = scored.filter { $0.1 <= minScore + tolerance }.map(\.0)
        return best.randomElement(using: &rng)
    }

    static func pickExercises(_ pool: [Exercise], count: Int, avoidPatterns: [MovementPattern], muscleLoad: [String: Int]?, coveragePriority: Set<MuscleGroup> = [], using rng: inout SeededGenerator) -> [Exercise] {
        var usedPatterns = Set<MovementPattern>()
        var usedIds = Set<String>()
        var result: [Exercise] = []

        for _ in 0..<count {
            var filtered = pool.filter { !usedIds.contains($0.id) && !usedPatterns.contains($0.pattern) && !avoidPatterns.contains($0.pattern) }
            if filtered.isEmpty { filtered = pool.filter { !usedIds.contains($0.id) && !usedPatterns.contains($0.pattern) } }
            if filtered.isEmpty { filtered = pool.filter { !usedIds.contains($0.id) } }
            if filtered.isEmpty { break }
            guard let pick = leastLoadedPick(filtered, muscleLoad, coveragePriority: coveragePriority, using: &rng) else { break }
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

    /// %1RM podle plánovaného počtu opakování v sérii — ne tvrdé "1× maximum při
    /// X opakováních" (to by bylo RM, ne opakovatelná pracovní série), ale
    /// obvyklá praxe při více pracovních sériích: NSCA load-rep tabulka řadí
    /// ~87 % k 5RM a ~90 % ke 4RM, Prilepinova tabulka doporučuje pro 2–4
    /// opakování v sérii pásmo 80–90 %. Několik sérií za sebou proto jde o
    /// kousek níž, než by šlo jedno maximální opakování na daný počet. Rozšířeno
    /// i o 2/6/7-8 opakování pro rotující schémata (viz `strengthSetsScheme`) —
    /// stupnice dál klesá se stoupajícím objemem na sérii.
    private static func strengthPercent(forReps reps: Int?) -> Double {
        guard let reps else { return 0.80 }
        switch reps {
        case ...2: return 0.90
        case 3: return 0.88
        case 4: return 0.83
        case 5: return 0.76
        case 6: return 0.73
        default: return 0.68 // 7-8+ opakování v sérii
        }
    }

    /// `deload`: jednou za měsíc (viz `isDeloadWeek`) jde zátěž výrazně dolů bez
    /// ohledu na rep scheme/RPE historii — autoreg se v deload týdnu ignoruje
    /// (adj = 0), protože celý smysl deloadu je zaručeně odlehčit, ne nechat
    /// nedávné RPE tu redukci přebít zpátky nahoru. `.technique` zátěž se
    /// neodlehčuje dál — je už dost nízká (20–40 %) sama o sobě.
    static func computeLoad(_ exercise: Exercise, _ profile: AthleteProfile, purpose: LoadPurpose, autoreg: [LoadPurpose: Int], repsPerSet: Int? = nil, deload: Bool = false) -> LoadResult? {
        guard exercise.loadable else { return nil }
        var pct: Double
        switch purpose {
        case .strength: pct = deload ? 0.6 : strengthPercent(forReps: repsPerSet)
        case .metcon: pct = deload ? 0.4 : 0.5
        case .technique: pct = 0.3
        }

        let adj = deload ? 0 : (autoreg[purpose] ?? 0)
        pct += Double(adj) / 100
        let bounds: (Double, Double) = {
            switch purpose {
            case .strength: return deload ? (0.5, 0.65) : (0.65, 0.95)
            case .metcon: return deload ? (0.3, 0.45) : (0.35, 0.65)
            case .technique: return (0.2, 0.4)
            }
        }()
        pct = max(bounds.0, min(bounds.1, pct))

        let step: Double = exercise.equipment.contains(.barbell) ? 2.5 : 1

        if let key = exercise.oneRMKey, let oneRM = profile.oneRM[key] {
            let weight = roundToStep(oneRM * exercise.variantMultiplier * pct, step)
            let liftLabel = OneRepMaxes.liftLabels.first(where: { $0.key == key })?.label ?? key
            // Zobrazené "% 1RM" musí sedět na zobrazenou váhu (uživatel: "bent
            // over row 55 % deadlift 1RM není 55 kg z 200 kg"). U odvozeného
            // cviku (variantMultiplier != 1, např. bent-over-row ~50 % deadliftu)
            // se váha počítá JEŠTĚ přes tenhle multiplikátor navrch `pct` — bez
            // něj v popisku by "55 %" neodpovídalo skutečné váze, jen cílovému
            // pct před přepočtem na variantu.
            let effectivePct = Int((pct * exercise.variantMultiplier * 100).rounded())
            return LoadResult(weight: weight, unit: "kg", source: "\(liftLabel) 1RM", pct: effectivePct, autoregAdj: adj)
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
            if deload, purpose != .technique { weight *= 0.65 }
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

    static func toWorkoutExercise(_ exercise: Exercise, _ profile: AthleteProfile, purpose: LoadPurpose, reps: String, note: String, autoreg: [LoadPurpose: Int], repsPerSet: Int? = nil, deload: Bool = false) -> WorkoutExercise {
        let load = computeLoad(exercise, profile, purpose: purpose, autoreg: autoreg, repsPerSet: repsPerSet, deload: deload)
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

    /// Kolikátý je tenhle silový den v uložené historii (0-based) — používá se
    /// k CYKLICKÉMU prostřídání rep schémat (viz `strengthSetsScheme`), ne k
    /// náhodě. Nahlášený bug: schéma bylo čistě funkcí úrovně, takže advanced
    /// atlet viděl "5 × 3" se stejnou váhou doslova navždy, bez jakékoli
    /// periodizace. Počítá se jen z DŘÍVE uložených tréninků, takže
    /// "přegenerovat" ve stejném dni schéma nerozhodí (shoda s tím, že
    /// `strengthSetsScheme` beztak s `rng` nepracuje).
    static func strengthSessionVariantIndex(_ history: [Workout]) -> Int {
        history.filter { $0.dayType == .strength }.count % 3
    }

    /// Tři rotující varianty objemu/intenzity na úroveň namísto jednoho fixního
    /// schématu navždy: těžší/nižší objem → střední → vyšší objem/lehčí, pak
    /// znovu od začátku. `variant` typicky přichází z `strengthSessionVariantIndex`.
    static func strengthSetsScheme(_ level: AthleteLevel, _ variant: Int = 0, _ language: AppLanguage = .cs) -> (sets: Int, reps: Int, label: String) {
        let variants: [(sets: Int, reps: Int)]
        switch level {
        case .beginner: variants = [(3, 5), (3, 8), (4, 6)]
        case .intermediate: variants = [(4, 4), (3, 6), (5, 3)]
        case .advanced, .rx: variants = [(5, 3), (4, 5), (3, 2)]
        }
        let idx = ((variant % variants.count) + variants.count) % variants.count
        let (sets, reps) = variants[idx]
        if language == .en {
            return (sets, reps, "\(sets) sets × \(reps) reps")
        }
        let setsWord = sets >= 5 ? "sérií" : "série"
        return (sets, reps, "\(sets) \(setsWord) × \(reps) opakování")
    }

    /// Jednou za kalendářní měsíc (poslední týden měsíce) jde celý trénink
    /// výrazně dolů v objemu i intenzitě — deload, co by měl mít v sobě
    /// každý rozumný tréninkový plán, ať tělo pravidelně dostane prostor na
    /// zotavení a dlouhodobě neroste riziko přetrénování/zranění. Počítá se
    /// čistě z kalendářního data (ne z historie) — je tak predikovatelné a
    /// nezávisí na tom, kolik se toho ten měsíc reálně natrénovalo.
    static func isDeloadWeek(_ dateString: String) -> Bool {
        let date = DateUtils.date(from: dateString)
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        guard let day = cal.dateComponents([.day], from: date).day,
              let range = cal.range(of: .day, in: .month, for: date) else { return false }
        return day > range.count - 7
    }

    /// Fixní nízkoobjemové schéma pro deload — NE jedna z běžných rotujících
    /// variant (viz `strengthSetsScheme`), aby deload byl vždy jasně odlišený
    /// od běžného tréninku, i kdyby zrovna vyšla "lehčí" rotace.
    static func deloadStrengthScheme(_ language: AppLanguage = .cs) -> (sets: Int, reps: Int, label: String) {
        language == .en ? (3, 8, "3 sets × 8 reps (deload)") : (3, 8, "3 série × 8 opakování (deload)")
    }

    // MARK: Stavba jednotlivých typů dne

    static func buildStrengthDay(_ profile: AthleteProfile, _ dateString: String, _ history: [Workout], _ autoreg: [LoadPurpose: Int], _ language: AppLanguage = .cs, deload: Bool = false, using rng: inout SeededGenerator) -> [WorkoutBlock] {
        let avoid = recoveryAvoidPatterns(history, dateString)
        let muscleLoad = recentMuscleLoad(history, dateString, daysBack: 7)
        let pool = filterPool(profile, categories: [.weightlifting], history: history, dateString: dateString, using: &rng).filter { [.squat, .hinge, .push, .olympic].contains($0.pattern) }
        let mainCandidates = pool.filter { !avoid.contains($0.pattern) }
        let mainPool = mainCandidates.isEmpty ? pool : mainCandidates
        // Povinné svalové partie (nohy/záda/hrudník/ramena), co tenhle týden ještě
        // nebyly zasažené — viz MuscleCoverage. Hlavní zvedaný cvik je nejsilnější
        // páka, jak je napravit (deadlift/dobré ráno zasáhne záda, bench/push
        // press hrudník+ramena, dřepy nohy), takže dostane prioritu před čistým
        // vyvažováním nedávné zátěže.
        var missing = MuscleCoverage.missingMandatory(history, dateString: dateString)
        let main = leastLoadedPick(mainPool, muscleLoad, coveragePriority: missing, using: &rng)

        let total = profile.timeAvailable
        let strengthMin = clampInt(Int((Double(total) * 0.4 / 5).rounded()) * 5, 12, 40)
        var blocks: [WorkoutBlock] = []
        var usedPatterns: [MovementPattern] = []
        let scheme = deload ? deloadStrengthScheme(language) : strengthSetsScheme(profile.level, strengthSessionVariantIndex(history), language)
        var letterIndex = 0
        let letters = ["A", "B", "C", "D"]
        func nextLetter() -> String { let l = letters[min(letterIndex, letters.count - 1)]; letterIndex += 1; return l }

        if let main {
            missing.subtract(MuscleCoverage.groups(for: main))
            let wEx = toWorkoutExercise(main, profile, purpose: .strength, reps: "\(scheme.sets) × \(scheme.reps)", note: scheme.label, autoreg: autoreg, repsPerSet: scheme.reps, deload: deload)
            usedPatterns.append(main.pattern)
            let weightLabel = wEx.weight != nil ? "\(formatWeight(wEx.weight!)) kg" : (language == .en ? "per standard" : "dle standardu")
            let letter = nextLetter()
            blocks.append(WorkoutBlock(
                title: language == .en ? "Block \(letter) · Strength" : "Blok \(letter) · Síla", format: .strength, formatLabel: WorkoutFormat.strength.label(language),
                durationMin: strengthMin, timeCap: nil, scheme: scheme.label, exercises: [wEx],
                notes: (deload
                    ? (language == .en ? "Deload week — stay well under max effort, this is about recovery, not a new PR." : "Deload týden — zůstaň hodně pod maximem, jde o regeneraci, ne o nový rekord.")
                    : (language == .en
                        ? "Gradually build up to your working weight (\(weightLabel)), 2–3 min rest between sets."
                        : "Postupné navyšování na pracovní váhu (\(weightLabel)), 2–3 min odpočinek mezi sériemi.")) + autoregNote(autoreg, .strength, language)
            ))
        }

        // S cílem "Síla" (profile.goal) jde delší trénink přednostně do DALŠÍCH
        // zvedaných cviků, ne jen do metconu — uživatel: "sílu bych dal třeba
        // dřep a mrtvoly + bicep a třeba jeden emom na konec". `profile.goal`
        // předtím generátor vůbec nečetl, takže volba cíle v profilu neměla na
        // skladbu tréninku žádný vliv — delší trénink byl vždycky jen "víc
        // metconu" bez ohledu na to, co si uživatel zvolil. V deload týdnu se
        // tahle přístavba vždy vynechává — deload je o odpočinku, ne o přidávání
        // dalšího objemu.
        let buildingFocus = profile.goal == .strength && !deload
        var remaining = max(0, total - (main != nil ? strengthMin : 0))

        if buildingFocus, let main, remaining >= 18 {
            // Druhý zvedaný cvik: NE jiný "pattern" (bench press + shoulder press
            // jsou oba .push, a přesně tohle je uživatelův příklad — "bench press,
            // přidej něco na ramena"), ale jiné `oneRMKey` (jiná kotva/maximum) —
            // to spolehlivě vyloučí jen skutečně redundantní dvojice (squat +
            // overhead squat, oba na backSquat) a necha projít doplňkové páry na
            // podobnou partii, co uživatel chce (squat+deadlift, bench+press).
            let secondMin = clampInt(Int((Double(remaining) * 0.4 / 5).rounded()) * 5, 10, 25)
            let secondPool = mainPool.filter { $0.id != main.id && $0.oneRMKey != main.oneRMKey }
            if let second = leastLoadedPick(secondPool, muscleLoad, coveragePriority: missing, using: &rng) {
                missing.subtract(MuscleCoverage.groups(for: second))
                usedPatterns.append(second.pattern)
                remaining -= secondMin
                let wEx2 = toWorkoutExercise(second, profile, purpose: .strength, reps: "\(scheme.sets) × \(scheme.reps)", note: scheme.label, autoreg: autoreg, repsPerSet: scheme.reps)
                let letter = nextLetter()
                blocks.append(WorkoutBlock(
                    title: language == .en ? "Block \(letter) · Strength" : "Blok \(letter) · Síla", format: .strength, formatLabel: WorkoutFormat.strength.label(language),
                    durationMin: secondMin, timeCap: nil, scheme: scheme.label, exercises: [wEx2],
                    notes: (language == .en
                        ? "Second compound lift to round out today's strength work, same working weight logic as above."
                        : "Druhý zvedaný cvik pro doplnění dnešní silové části, stejná logika pracovní váhy jako výše.") + autoregNote(autoreg, .strength, language)
                ))
            }
        }

        if buildingFocus, remaining >= 15 {
            // Třetí, doplňkový (isolation) cvik na konkrétní svalovou skupinu
            // (biceps/triceps/ramena) — uživatel: "... + bicep". Samostatný pool
            // (MovementPattern.isolation), ne hlavní squat/hinge/push/olympic.
            let accessoryMin = clampInt(Int((Double(remaining) * 0.4 / 5).rounded()) * 5, 8, 15)
            let accessoryPool = filterPool(profile, categories: [.weightlifting], history: history, dateString: dateString, using: &rng)
                .filter { $0.pattern == .isolation }
            if let accessory = leastLoadedPick(accessoryPool, muscleLoad, coveragePriority: missing, using: &rng) {
                missing.subtract(MuscleCoverage.groups(for: accessory))
                usedPatterns.append(accessory.pattern)
                remaining -= accessoryMin
                let accessoryReps = "3 × 10–12"
                let wEx3 = toWorkoutExercise(accessory, profile, purpose: .strength, reps: accessoryReps, note: language == .en ? "Accessory" : "Doplňkový cvik", autoreg: autoreg, repsPerSet: 10)
                let letter = nextLetter()
                blocks.append(WorkoutBlock(
                    title: language == .en ? "Block \(letter) · Accessory" : "Blok \(letter) · Doplňkový cvik", format: .strength, formatLabel: WorkoutFormat.strength.label(language),
                    durationMin: accessoryMin, timeCap: nil, scheme: accessoryReps, exercises: [wEx3],
                    notes: language == .en
                        ? "Lighter isolation work — controlled tempo, not a max-effort lift."
                        : "Lehčí izolovaný cvik — kontrolované tempo, ne cvik na maximum."
                ))
            }
        }

        let metconPool = filterPool(profile, categories: [.gymnastics, .monostructural, .strongman, .weightlifting], excludeStandaloneCardio: true, history: history, dateString: dateString, using: &rng)
            .filter { !usedPatterns.contains($0.pattern) || $0.category == .monostructural }
        if buildingFocus {
            // "jeden emom na zpocení"/"jeden emom na konec" — s cílem Síla je
            // finišer VŽDY jeden jediný EMOM blok, ne segmentovaný AMRAP/ForTime
            // přes buildMetconSegments (to by mohlo vyrobit 2–4 bloky a jiný
            // formát). Krátký a jednoduchý, ne hlavní náplň tréninku.
            let emomMinutes = clampInt(remaining, 8, 30)
            let picks = pickExercises(metconPool, count: 3, avoidPatterns: usedPatterns + Array(avoid), muscleLoad: muscleLoad, coveragePriority: missing, using: &rng)
            if !picks.isEmpty {
                let letter = nextLetter()
                blocks.append(buildMetconBlock(
                    title: language == .en ? "Block \(letter) · EMOM" : "Blok \(letter) · EMOM",
                    format: .emom, picks: picks, profile: profile, minutes: emomMinutes, autoreg: autoreg, language: language
                ))
            }
        } else {
            let metconMinutes = clampInt(deload ? Int(Double(remaining) * 0.6) : remaining, 8, 60)
            let letter = nextLetter()
            blocks.append(contentsOf: buildMetconSegments(
                titlePrefix: language == .en ? "Block \(letter) · Metcon" : "Blok \(letter) · Metcon", formatCandidates: [.amrap, .emom, .forTime], pool: metconPool,
                profile: profile, totalMinutes: metconMinutes, baseAvoidPatterns: usedPatterns + Array(avoid), muscleLoad: muscleLoad, autoreg: autoreg,
                coveragePriority: missing, deload: deload, language: language, using: &rng
            ))
        }
        return blocks
    }

    static func buildGymnasticsDay(_ profile: AthleteProfile, _ dateString: String, _ history: [Workout], _ autoreg: [LoadPurpose: Int], _ language: AppLanguage = .cs, deload: Bool = false, using rng: inout SeededGenerator) -> [WorkoutBlock] {
        let avoid = recoveryAvoidPatterns(history, dateString)
        let muscleLoad = recentMuscleLoad(history, dateString, daysBack: 7)
        // Blok A je dedikovaný NÍZKOOBJEMOVÝ technický nácvik ("5 × 3–5 kvalitních
        // opakování") — podle research (NSCA/CrossFit skill-training konvence) tahle
        // prescribce patří jen skutečným technickým dovednostem (pistol, HSPU,
        // muscle-up buildup…), ne výbušným/kondičním pohybům ve stejné `.gymnastics`
        // kategorii (burpee broad jump, box jump…), které nízký objem taky chtějí,
        // ale formou vyššího počtu kol ve WODu (viz EMOM pool níž), ne jako
        // samostatný nácvik. Odtud `isSkillPractice` filtr — s odstupňovaným
        // fallbackem, ať den kvůli vybavení nikdy nezůstane bez kandidáta.
        let allGymnastics = filterPool(profile, categories: [.gymnastics], history: history, dateString: dateString, using: &rng)
        let skillOnly = allGymnastics.filter { $0.isSkillPractice }
        let skillPool = (skillOnly.isEmpty ? allGymnastics : skillOnly).filter { !avoid.contains($0.pattern) }
        let skillCandidates = skillPool.isEmpty ? (skillOnly.isEmpty ? allGymnastics : skillOnly) : skillPool
        // Viz MuscleCoverage/buildStrengthDay — stejná týdenní priorita povinných
        // partií, tady uplatněná na skill pick a následně na EMOM pool.
        var missing = MuscleCoverage.missingMandatory(history, dateString: dateString)
        let skillPick = leastLoadedPick(skillCandidates, muscleLoad, coveragePriority: missing, using: &rng)

        let total = profile.timeAvailable
        let skillMin = clampInt(Int((Double(total) * 0.3 / 5).rounded()) * 5, 8, 25)
        var blocks: [WorkoutBlock] = []
        var usedPatterns: [MovementPattern] = []

        if let skillPick {
            missing.subtract(MuscleCoverage.groups(for: skillPick))
            usedPatterns.append(skillPick.pattern)
            let tier = profile.level.tier
            let info = skillPick.levels.info(for: tier)
            let wEx = toWorkoutExercise(skillPick, profile, purpose: .technique, reps: language == .en ? "5 × 3–5 quality reps" : "5 × 3–5 kvalitních opakování", note: language == .en ? "Technique practice" : "Technický nácvik", autoreg: autoreg, deload: deload)
            blocks.append(WorkoutBlock(
                title: language == .en ? "Block A · Skill" : "Blok A · Skill", format: .strength, formatLabel: language == .en ? "Technique" : "Technika",
                durationMin: skillMin, timeCap: nil, scheme: language == .en ? "5 sets, focus on quality" : "5 sérií, důraz na kvalitu", exercises: [wEx],
                notes: "\(language == .en ? "Criteria to advance" : "Kritérium postupu"): \(info.criteria)"
            ))
        }

        // Stejná logika jako u buildStrengthDay — s cílem "Síla" nebo "Skill" jde
        // delší trénink přednostně do DRUHÉHO technického cviku, ne jen do dalšího
        // EMOMu, ať delší skill den opravdu znamená víc budování dovednosti, ne
        // jen víc kondičního objemu. V deload týdnu se vynechává stejně jako u
        // buildStrengthDay.
        let buildingFocus = (profile.goal == .strength || profile.goal == .skill) && !deload
        let remainingAfterSkill = max(0, total - (skillPick != nil ? skillMin : 0))
        var secondMin = 0
        var secondBlock: WorkoutBlock?
        if buildingFocus, let skillPick, remainingAfterSkill >= 18 {
            secondMin = clampInt(Int((Double(remainingAfterSkill) * 0.5 / 5).rounded()) * 5, 8, 20)
            let secondPool = skillCandidates.filter { $0.pattern != skillPick.pattern && $0.id != skillPick.id }
            if let second = leastLoadedPick(secondPool, muscleLoad, coveragePriority: missing, using: &rng) {
                missing.subtract(MuscleCoverage.groups(for: second))
                usedPatterns.append(second.pattern)
                let tier = profile.level.tier
                let info2 = second.levels.info(for: tier)
                let wEx2 = toWorkoutExercise(second, profile, purpose: .technique, reps: language == .en ? "5 × 3–5 quality reps" : "5 × 3–5 kvalitních opakování", note: language == .en ? "Technique practice" : "Technický nácvik", autoreg: autoreg, deload: deload)
                secondBlock = WorkoutBlock(
                    title: language == .en ? "Block B · Skill" : "Blok B · Skill", format: .strength, formatLabel: language == .en ? "Technique" : "Technika",
                    durationMin: secondMin, timeCap: nil, scheme: language == .en ? "5 sets, focus on quality" : "5 sérií, důraz na kvalitu", exercises: [wEx2],
                    notes: "\(language == .en ? "Criteria to advance" : "Kritérium postupu"): \(info2.criteria)"
                )
            } else {
                secondMin = 0
            }
        }
        if let secondBlock { blocks.append(secondBlock) }

        let emomLetter = secondBlock != nil ? "C" : "B"
        let rawEmomMinutes = total - (skillPick != nil ? skillMin : 0) - secondMin
        let emomMinutes = clampInt(deload ? Int(Double(rawEmomMinutes) * 0.6) : rawEmomMinutes, 8, 65)
        let emomPool = filterPool(profile, categories: [.gymnastics, .monostructural, .weightlifting, .strongman], excludeStandaloneCardio: true, history: history, dateString: dateString, using: &rng)
        blocks.append(contentsOf: buildMetconSegments(
            titlePrefix: language == .en ? "Block \(emomLetter) · EMOM" : "Blok \(emomLetter) · EMOM", formatCandidates: [.emom, .amrap], pool: emomPool,
            profile: profile, totalMinutes: emomMinutes, baseAvoidPatterns: usedPatterns + Array(avoid), muscleLoad: muscleLoad, autoreg: autoreg,
            coveragePriority: missing, deload: deload, language: language, using: &rng
        ))
        return blocks
    }

    static func buildMonostructuralDay(_ profile: AthleteProfile, _ language: AppLanguage = .cs, deload: Bool = false, using rng: inout SeededGenerator) -> [WorkoutBlock] {
        let pool = filterPool(profile, categories: [.monostructural], using: &rng)
        let fullTotal = clampInt(profile.timeAvailable, 12, 90)
        let total = deload ? clampInt(Int(Double(fullTotal) * 0.7), 10, 90) : fullTotal
        guard !pool.isEmpty else {
            return [WorkoutBlock(
                title: "Engine", format: .steady, formatLabel: WorkoutFormat.steady.label(language),
                durationMin: total, timeCap: nil, scheme: language == .en ? "Active recovery" : "Aktivní regenerace", exercises: [],
                notes: language == .en
                    ? "No monostructural equipment available — pick a light walk/easy spin as active recovery."
                    : "Nemáš k dispozici žádné monostrukturální vybavení — zvol volnou chůzi/lehký výklus jako aktivní regeneraci."
            )]
        }
        guard let pick = pool.randomElement(using: &rng) else { return [] }
        if deload {
            // Deload Engine den = vždy jen klidné souvislé tempo, žádný tabata/
            // vysokoobjemový dice-roll — to by šlo přímo proti smyslu deloadu.
            var wEx = toWorkoutExercise(pick, profile, purpose: .metcon, reps: "", note: "", autoreg: [:], deload: true)
            wEx.reps = language == .en ? "\(total) easy minutes, zone 1–2 (deload)" : "\(total) minut v klidném tempu, zóna 1–2 (deload)"
            return [WorkoutBlock(
                title: language == .en ? "Engine · Deload" : "Engine · Deload", format: .steady, formatLabel: WorkoutFormat.steady.label(language),
                durationMin: total, timeCap: nil, scheme: language == .en ? "Easy pace" : "Klidné tempo", exercises: [wEx],
                notes: language == .en
                    ? "Deload week — easy conversational pace only, no intervals."
                    : "Deload týden — jen klidné konverzační tempo, žádné intervaly."
            )]
        }
        let candidateFormats: [WorkoutFormat] = total <= 20 ? [.tabata, .intervals] : [.intervals, .steady]
        let format = pickMetconFormat(candidateFormats, profile, using: &rng)
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

    /// Jeden chipper-styl blok (For Time, sestupné počty, každý cvik jednou) —
    /// vytažené z `buildChipperDay` do samostatné funkce, aby šlo totéž použít
    /// jako JEDEN z více bloků dne (viz "recepty" níže), ne jen jako celý den.
    private static func buildChipperBlock(title: String, picks: [Exercise], profile: AthleteProfile, minutes: Int, autoreg: [LoadPurpose: Int], deload: Bool, language: AppLanguage) -> WorkoutBlock {
        let baseReps = deload ? [30, 25, 20, 18, 15, 12, 10, 8] : [50, 40, 35, 30, 25, 20, 15, 10]
        let exercises = picks.enumerated().map { i, ex in
            toWorkoutExercise(ex, profile, purpose: .metcon, reps: String(i < baseReps.count ? baseReps[i] : 15), note: "", autoreg: autoreg, deload: deload)
        }
        return WorkoutBlock(
            title: title, format: .chipper, formatLabel: WorkoutFormat.chipper.label(language),
            durationMin: minutes, timeCap: "\(minutes) min", scheme: language == .en ? "For Time — go through the exercises in order, once each" : "For Time — projdi cviky v pořadí, jednou každý",
            exercises: exercises, notes: (deload
                ? (language == .en ? "Deload week — lower volume, moderate pace." : "Deload týden — nižší objem, mírné tempo.")
                : (language == .en
                    ? "Long volume workout — pace yourself, don't start too fast."
                    : "Dlouhý objemový trénink — rozlož síly, nezačínej zbytečně rychle.")) + autoregNote(autoreg, .metcon, language)
        )
    }

    /// "Objemový metcon" den (uživatelsky "kalorická crossfitová vypalovačka") —
    /// uživatel výslovně chtěl, aby se tenhle den neskládal pořád ze stejného
    /// jednoho formátu, ale mixoval 2–3 různé: "3 amrapy, nebo emom a amrap,
    /// nebo emom a chipper, nebo amrap a chipper." Recept se losuje (seedem,
    /// takže stejný den = stejný recept, dokud se nepřegeneruje), každý blok
    /// dostane vlastní výběr cviků (bez opakování patternu/cviku z
    /// předchozích bloků toho dne) a zhruba rovný díl času.
    static func buildChipperDay(_ profile: AthleteProfile, _ dateString: String, _ history: [Workout], _ autoreg: [LoadPurpose: Int], _ language: AppLanguage = .cs, deload: Bool = false, using rng: inout SeededGenerator) -> [WorkoutBlock] {
        let avoid = recoveryAvoidPatterns(history, dateString)
        let muscleLoad = recentMuscleLoad(history, dateString, daysBack: 7)
        let pool = filterPool(profile, categories: [.gymnastics, .monostructural, .strongman, .weightlifting], excludeStandaloneCardio: true, history: history, dateString: dateString, using: &rng)
        let missing = MuscleCoverage.missingMandatory(history, dateString: dateString)

        let fullTotal = clampInt(profile.timeAvailable, 15, 90)
        let total = deload ? clampInt(Int(Double(fullTotal) * 0.6), 12, 90) : fullTotal

        let recipes: [[WorkoutFormat]] = [
            [.amrap, .amrap, .amrap],
            [.emom, .amrap],
            [.emom, .chipper],
            [.amrap, .chipper]
        ]
        let recipe = recipes.randomElement(using: &rng) ?? [.amrap, .amrap]
        let letters = ["A", "B", "C", "D"]
        let perBlockMinutes = clampInt(Int((Double(total) / Double(recipe.count) / 5).rounded()) * 5, 10, 30)

        var blocks: [WorkoutBlock] = []
        var cumulativePatterns = Array(avoid)
        var cumulativeIds: [String] = []

        for (i, format) in recipe.enumerated() {
            var segPool = pool.filter { !cumulativeIds.contains($0.id) }
            if segPool.count < 4 { segPool = pool }
            let letter = letters[min(i, letters.count - 1)]
            let label = "\(language == .en ? "Block" : "Blok") \(letter) · \(format.label(language))"

            if format == .chipper {
                let count = clampInt(Int((Double(perBlockMinutes) / 3).rounded()), 4, 8)
                let picks = pickExercises(segPool, count: count, avoidPatterns: cumulativePatterns, muscleLoad: muscleLoad, coveragePriority: missing, using: &rng)
                blocks.append(buildChipperBlock(title: label, picks: picks, profile: profile, minutes: perBlockMinutes, autoreg: autoreg, deload: deload, language: language))
                for p in picks { cumulativePatterns.append(p.pattern); cumulativeIds.append(p.id) }
            } else {
                let picks = pickExercises(segPool, count: 3, avoidPatterns: cumulativePatterns, muscleLoad: muscleLoad, coveragePriority: missing, using: &rng)
                blocks.append(buildMetconBlock(title: label, format: format, picks: picks, profile: profile, minutes: perBlockMinutes, autoreg: autoreg, deload: deload, language: language))
                for p in picks { cumulativePatterns.append(p.pattern); cumulativeIds.append(p.id) }
            }
        }
        return blocks
    }

    /// Počet opakování/kalorií v metconu podle typu cviku, ne jednotně pro
    /// všechny — vážené vícekloubové cviky (weightlifting/strongman: deadlift,
    /// thruster, sandbag carry…) cyklované pod časovým tlakem potřebují citelně
    /// nižší objem na kolo než bezváhová gymnastika, jinak vyjdou nerealisticky
    /// vysoká čísla (např. "10×" nebo "15×" na těžký zvedaný cvik). Monostrukturální
    /// cviky se měří v kaloriích, ne opakováních.
    private static func metconRepsLabel(_ exercise: Exercise, format: WorkoutFormat, language: AppLanguage) -> String {
        let isLoadedLift = exercise.category == .weightlifting || exercise.category == .strongman
        switch format {
        case .emom:
            if exercise.category == .monostructural { return language == .en ? "12–15 cals" : "12–15 kalorií" }
            if exercise.category == .gymnastics { return language == .en ? "8–12 reps" : "8–12 opakování" }
            return language == .en ? "5–6 reps" : "5–6 opakování"
        case .forTime:
            if exercise.category == .monostructural { return language == .en ? "15 cals" : "15 kalorií" }
            if isLoadedLift { return language == .en ? "8–10 reps" : "8–10 opakování" }
            return language == .en ? "15 reps" : "15 opakování"
        default: // .amrap
            if exercise.category == .monostructural { return language == .en ? "12 cals" : "12 kalorií" }
            if isLoadedLift { return language == .en ? "6–8 reps" : "6–8 opakování" }
            return language == .en ? "10 reps" : "10 opakování"
        }
    }

    static func buildMetconBlock(title: String, format: WorkoutFormat, picks: [Exercise], profile: AthleteProfile, minutes: Int, autoreg: [LoadPurpose: Int], deload: Bool = false, language: AppLanguage = .cs) -> WorkoutBlock {
        var exercises = picks.map { toWorkoutExercise($0, profile, purpose: .metcon, reps: "", note: "", autoreg: autoreg, deload: deload) }
        let note = autoregNote(autoreg, .metcon, language)
        let deloadNote = deload ? (language == .en ? " Deload — moderate pace, not max effort." : " Deload — mírné tempo, ne na maximum.") : ""

        if format == .emom {
            for (i, pick) in picks.enumerated() {
                exercises[i].reps = metconRepsLabel(pick, format: .emom, language: language)
                exercises[i].note = language == .en ? "Minute \(i + 1) of every cycle" : "Minuta \(i + 1) z každého cyklu"
            }
            return WorkoutBlock(
                title: title, format: .emom, formatLabel: WorkoutFormat.emom.label(language), durationMin: minutes, timeCap: nil,
                scheme: language == .en ? "EMOM \(minutes) min — rotate \(exercises.count) exercises each minute" : "EMOM \(minutes) min — střídej \(exercises.count) cviky po minutách", exercises: exercises,
                notes: (language == .en
                    ? "Aim to finish the work in the first half of the minute, leaving time to rest."
                    : "Cílem je zvládnout práci vždy v první polovině minuty a mít prostor na odpočinek.") + deloadNote + note
            )
        }
        if format == .forTime {
            for (i, pick) in picks.enumerated() {
                exercises[i].reps = metconRepsLabel(pick, format: .forTime, language: language)
            }
            let cap = "\(minutes) min"
            return WorkoutBlock(
                title: title, format: .forTime, formatLabel: WorkoutFormat.forTime.label(language), durationMin: minutes, timeCap: cap,
                scheme: language == .en ? "3 rounds For Time" : "3 kola For Time", exercises: exercises,
                notes: "\(language == .en ? "Time cap" : "Time cap") \(cap). \(language == .en ? "Note your finish time to track progress." : "Piš si čas dokončení pro sledování progresu.")\(deloadNote)\(note)"
            )
        }
        for (i, pick) in picks.enumerated() {
            exercises[i].reps = metconRepsLabel(pick, format: .amrap, language: language)
        }
        return WorkoutBlock(
            title: title, format: .amrap, formatLabel: WorkoutFormat.amrap.label(language), durationMin: minutes, timeCap: nil,
            scheme: "AMRAP \(minutes) min", exercises: exercises,
            notes: (language == .en
                ? "As many complete rounds as possible in the time, technique before speed."
                : "Co nejvíce kompletních kol v daném čase, technika před rychlostí.") + deloadNote + note
        )
    }

    /// Dlouhý metcon/EMOM v jedné neměnné sadě cviků je mentálně vyčerpávající — nad ~22 min
    /// proto rozdělíme na 2–4 kratší segmenty (~15 min každý) s vlastním výběrem cviků.
    static func buildMetconSegments(
        titlePrefix: String, formatCandidates: [WorkoutFormat], pool: [Exercise], profile: AthleteProfile,
        totalMinutes: Int, baseAvoidPatterns: [MovementPattern], muscleLoad: [String: Int], autoreg: [LoadPurpose: Int],
        exercisesPerSegment: Int = 3, coveragePriority: Set<MuscleGroup> = [], deload: Bool = false, language: AppLanguage = .cs, using rng: inout SeededGenerator
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
            let picks = pickExercises(segPool, count: exercisesPerSegment, avoidPatterns: cumulativePatterns, muscleLoad: muscleLoad, coveragePriority: coveragePriority, using: &rng)
            let label = numSegments > 1 ? "\(titlePrefix) · \(i + 1)/\(numSegments)" : titlePrefix
            var block = buildMetconBlock(title: label, format: format, picks: picks, profile: profile, minutes: segMinutes, autoreg: autoreg, deload: deload, language: language)
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
        let deload = isDeloadWeek(dateString)
        let blocks: [WorkoutBlock]
        switch dayType {
        case .strength: blocks = buildStrengthDay(profile, dateString, history, autoreg, language, deload: deload, using: &rng)
        case .gymnastics: blocks = buildGymnasticsDay(profile, dateString, history, autoreg, language, deload: deload, using: &rng)
        case .monostructural: blocks = buildMonostructuralDay(profile, language, deload: deload, using: &rng)
        case .chipper: blocks = buildChipperDay(profile, dateString, history, autoreg, language, deload: deload, using: &rng)
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
