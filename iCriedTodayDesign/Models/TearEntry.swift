import Foundation
import SwiftData

@Model
final class TearEntry {
    var id: UUID = UUID()
    var date: Date = Date()
    var emojiId: UUID = UUID()
    var tagId: UUID?
    var note: String = ""
    
    init(date: Date, emojiId: UUID, tagId: UUID?, note: String) {
        self.id = UUID()
        self.date = date
        self.emojiId = emojiId
        self.tagId = tagId
        self.note = note
    }
}
