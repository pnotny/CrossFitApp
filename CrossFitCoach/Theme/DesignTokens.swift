import SwiftUI
import UIKit

extension Color {
    /// `0xRRGGBB` — menší riziko překlepu než ruční přepočet na 0–1 komponenty.
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

/// Barva, která se přepočítá podle AKTUÁLNÍHO colorSchemu v místě použití (ne podle
/// scope, kde je deklarovaná) — stejné chování jako dynamický UIColor/Asset Catalog.
private func dynamic(light: Color, dark: Color) -> Color {
    Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light) })
}

/// Designové tokeny redesignu — čistá černá/bílá místo systémové šedé, plochý
/// volt-limetkový akcent. `accent` je vždy stejný (plná výplň s tmavým textem
/// funguje v obou režimech); `accentText` se naopak MUSÍ lišit, protože limetka
/// jako text/ikona přímo na pozadí by na bílé měla mizerný kontrast.
enum DT {
    static let bg = dynamic(light: Color(hex: 0xFFFFFF), dark: Color(hex: 0x0A0A0B))
    static let surface = dynamic(light: Color(hex: 0xF1F1EE), dark: Color(hex: 0x17181A))
    static let surfaceRaised = dynamic(light: Color(hex: 0xFFFFFF), dark: Color(hex: 0x1B1C1E))
    static let line = dynamic(light: Color(hex: 0xE2E2DD), dark: Color(hex: 0x2B2C2F))

    static let fg = dynamic(light: Color(hex: 0x121214), dark: Color(hex: 0xF5F5F3))
    static let fgMuted = dynamic(light: Color(hex: 0x68686C), dark: Color(hex: 0x9A9A9C))
    static let fgFaint = dynamic(light: Color(hex: 0x9D9D9A), dark: Color(hex: 0x5C5C5F))

    /// Plná výplň (badge, primární tlačítko, aktivní chip) — vždy s `accentInk` textem.
    static let accent = Color(hex: 0xD7FF3F)
    static let accentInk = Color(hex: 0x141600)
    /// Akcent jako text/ikona přímo na pozadí obrazovky (reps, aktivní záložka, swap ikony).
    static let accentText = dynamic(light: Color(hex: 0x5D7A00), dark: Color(hex: 0xD7FF3F))

    static let barBg = dynamic(light: Color(hex: 0xFFFFFF).opacity(0.82), dark: Color(hex: 0x0A0A0B).opacity(0.82))

    static let danger = dynamic(light: Color(hex: 0xC03A2B), dark: Color(hex: 0xFF6B52))
}

/// Verzálkový, trochu "ozubený" vzhled nadpisů/čísel z konceptu — nejblíž systémovému
/// Archivo Black je SF Pro Rounded v Black/Heavy řezu (žádný bundlovaný font, 0 rizika).
enum DF {
    static func display(_ size: CGFloat, weight: Font.Weight = .heavy) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
    static func label(_ size: CGFloat = 11, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight)
    }
}

extension Text {
    /// Verzálkový štítek s mírným trackingem — pro badge/popisky typu "KCAL", "DNES".
    func trackedUppercase(_ spacing: CGFloat = 0.6) -> Text {
        self.textCase(.uppercase).kerning(spacing)
    }
}
