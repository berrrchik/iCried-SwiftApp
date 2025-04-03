import Foundation

protocol DataManagerProtocol {
    var entries: [TearEntry] { get }
    var tags: [TagItem] { get }
    var emojiIntensities: [EmojiIntensity] { get }
    
    func addEntry(_ entry: TearEntry)
    func deleteEntry(_ entry: TearEntry)
    func updateEntry(withId entryId: UUID, newDate: Date, newEmojiId: EmojiIntensity?, newTagId: TagItem?, newNote: String) throws

    func addTag(_ name: String)
    func removeTag(_ tagId: UUID)
    func moveTag(from source: IndexSet, to destination: Int)
    
    func addEmojiIntensity(_ emoji: EmojiIntensity)
    func removeEmojiIntensity(at index: Int)
    func updateEmojiIntensity(_ updatedEmoji: EmojiIntensity, at index: Int)
    func moveEmojiIntensity(from source: IndexSet, to destination: Int)
    
    func save()
}
