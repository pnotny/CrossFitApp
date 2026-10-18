import Foundation
import AudioToolbox
import Combine

/// Zvuková znamení přes systémové tóny iOS (AudioServicesPlaySystemSound) —
/// bezpečnější a spolehlivější než vlastní generátor tónu, žádné bundlované soubory.
enum TimerSound {
    /// Krátké, nevýrazné "tik" — odpočet posledních vteřin.
    nonisolated static func tick() { AudioServicesPlaySystemSound(1103) }
    /// Výraznější "ding" — začátek minuty/kola, přechod práce↔odpočinek.
    nonisolated static func notify() { AudioServicesPlaySystemSound(1057) }
    /// Dokončovací tón — konec bloku / time cap.
    nonisolated static func done() { AudioServicesPlaySystemSound(1005) }
}

enum TimerPhaseKind {
    case normal, work, rest, warn
}

struct TimerConfig {
    var title: String
    var formatLabel: String
    var format: WorkoutFormat
    var dayType: DayType
    var durationMin: Int
    var timeCapLabel: String?
    var exercises: [String]
}

/// Formátově specifický tréninkový timer (port js/timer.js) jako ObservableObject pro SwiftUI.
final class TimerEngine: ObservableObject {
    @Published private(set) var displayText: String = "00:00"
    @Published private(set) var phaseText: String = ""
    @Published private(set) var phaseKind: TimerPhaseKind = .normal
    @Published private(set) var subText: String = ""
    @Published private(set) var running: Bool = false
    @Published var rounds: Int = 0
    @Published var muted: Bool = false
    @Published private(set) var showRoundCounter: Bool = false

    private var config: TimerConfig?
    private var elapsed: Int = 0
    private var timer: Timer?

    func configure(_ config: TimerConfig) {
        self.config = config
        reset()
    }

    func toggle() {
        running ? stop() : start()
    }

    func start() {
        guard !running, config != nil else { return }
        running = true
        let t = Timer(timeInterval: 1, repeats: true) { [weak self] _ in self?.tick() }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    func stop() {
        running = false
        timer?.invalidate()
        timer = nil
    }

    func reset() {
        stop()
        elapsed = 0
        rounds = 0
        render()
    }

    func incrementRounds() { rounds += 1 }
    func decrementRounds() { rounds = max(0, rounds - 1) }

    func destroy() {
        stop()
        config = nil
    }

    private func tick() {
        elapsed += 1
        render()
    }

    private func fmt(_ sec: Int) -> String {
        let s = max(0, sec)
        return String(format: "%02d:%02d", s / 60, s % 60)
    }

    private func parseCapSeconds() -> Int {
        guard let config else { return 600 }
        if let label = config.timeCapLabel {
            let digits = label.filter(\.isNumber)
            if let n = Int(digits), n > 0 { return n * 60 }
        }
        return max(config.durationMin, 1) * 60
    }

    private func play(_ sound: () -> Void) {
        guard !muted else { return }
        sound()
    }

    private func render() {
        guard let config else { return }
        showRoundCounter = (config.format == .amrap)

        switch config.format {
        case .emom:
            let totalSec = max(config.durationMin, 1) * 60
            let minuteIdx = min(elapsed / 60, max(config.durationMin - 1, 0))
            let secIntoMin = elapsed % 60
            let secLeft = elapsed >= totalSec ? 0 : 60 - secIntoMin
            displayText = elapsed >= totalSec ? "00:00" : String(format: "%02d", secLeft)
            phaseText = elapsed >= totalSec ? "✅ Hotovo" : "Minuta \(minuteIdx + 1) / \(config.durationMin)"
            phaseKind = .normal
            subText = config.exercises.isEmpty ? "" : "Na řadě: \(config.exercises[minuteIdx % config.exercises.count])"
            if elapsed >= totalSec {
                if running { play(TimerSound.done); stop() }
            } else if running && secIntoMin == 0 && elapsed > 0 {
                play(TimerSound.notify)
            } else if running && secLeft <= 3 && secLeft > 0 {
                play(TimerSound.tick)
            }

        case .amrap:
            let totalSec = max(config.durationMin, 1) * 60
            let left = totalSec - elapsed
            displayText = fmt(left)
            phaseText = left <= 0 ? "✅ Čas vypršel" : "AMRAP"
            phaseKind = .normal
            subText = "Cíl: \(config.durationMin) min"
            if left <= 0, running { play(TimerSound.done); stop() }

        case .forTime, .chipper:
            let capSec = parseCapSeconds()
            displayText = fmt(elapsed)
            let overCap = elapsed >= capSec
            phaseText = overCap ? "⏰ Time cap" : "FOR TIME"
            phaseKind = overCap ? .warn : .normal
            subText = "Time cap: \(fmt(capSec))"
            if overCap, running { play(TimerSound.done); stop() }

        case .tabata:
            let cycle = 30
            let totalSec = 8 * cycle
            if elapsed >= totalSec {
                displayText = "00:00"
                phaseText = "✅ Hotovo"
                phaseKind = .normal
                subText = "8/8 kol"
                if running { play(TimerSound.done); stop() }
                return
            }
            let round = elapsed / cycle + 1
            let posInCycle = elapsed % cycle
            let isWork = posInCycle < 20
            let left = isWork ? 20 - posInCycle : 30 - posInCycle
            displayText = String(format: "%02d", left)
            phaseText = isWork ? "🔥 PRÁCE" : "😮\u{200D}💨 ODPOČINEK"
            phaseKind = isWork ? .work : .rest
            subText = "Kolo \(round) / 8"
            if running && left == 1 { play(TimerSound.notify) }

        default:
            let targetSec = config.durationMin * 60
            displayText = fmt(elapsed)
            phaseText = config.format == .rest ? "ODPOČINEK" : "STOPKY"
            phaseKind = .normal
            subText = targetSec > 0 ? "Cíl: \(fmt(targetSec))" : ""
            if targetSec > 0 && elapsed == targetSec && running { play(TimerSound.notify) }
        }
    }
}
