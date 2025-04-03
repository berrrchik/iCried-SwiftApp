import Foundation
import SwiftData

@Observable
class DataLoader {
    private let modelContext: ModelContext
    private let emojiManager: EmojiIntensityManager
    private let tagManager: TagManager
    
    init(modelContext: ModelContext, emojiManager: EmojiIntensityManager, tagManager: TagManager) {
        self.modelContext = modelContext
        self.emojiManager = emojiManager
        self.tagManager = tagManager
    }
    
    func loadInitialData() {
        if emojiManager.emojiIntensities.isEmpty {
            let defaultEmojis = [
                ("🥲", 0.4),
                ("😢", 0.7),
                ("😭", 1.0)
            ]
            
            for (index, (emoji, opacity)) in defaultEmojis.enumerated() {
                let newEmoji = EmojiIntensity(emoji: emoji, color: .blue, opacity: opacity, order: index)
                emojiManager.addEmojiIntensity(newEmoji)
            }
        }
        
        if tagManager.tags.isEmpty {
            let defaultTags = ["#Здоровье", "#Одиночество", "#Работа", "#Семья", "#Фильмы"]
            defaultTags.forEach { tagManager.addTag($0) }
        }
    }
}
