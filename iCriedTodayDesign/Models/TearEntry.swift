import Foundation

struct TearEntry: Identifiable, Codable {
    var id = UUID()
    var date: Date
    var emojiId: UUID
    var tags: Set<String>
    var note: String
    
    init(date: Date, emojiId: UUID, tags: Set<String>, note: String) {
        self.date = date
        self.emojiId = emojiId
        self.tags = tags
        self.note = note
    }
} 