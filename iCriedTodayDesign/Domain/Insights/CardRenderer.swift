import SwiftUI
import UIKit

protocol CardRendering {
    func renderCard(insight: InsightSummary) async -> UIImage?
}

@MainActor
final class CardRenderer: CardRendering {
    func renderCard(insight: InsightSummary) async -> UIImage? {
        let view = InsightCard(insight: insight)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 2.0
        renderer.proposedSize = ProposedViewSize(width: 300, height: 375)

        guard let image = renderer.uiImage else { return nil }
        if let data = image.jpegData(compressionQuality: 0.82), data.count < 2_000_000 {
            return UIImage(data: data)
        }
        return image
    }
}
