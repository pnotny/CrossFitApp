import SwiftUI

struct TimerSheetView: View {
    @EnvironmentObject var store: AppStore
    let config: TimerConfig
    @StateObject private var engine = TimerEngine()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                Button { engine.muted.toggle() } label: {
                    Image(systemName: engine.muted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .foregroundColor(DT.fgMuted)
                }
                Spacer()
                Text(config.title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(DT.fgMuted)
                    .lineLimit(1)
                Spacer()
                Button(store.t("close")) { engine.destroy(); dismiss() }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(DT.accentText)
            }

            BadgeView(text: config.formatLabel.uppercased(), color: config.dayType.color)
                .padding(.top, 2)

            Text(engine.phaseText)
                .font(.system(size: 14, weight: .heavy))
                .foregroundColor(phaseColor)
                .textCase(.uppercase)
                .padding(.top, 10)

            Text(engine.displayText)
                .font(DF.display(72))
                .foregroundColor(DT.fg)
                .monospacedDigit()

            if !engine.subText.isEmpty {
                Text(engine.subText)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(DT.fgMuted)
            }

            if engine.showRoundCounter {
                HStack(spacing: 18) {
                    Button { engine.decrementRounds() } label: {
                        Image(systemName: "minus.circle.fill").font(.system(size: 28))
                    }
                    Text("\(engine.rounds) \(store.t("rounds_short"))")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(DT.fg)
                        .frame(minWidth: 70)
                    Button { engine.incrementRounds() } label: {
                        Image(systemName: "plus.circle.fill").font(.system(size: 28))
                    }
                }
                .foregroundColor(DT.accentText)
                .padding(.vertical, 6)
            }

            HStack(spacing: 12) {
                Button { engine.reset() } label: {
                    Text("🔄 \(store.t("reset"))")
                }
                .buttonStyle(.dtSecondary)

                Button { engine.toggle() } label: {
                    Text(engine.running ? "⏸ \(store.t("pause"))" : "▶️ \(store.t("start"))")
                }
                .buttonStyle(.dtPrimary)
            }
            .padding(.top, 6)
        }
        .padding(24)
        .background(DT.bg)
        .onAppear { engine.configure(config, language: store.language) }
        .onDisappear { engine.destroy() }
        .presentationDetents([.medium, .large])
    }

    private var phaseColor: Color {
        switch engine.phaseKind {
        case .normal: return DT.accentText
        case .work: return .orange
        case .rest: return .teal
        case .warn: return .red
        }
    }
}
