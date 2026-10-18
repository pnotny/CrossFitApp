import SwiftUI

/// Vykreslí ShareCardView mimo obrazovku do UIImage (PNG) přes ImageRenderer (iOS 16+).
@MainActor
enum ShareCardRenderer {
    static func render(workout: Workout) -> UIImage? {
        let view = ShareCardView(workout: workout)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 1 // frame je už ve finálním rozlišení karty (1080×1350)
        renderer.isOpaque = true
        return renderer.uiImage
    }
}
