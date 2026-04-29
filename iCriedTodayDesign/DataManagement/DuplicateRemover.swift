import Foundation

@MainActor
final class DuplicateRemover {
    private let entryRepository: any EntryRepositoryProtocol
    private let tagRepository: any TagRepositoryProtocol
    private let emojiRepository: any EmojiRepositoryProtocol
    
    init(
        entryRepository: any EntryRepositoryProtocol,
        tagRepository: any TagRepositoryProtocol,
        emojiRepository: any EmojiRepositoryProtocol
    ) {
        self.entryRepository = entryRepository
        self.tagRepository = tagRepository
        self.emojiRepository = emojiRepository
    }
    
    func removeDuplicates() {
        removeDuplicateEmojis()
        removeDuplicateTags()
        removeDuplicateEntries()
    }
    
    private func removeDuplicateEmojis() {
        let groups = Dictionary(grouping: emojiRepository.emojiIntensities) { $0.emoji }
        for (_, group) in groups where group.count > 1 {
            let primary = group.sorted { $0.order < $1.order }.first!
            group.dropFirst().forEach { duplicate in
                entryRepository.entries
                    .filter { $0.emojiId?.id == duplicate.id }
                    .forEach { $0.emojiId = primary }
                
                if let duplicateIndex = emojiRepository.emojiIntensities.firstIndex(where: { $0.id == duplicate.id }) {
                    emojiRepository.removeEmojiIntensity(at: duplicateIndex)
                }
            }
        }
        emojiRepository.reloadEmojiIntensities()
    }
    
    private func removeDuplicateTags() {
        let groups = Dictionary(grouping: tagRepository.tags) { $0.name.lowercased() }
        for (_, group) in groups where group.count > 1 {
            let primary = group.sorted { $0.order < $1.order }.first!
            group.dropFirst().forEach { duplicate in
                entryRepository.entries
                    .filter { $0.tagId?.id == duplicate.id }
                    .forEach { $0.tagId = primary }
                tagRepository.removeTag(duplicate.id)
            }
        }
        tagRepository.reloadTags()
    }
    
    private func removeDuplicateEntries() {
        var uniqueIds = Set<UUID>()
        var duplicates: [TearEntry] = []
        entryRepository.entries.forEach {
            if !uniqueIds.insert($0.id).inserted { duplicates.append($0) }
        }
        
        var uniqueSignatures = Set<String>()
        var contentDuplicates: [TearEntry] = []
        entryRepository.entries.filter { !duplicates.contains($0) }.forEach { entry in
            let signature = "\(entry.date.timeIntervalSince1970)-\(entry.emojiId?.id.uuidString ?? "")-\(entry.tagId?.id.uuidString ?? "")-\(entry.note)"
            if !uniqueSignatures.insert(signature).inserted { contentDuplicates.append(entry) }
        }
        
        duplicates.append(contentsOf: contentDuplicates)
        duplicates.forEach { entryRepository.deleteEntry($0) }
        entryRepository.reloadEntries()
    }
}
