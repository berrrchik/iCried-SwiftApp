import Foundation
import UIKit

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

struct HeatmapDaySummary: Identifiable {
    let id: UUID
    let date: Date
    let entryCount: Int
    let dominantEmojiID: UUID?
    let intensityScore: Double
}

enum HeatmapDisplayMode {
    case monthly
    case yearly
}

struct ExportSummary {
    let periodTitle: String
    let totalEntries: Int
    let topTags: [(name: String, count: Int)]
    let emojiStats: [(emoji: String, count: Int)]
    let heatmapSnapshot: UIImage?
}

enum InsightType: CaseIterable, Identifiable {
    case thisMonth
    case topTrigger
    case mostUsedEmoji
    case yearSummary

    var id: Self { self }
}

extension InsightType {
    var displayTitle: String {
        switch self {
        case .thisMonth:
            return "Этот месяц"
        case .topTrigger:
            return "Топ причина"
        case .mostUsedEmoji:
            return "Самый частый эмодзи"
        case .yearSummary:
            return "Год в целом"
        }
    }

    var displaySubtitle: String {
        switch self {
        case .thisMonth:
            return "Сравнение с прошлым месяцем"
        case .topTrigger:
            return "Самый частый тег"
        case .mostUsedEmoji:
            return "Эмодзи с наибольшим числом записей"
        case .yearSummary:
            return "Итог за год"
        }
    }

    var systemImageName: String {
        switch self {
        case .thisMonth:
            return "calendar"
        case .topTrigger:
            return "tag"
        case .mostUsedEmoji:
            return "face.smiling"
        case .yearSummary:
            return "chart.bar"
        }
    }
}

struct InsightSummary {
    let type: InsightType
    let title: String
    let primaryStat: String
    let secondaryStat: String?
    let emoji: String?
    let accentColorHex: String?
}
