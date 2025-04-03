import Foundation

@Observable
class DataAnalyzer {
    private let entries: [TearEntry]
    private let tags: [TagItem]
    private let emojiIntensities: [EmojiIntensity]
    
    init(entries: [TearEntry], tags: [TagItem], emojiIntensities: [EmojiIntensity]) {
        self.entries = entries
        self.tags = tags
        self.emojiIntensities = emojiIntensities
    }
    
    var availableYears: [Int] {
        Set(entries.map { Calendar.current.component(.year, from: $0.date) }).sorted()
    }
    
    var groupedEntries: [(month: String, records: [TearEntry])] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "LLLL yyyy"
        
        let grouped = Dictionary(grouping: entries) { calendar.dateComponents([.year, .month], from: $0.date) }
        return grouped
            .sorted { $0.key.year! > $1.key.year! || ($0.key.year! == $1.key.year! && $0.key.month! > $1.key.month!) }
            .map { (formatter.string(from: calendar.date(from: $0.key)!).uppercased(), $0.value.sorted(by: { $0.date > $1.date })) }
    }
    
    func getTag(for entry: TearEntry) -> TagItem? {
        entry.tagId
    }
    
    func entriesForYear(_ year: Int, emoji: EmojiIntensity? = nil, tags: [TagItem]? = nil) -> [TearEntry] {
        let calendar = Calendar.current
        return entries.filter { entry in
            calendar.component(.year, from: entry.date) == year &&
            (emoji == nil || entry.emojiId?.id == emoji?.id) &&
            (tags == nil || (entry.tagId != nil && tags!.contains { tag in tag.id == entry.tagId!.id }))
        }
    }
    
    func totalEntriesForYear(_ year: Int) -> Int {
        entriesForYear(year).count
    }
    
    func getEmoji(for entry: TearEntry) -> EmojiIntensity {
        entry.emojiId ?? emojiIntensities.first ?? EmojiIntensity(emoji: "😶", color: .gray, opacity: 0.5, order: 0)
    }
    
    func emojiStatistics(for year: Int, tags: [TagItem]? = nil) -> [(emoji: String, count: Int)] {
        let yearEntries = entriesForYear(year, tags: tags)
        var counts: [UUID: Int] = [:]
        yearEntries.forEach { counts[$0.emojiId?.id ?? UUID(), default: 0] += 1 }
        return emojiIntensities.map { ($0.emoji, counts[$0.id] ?? 0) }
    }
    
    func tagStatistics(for year: Int, tags: [TagItem]? = nil) -> [(tag: String, count: Int)] {
        let yearEntries = entriesForYear(year, tags: tags)
        var counts: [UUID: Int] = [:]
        yearEntries.compactMap { $0.tagId?.id }.forEach { counts[$0, default: 0] += 1 }
        return (tags ?? self.tags).map { ($0.name, counts[$0.id] ?? 0) }
    }
    
    func monthlyDataByIntensity(for year: Int, emoji: EmojiIntensity? = nil, tags: [TagItem]? = nil) -> [(date: Date, intensityCounts: [Int])] {
        let calendar = Calendar.current
        let yearEntries = entriesForYear(year, emoji: emoji, tags: tags)
        
        return (1...12).map { month in
            let date = calendar.date(from: DateComponents(year: year, month: month, day: 1)) ?? Date()
            let monthEntries = yearEntries.filter { calendar.component(.month, from: $0.date) == month }
            var counts: [UUID: Int] = [:]
            monthEntries.forEach { counts[$0.emojiId?.id ?? UUID(), default: 0] += 1 }
            return (date, emojiIntensities.map { counts[$0.id] ?? 0 })
        }
    }
}
