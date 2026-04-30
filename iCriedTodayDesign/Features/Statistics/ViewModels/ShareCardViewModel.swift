import Foundation
import UIKit

@MainActor
final class ShareCardViewModel: ObservableObject {
    @Published var isGenerating = false
    @Published var generatedCard: UIImage?
    @Published var showingCardSelector = false
    @Published var showingShareSheet = false
    @Published var generationError: String?

    private let dataManager: any StatisticsDataManaging
    private let cardRenderer: CardRendering

    init(dataManager: any StatisticsDataManaging) {
        self.dataManager = dataManager
        self.cardRenderer = CardRenderer()
    }

    init(dataManager: any StatisticsDataManaging, cardRenderer: CardRendering) {
        self.dataManager = dataManager
        self.cardRenderer = cardRenderer
    }

    func presentCardSelector() {
        showingCardSelector = true
    }

    func generateCard(type: InsightType, filter: StatisticsFilter) async {
        showingCardSelector = false
        isGenerating = true
        defer { isGenerating = false }

        guard let summary = dataManager.buildInsightSummary(type: type, filter: filter) else {
            generationError = "Недостаточно данных для этой карточки"
            return
        }

        guard let image = await cardRenderer.renderCard(insight: summary) else {
            generationError = "Не удалось создать карточку"
            return
        }

        generatedCard = image
        showingShareSheet = true
    }

    func dismissShareSheet() {
        showingShareSheet = false
        generatedCard = nil
    }
}
