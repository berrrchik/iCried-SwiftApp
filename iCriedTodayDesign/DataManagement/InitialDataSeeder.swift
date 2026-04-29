import Foundation

@MainActor
final class InitialDataSeeder {
    private let emojiRepository: any EmojiRepositoryProtocol
    private let tagRepository: any TagRepositoryProtocol
    
    init(emojiRepository: any EmojiRepositoryProtocol, tagRepository: any TagRepositoryProtocol) {
        self.emojiRepository = emojiRepository
        self.tagRepository = tagRepository
    }
    
    func seedIfNeeded() {
        if emojiRepository.emojiIntensities.isEmpty {
            let defaultEmojis = [
                ("🥲", 0.4),
                ("😢", 0.7),
                ("😭", 1.0)
            ]
            
            for (index, (emoji, opacity)) in defaultEmojis.enumerated() {
                let newEmoji = EmojiIntensity(emoji: emoji, color: .blue, opacity: opacity, order: index)
                emojiRepository.addEmojiIntensity(newEmoji)
            }
        }
        
        if tagRepository.tags.isEmpty {
            let defaultTags = ["#Здоровье", "#Одиночество", "#Работа", "#Семья", "#Фильмы"]
            defaultTags.forEach { tagRepository.addTag($0) }
        }
    }
}
