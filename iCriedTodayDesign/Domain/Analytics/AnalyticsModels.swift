import Foundation

struct DiarySection: Identifiable {
    let monthStart: Date
    let monthTitle: String
    let records: [TearEntry]
    
    var id: Date { monthStart }
}

struct StatisticsMonthPoint: Identifiable {
    let monthStart: Date
    let intensityCounts: [Int]
    
    var id: Date { monthStart }
}

struct EmojiStatItem: Identifiable {
    let emojiID: UUID
    let emoji: String
    let count: Int
    
    var id: UUID { emojiID }
}

struct TagStatItem: Identifiable {
    let tagID: UUID
    let name: String
    let count: Int
    
    var id: UUID { tagID }
}

struct StatisticsFilter {
    let year: Int
    let selectedMonth: Date?
    let selectedEmojiID: UUID?
    let selectedTagIDs: Set<UUID>
}

struct StatisticsSnapshot {
    let filteredEntriesCount: Int
    let diarySections: [DiarySection]
    let monthPoints: [StatisticsMonthPoint]
    let emojiItems: [EmojiStatItem]
    let tagItems: [TagStatItem]
}
