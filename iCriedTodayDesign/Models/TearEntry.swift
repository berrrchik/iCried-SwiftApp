import Foundation
import SwiftData

@Model
final class TearEntry {
    var id: UUID = UUID()
    var date: Date = Date()
    @Relationship var emojiId: EmojiIntensity?
    @Relationship var tagId: TagItem?
    var note: String = ""
    
    init(date: Date, emojiId: EmojiIntensity?, tagId: TagItem?, note: String) {
        self.id = UUID()
        self.date = date
        self.emojiId = emojiId
        self.tagId = tagId
        self.note = note
    }
}
