import SwiftUI

struct TimerSheetView: View {
    let config: TimerConfig
    @StateObject private var engine = TimerEngine()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                Button { engine.muted.toggle() } label: {
                    Image(systemName: engine.muted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text(config.title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                Spacer()
                Button("Zavřít") { engine.destroy(); dismiss() }
                    .font(.system(size: 14, weight: .semibold))
            }

            BadgeView(text: config.formatLabel.uppercased(), color: config.dayType.color)
                .padding(.top, 2)

            Text(engine.phaseText)
                .font(.system(size: 14, weight: .heavy))
                .foregroundColor(phaseColor)
                .textCase(.uppercase)
                .padding(.top, 10)

            Text(engine.displayText)
                .font(.system(size: 72, weight: .heavy, design: .rounded))
                .monospacedDigit()

            if !engine.subText.isEmpty {
                Text(engine.subText)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
            }

            if engine.showRoundCounter {
                HStack(spacing: 18) {
                    Button { engine.decrementRounds() } label: {
                        Image(systemName: "minus.circle.fill").font(.system(size: 28))
                    }
                    Text("\(engine.rounds) kol")
                        .font(.system(size: 17, weight: .bold))
                        .frame(minWidth: 70)
                    Button { engine.incrementRounds() } label: {
                        Image(systemName: "plus.circle.fill").font(.system(size: 28))
                    }
                }
                .foregroundColor(.accentColor)
                .padding(.vertical, 6)
            }

            HStack(spacing: 12) {
                Button { engine.reset() } label: {
                    Text("🔄 Reset")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                }
                .background(Color(.secondarySystemBackground))
                .foregroundColor(.primary)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                Button { engine.toggle() } label: {
                    Text(engine.running ? "⏸ Pauza" : "▶️ Start")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                }
                .background(Color.accentColor)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .font(.system(size: 15, weight: .bold))
            .padding(.top, 6)
        }
        .padding(24)
        .onAppear { engine.configure(config) }
        .onDisappear { engine.destroy() }
        .presentationDetents([.medium, .large])
    }

    private var phaseColor: Color {
        switch engine.phaseKind {
        case .normal: return .accentColor
        case .work: return .orange
        case .rest: return .teal
        case .warn: return .red
        }
    }
}
