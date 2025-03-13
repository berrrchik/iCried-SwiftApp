import Foundation

struct TearEntry: Identifiable, Codable {
    var id = UUID()
    var date: Date
    var emojiId: UUID
    var tagId: UUID?
    var note: String
    
    init(date: Date, emojiId: UUID, tagId: UUID?, note: String) {
        self.date = date
        self.emojiId = emojiId
        self.tagId = tagId
        self.note = note
    }
}
