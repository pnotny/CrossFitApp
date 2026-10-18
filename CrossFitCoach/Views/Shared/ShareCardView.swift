import SwiftUI

/// Vizuál sdílecí karty (tmavá, výrazný display font) — vykresluje se mimo obrazovku
/// přes ImageRenderer do PNG, stejný koncept jako canvas karta ve webové appce.
struct ShareCardView: View {
    let workout: Workout
    let language: AppLanguage
    private let accent: Color

    init(workout: Workout, language: AppLanguage = .cs) {
        self.workout = workout
        self.language = language
        self.accent = workout.dayType.color
    }

    private var dateLabel: String {
        let date = DateUtils.date(from: workout.date)
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: language == .en ? "en_US" : "cs_CZ")
        formatter.dateFormat = "EEEE d. MMMM"
        return formatter.string(from: date).prefix(1).uppercased() + formatter.string(from: date).dropFirst()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("CROSSFIT COACH")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(accent)

            Text(dateLabel)
                .font(.system(size: 44, weight: .heavy, design: .rounded))
                .foregroundColor(.white)

            Text(workout.dayType.label(language))
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundColor(accent)

            Rectangle().fill(Color.white.opacity(0.15)).frame(height: 1)

            VStack(alignment: .leading, spacing: 22) {
                ForEach(Array(workout.blocks.enumerated()), id: \.offset) { _, block in
                    blockView(block)
                }
            }

            Spacer(minLength: 0)

            Rectangle().fill(Color.white.opacity(0.15)).frame(height: 1)
            HStack {
                Text("🔥 ~\(workout.estKcal) kcal")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
                Text("#crossfit #wod")
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(48)
        .frame(width: 1080, height: 1350, alignment: .topLeading)
        .background(
            LinearGradient(
                colors: [Color(red: 0.043, green: 0.043, blue: 0.063), Color(red: 0.090, green: 0.090, blue: 0.122)],
                startPoint: .top, endPoint: .bottom
            )
        )
    }

    @ViewBuilder
    private func blockView(_ block: WorkoutBlock) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(block.format.label(language).uppercased()) · \(block.title)")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(accent)
            if !block.scheme.isEmpty {
                Text(block.scheme)
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
            }
            ForEach(Array(block.exercises.enumerated()), id: \.offset) { _, ex in
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("•  \(ex.name)")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                        if let w = ex.weight {
                            Text("·  \(WorkoutGenerator.formatWeight(w)) \(ex.unit ?? "kg")")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white.opacity(0.85))
                        }
                    }
                    if !ex.reps.isEmpty {
                        Text(ex.reps)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.5))
                            .padding(.leading, 20)
                    }
                }
            }
        }
    }
}
