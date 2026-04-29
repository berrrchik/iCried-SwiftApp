import Foundation

@MainActor
protocol EntryRepositoryProtocol: AnyObject {
    var entries: [TearEntry] { get }
    
    func reloadEntries()
    func addEntry(_ entry: TearEntry)
    func deleteEntry(_ entry: TearEntry)
    func updateEntry(
        withId entryId: UUID,
        newDate: Date,
        newEmojiId: EmojiIntensity?,
        newTagId: TagItem?,
        newNote: String
    ) throws
}

@MainActor
protocol TagRepositoryProtocol: AnyObject {
    var tags: [TagItem] { get }
    
    func reloadTags()
    func addTag(_ name: String)
    func updateTag(withId tagId: UUID, newName: String)
    func removeTag(_ tagId: UUID)
    func moveTag(from source: IndexSet, to destination: Int)
}

@MainActor
protocol EmojiRepositoryProtocol: AnyObject {
    var emojiIntensities: [EmojiIntensity] { get }
    
    func reloadEmojiIntensities()
    func addEmojiIntensity(_ emoji: EmojiIntensity)
    func removeEmojiIntensity(at index: Int)
    func updateEmojiIntensity(_ updatedEmoji: EmojiIntensity, at index: Int)
    func moveEmojiIntensity(from source: IndexSet, to destination: Int)
}
