import SwiftUI

// MARK: - Barvy podle typu dne (zachováno — slouží k rychlému rozlišení typu dne
// v historii/hero kartě, redesign mění jen zbytek palety)

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

// MARK: - Karta

struct CardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(18)
            .background(DT.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(DT.line, lineWidth: 1)
            )
    }
}

extension View {
    func cardStyle() -> some View { modifier(CardBackground()) }
}

// MARK: - Řádek smazatelný potažením doleva

/// Obalí libovolný obsah (typicky kartu) tak, aby šel potažením doleva odhalit
/// červené tlačítko smazání — vlastní implementace, appka nepoužívá List,
/// takže nativní `.swipeActions` není k dispozici.
struct SwipeToDeleteRow<Content: View>: View {
    let onDelete: () -> Void
    @ViewBuilder var content: () -> Content

    @State private var offsetX: CGFloat = 0
    @State private var isOpen = false
    private let actionWidth: CGFloat = 76

    var body: some View {
        ZStack(alignment: .trailing) {
            Button(role: .destructive, action: onDelete) {
                VStack(spacing: 4) {
                    Image(systemName: "trash")
                        .font(.system(size: 17, weight: .semibold))
                    Text("Smazat")
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(width: actionWidth)
                .frame(maxHeight: .infinity)
            }
            .buttonStyle(.plain)
            .background(DT.danger)

            content()
                .cardStyle()
                .offset(x: offsetX)
                .gesture(
                    DragGesture(minimumDistance: 16)
                        .onChanged { value in
                            let translation = value.translation.width
                            let base: CGFloat = isOpen ? -actionWidth : 0
                            guard translation < 0 || isOpen else { return }
                            offsetX = min(0, max(base + translation, -actionWidth))
                        }
                        .onEnded { value in
                            let shouldOpen = offsetX < -actionWidth / 2
                            withAnimation(.easeOut(duration: 0.2)) {
                                offsetX = shouldOpen ? -actionWidth : 0
                            }
                            isOpen = shouldOpen
                        }
                )
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// MARK: - Badge (pilulka)
//
// Výchozí (plná) varianta = akcentní výplň + tmavý text, stejně v obou režimech.
// `outline` = tichá varianta na `surfaceRaised` pro sekundární/day-type badge, kde
// barva nese vlastní význam (`DayType.color`) a nemá smysl ji přebíjet akcentem.

struct BadgeView: View {
    let text: String
    var color: Color = DT.accent
    var outline: Bool = false

    var body: some View {
        Text(text)
            .trackedUppercase(0.3)
            .font(.system(size: 11, weight: .heavy))
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(outline ? DT.surfaceRaised : color)
            .foregroundColor(outline ? DT.fgMuted : DT.accentInk)
            .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .stroke(outline ? DT.line : .clear, lineWidth: 1)
            )
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
                        .font(.system(size: 13, weight: .bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 2)
                        .padding(.vertical, 8)
                        .background(selection == opt.value ? DT.surfaceRaised : Color.clear)
                        .foregroundColor(selection == opt.value ? DT.fg : DT.fgMuted)
                        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(DT.surface)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(DT.line, lineWidth: 1))
    }
}

// MARK: - Chip (multi-select)

struct ChipButton: View {
    let label: String
    let isActive: Bool
    var danger: Bool = false
    /// Užší odsazení a menší písmo pro řádky, kde se vejde víc chipů najednou
    /// (např. délka tréninku) — ostatní místa v appce zůstávají beze změny.
    var compact: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: compact ? 12 : 13, weight: .bold))
                .padding(.horizontal, compact ? 10 : 14)
                .padding(.vertical, compact ? 6 : 8)
                .background(backgroundColor)
                .foregroundColor(foregroundColor)
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .stroke(danger && isActive ? DT.danger : .clear, lineWidth: 1.5)
                )
        }
        .buttonStyle(.plain)
    }

    private var backgroundColor: Color {
        if danger { return isActive ? DT.danger.opacity(0.16) : DT.surface }
        return isActive ? DT.accent : DT.surface
    }
    private var foregroundColor: Color {
        if danger { return isActive ? DT.danger : DT.fgMuted }
        return isActive ? DT.accentInk : DT.fgMuted
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

// MARK: - Tlačítka

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .heavy))
            .trackedUppercase(0.2)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(DT.accent.opacity(configuration.isPressed ? 0.75 : 1))
            .foregroundColor(DT.accentInk)
            .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .heavy))
            .trackedUppercase(0.2)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(DT.surface.opacity(configuration.isPressed ? 0.7 : 1))
            .foregroundColor(DT.fg)
            .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 11, style: .continuous).stroke(DT.line, lineWidth: 1))
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var dtPrimary: PrimaryButtonStyle { PrimaryButtonStyle() }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    static var dtSecondary: SecondaryButtonStyle { SecondaryButtonStyle() }
}

struct DestructiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .heavy))
            .trackedUppercase(0.2)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(DT.danger.opacity(configuration.isPressed ? 0.12 : 0.16))
            .foregroundColor(DT.danger)
            .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
    }
}

extension ButtonStyle where Self == DestructiveButtonStyle {
    static var dtDestructive: DestructiveButtonStyle { DestructiveButtonStyle() }
}

// MARK: - Toast

struct ToastView: View {
    let message: String
    var body: some View {
        Text(message)
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(Color.black.opacity(0.9))
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.3), radius: 12, y: 4)
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
                .foregroundColor(DT.fgMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 50)
    }
}
