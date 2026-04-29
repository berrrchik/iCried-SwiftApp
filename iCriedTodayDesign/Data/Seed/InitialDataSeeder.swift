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
        emojiRepository.ensureDefaultEmojiScale()
        
        if tagRepository.tags.isEmpty {
            let defaultTags = ["#Здоровье", "#Одиночество", "#Работа", "#Семья", "#Фильмы"]
            defaultTags.forEach { tagRepository.addTag($0) }
        }
    }
}
