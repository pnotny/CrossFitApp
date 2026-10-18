import SwiftUI

/// Vykreslí ShareCardView mimo obrazovku do UIImage (PNG) přes ImageRenderer (iOS 16+).
@MainActor
enum ShareCardRenderer {
    static func render(workout: Workout, language: AppLanguage = .cs) -> UIImage? {
        let view = ShareCardView(workout: workout, language: language)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 1 // frame je už ve finálním rozlišení karty (1080×1350)
        renderer.isOpaque = true
        return renderer.uiImage
    }
}
