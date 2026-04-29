import Foundation
import CryptoKit
import SwiftData

func stableUUID(from value: String) -> UUID {
    let digest = Insecure.MD5.hash(data: Data(value.utf8))
    let hex = digest.map { String(format: "%02x", $0) }.joined()
    
    let first = String(hex.prefix(8))
    let secondStart = hex.index(hex.startIndex, offsetBy: 8)
    let secondEnd = hex.index(secondStart, offsetBy: 4)
    let thirdEnd = hex.index(secondEnd, offsetBy: 4)
    let fourthEnd = hex.index(thirdEnd, offsetBy: 4)
    
    let second = String(hex[secondStart..<secondEnd])
    let third = String(hex[secondEnd..<thirdEnd])
    let fourth = String(hex[thirdEnd..<fourthEnd])
    let fifth = String(hex[fourthEnd...])
    
    let uuidString = [first, second, third, fourth, fifth].joined(separator: "-")
    
    return UUID(uuidString: uuidString) ?? UUID()
}

@Model
final class TearEntry {
    var id: UUID = UUID()
    var date: Date = Date()
    @Relationship var emojiId: EmojiIntensity?
    @Relationship var tagId: TagItem?
    var note: String = ""
    
    init(date: Date, emojiId: EmojiIntensity?, tagId: TagItem?, note: String) {
        let idString = "\(date.timeIntervalSince1970)-\(emojiId?.id.uuidString ?? "")-\(tagId?.id.uuidString ?? "")-\(note)"
        self.id = stableUUID(from: idString)
        self.date = date
        self.emojiId = emojiId
        self.tagId = tagId
        self.note = note
    }
}
