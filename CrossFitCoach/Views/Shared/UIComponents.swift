import SwiftUI

// MARK: - Barvy podle typu dne (shodné s webovou appkou)

extension DayType {
    var color: Color {
        switch self {
        case .strength: return Color(red: 1.0, green: 0.584, blue: 0)      // orange
        case .gymnastics: return Color(red: 0.369, green: 0.361, blue: 0.902) // indigo
        case .monostructural: return Color(red: 0.188, green: 0.690, blue: 0.780) // teal
        case .chipper: return Color(red: 1.0, green: 0.231, blue: 0.188)   // red
        case .rest: return Color(red: 0.204, green: 0.780, blue: 0.349)    // green
        }
    }
}

// MARK: - Karta (odpovídá .card v style.css)

struct CardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(18)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color(.separator).opacity(0.25), lineWidth: 1)
            )
    }
}

extension View {
    func cardStyle() -> some View { modifier(CardBackground()) }
}

// MARK: - Badge (pilulka)

struct BadgeView: View {
    let text: String
    var color: Color = .accentColor
    var outline: Bool = false

    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .bold))
            .lineLimit(1)
            .padding(.horizontal, 11)
            .padding(.vertical, 5)
            .background(outline ? Color(.tertiarySystemBackground) : color)
            .foregroundColor(outline ? .primary : .white)
            .clipShape(Capsule())
    }
}

// MARK: - Segmentovaný picker (1 z N)

struct SegmentedPicker<T: Hashable>: View {
    let options: [(value: T, label: String)]
    @Binding var selection: T

    var body: some View {
        HStack(spacing: 3) {
            ForEach(options, id: \.value) { opt in
                Button {
                    selection = opt.value
                } label: {
                    Text(opt.label)
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 2)
                        .padding(.vertical, 8)
                        .background(selection == opt.value ? Color(.systemBackground) : Color.clear)
                        .foregroundColor(selection == opt.value ? .primary : .secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
    }
}

// MARK: - Chip (multi-select)

struct ChipButton: View {
    let label: String
    let isActive: Bool
    var danger: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(backgroundColor)
                .foregroundColor(foregroundColor)
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(isActive ? (danger ? Color.red : Color.accentColor) : .clear, lineWidth: 1.5)
                )
        }
        .buttonStyle(.plain)
    }

    private var backgroundColor: Color {
        isActive ? (danger ? Color.red.opacity(0.14) : Color.accentColor.opacity(0.14)) : Color(.secondarySystemBackground)
    }
    private var foregroundColor: Color {
        isActive ? (danger ? .red : .accentColor) : .secondary
    }
}

/// Jednoduchá "wrap" mřížka pro skupiny chipů — bez custom Layout protokolu, nižší riziko.
struct ChipGrid<Content: View>: View {
    @ViewBuilder let content: Content
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 8)], alignment: .leading, spacing: 8) {
            content
        }
    }
}

// MARK: - Toast

struct ToastView: View {
    let message: String
    var body: some View {
        Text(message)
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(Color.black.opacity(0.88))
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.25), radius: 12, y: 4)
            .padding(.horizontal, 40)
    }
}

// MARK: - Prázdný stav

struct EmptyStateView: View {
    let icon: String
    let text: String
    var body: some View {
        VStack(spacing: 10) {
            Text(icon).font(.system(size: 40))
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 50)
    }
}
