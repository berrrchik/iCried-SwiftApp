import Foundation
import SwiftData

@MainActor
final class EmojiRepository: EmojiRepositoryProtocol {
    private static let defaultEmojiScale: [(emoji: String, opacity: Double)] = [
        ("🥲", 0.4),
        ("😢", 0.7),
        ("😭", 1.0)
    ]

    private let modelContext: ModelContext
    private(set) var emojiIntensities: [EmojiIntensity] = []
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        reloadEmojiIntensities()
    }
    
    func reloadEmojiIntensities() {
        do {
            let descriptor = FetchDescriptor<EmojiIntensity>(sortBy: [.init(\.order, order: .forward)])
            let newEmojis = try modelContext.fetch(descriptor)
            debugLog("Загружено эмодзи из базы: \(newEmojis.count)")
            emojiIntensities = newEmojis
            debugLog("Эмодзи после перезагрузки: \(emojiIntensities.count)")
        } catch {
            debugLog("Ошибка при загрузке эмодзи: \(error)")
        }
    }

    func ensureDefaultEmojiScale() {
        guard emojiIntensities.isEmpty else { return }

        for (index, item) in Self.defaultEmojiScale.enumerated() {
            let emoji = EmojiIntensity(
                emoji: item.emoji,
                color: .blue,
                opacity: item.opacity,
                order: index
            )
            modelContext.insert(emoji)
        }

        save()
        reloadEmojiIntensities()
    }
    
    private func save() {
        do {
            try modelContext.save()
        } catch {
            debugLog("Ошибка при сохранении эмодзи: \(error)")
        }
    }
}
