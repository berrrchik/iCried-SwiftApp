import Foundation
import SwiftData

@Observable
class DuplicateRemover {
    private let modelContext: ModelContext
    private let entryManager: TearEntryManager
    private let tagManager: TagManager
    private let emojiManager: EmojiIntensityManager
    
    init(modelContext: ModelContext, entryManager: TearEntryManager, tagManager: TagManager, emojiManager: EmojiIntensityManager) {
        self.modelContext = modelContext
        self.entryManager = entryManager
        self.tagManager = tagManager
        self.emojiManager = emojiManager
    }
    
    func removeDuplicates() {
        removeDuplicateEmojis()
        removeDuplicateTags()
        removeDuplicateEntries()
    }
    
    private func removeDuplicateEmojis() {
        var groups: [String: [EmojiIntensity]] = Dictionary(grouping: emojiManager.emojiIntensities) { $0.emoji }
        for (_, group) in groups where group.count > 1 {
            let primary = group.sorted { $0.order < $1.order }.first!
            group.dropFirst().forEach { duplicate in
                entryManager.entries.filter { $0.emojiId?.id == duplicate.id }.forEach { $0.emojiId = primary }
                modelContext.delete(duplicate)
            }
        }
        emojiManager.reloadEmojiIntensities()
    }
    
    private func removeDuplicateTags() {
        var groups: [String: [TagItem]] = Dictionary(grouping: tagManager.tags) { $0.name.lowercased() }
        for (_, group) in groups where group.count > 1 {
            let primary = group.sorted { $0.order < $1.order }.first!
            group.dropFirst().forEach { duplicate in
                entryManager.entries.filter { $0.tagId?.id == duplicate.id }.forEach { $0.tagId = primary }
                modelContext.delete(duplicate)
            }
        }
        tagManager.reloadTags()
    }
    
    private func removeDuplicateEntries() {
        var uniqueIds = Set<UUID>()
        var duplicates: [TearEntry] = []
        entryManager.entries.forEach {
            if !uniqueIds.insert($0.id).inserted { duplicates.append($0) }
        }
        
        var uniqueSignatures = Set<String>()
        var contentDuplicates: [TearEntry] = []
        entryManager.entries.filter { !duplicates.contains($0) }.forEach { entry in
            let signature = "\(entry.date.timeIntervalSince1970)-\(entry.emojiId?.id.uuidString ?? "")-\(entry.tagId?.id.uuidString ?? "")-\(entry.note)"
            if !uniqueSignatures.insert(signature).inserted { contentDuplicates.append(entry) }
        }
        
        duplicates.append(contentsOf: contentDuplicates)
        duplicates.forEach { entryManager.deleteEntry($0) }
    }
}
