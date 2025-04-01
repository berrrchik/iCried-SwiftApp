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
        let idString = "\(date.timeIntervalSince1970)-\(emojiId?.id.uuidString ?? "")-\(tagId?.id.uuidString ?? "")-\(note)"
        let idData = idString.data(using: .utf8)!
        self.id = UUID(uuidString: idData.base64EncodedString()) ?? UUID()
        self.date = date
        self.emojiId = emojiId
        self.tagId = tagId
        self.note = note
    }
}
