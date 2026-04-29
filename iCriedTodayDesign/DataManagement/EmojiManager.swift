import Foundation
import SwiftData

@Observable
class EmojiIntensityManager {
    private let modelContext: ModelContext
    private(set) var emojiIntensities: [EmojiIntensity] = []
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadEmojiIntensities()
    }
    
    private func loadEmojiIntensities() {
        do {
            let descriptor = FetchDescriptor<EmojiIntensity>(sortBy: [.init(\.order, order: .forward)])
            let newEmojis = try modelContext.fetch(descriptor)
            debugLog("Загружено эмодзи из базы: \(newEmojis.count)")
            emojiIntensities = newEmojis
        } catch {
            debugLog("Ошибка при загрузке эмодзи: \(error)")
        }
    }
    
    func reloadEmojiIntensities() {
        loadEmojiIntensities()
        debugLog("Эмодзи после перезагрузки: \(emojiIntensities.count)")
    }
    
    func addEmojiIntensity(_ emoji: EmojiIntensity) {
        if !emojiIntensities.contains(where: { $0.emoji == emoji.emoji }) {
            emoji.order = emojiIntensities.count
            modelContext.insert(emoji)
            emojiIntensities.append(emoji)
            save()
        } else {
            debugLog("Эмодзи '\(emoji.emoji)' уже существует")
        }
    }
    
    func removeEmojiIntensity(at index: Int) {
        guard index >= 0 && index < emojiIntensities.count else { return }
        let emoji = emojiIntensities[index]
        modelContext.delete(emoji)
        emojiIntensities.remove(at: index)
        save()
    }
    
    func updateEmojiIntensity(_ updatedEmoji: EmojiIntensity, at index: Int) {
        guard index >= 0 && index < emojiIntensities.count else { return }
        let original = emojiIntensities[index]
        original.emoji = updatedEmoji.emoji
        original.colorHex = updatedEmoji.colorHex
        original.opacity = updatedEmoji.opacity
        save()
    }
    
    func moveEmojiIntensity(from source: IndexSet, to destination: Int) {
        emojiIntensities.move(fromOffsets: source, toOffset: destination)
        for (index, emoji) in emojiIntensities.enumerated() {
            emoji.order = index
        }
        save()
    }
    
    func save() {
        do {
            try modelContext.save()
        } catch {
            debugLog("Ошибка при сохранении эмодзи: \(error)")
        }
    }
}
