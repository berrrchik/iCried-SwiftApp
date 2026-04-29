import Foundation

@Observable
class DataAnalyzer {
    private let entries: [TearEntry]
    private let tags: [TagItem]
    private let emojiIntensities: [EmojiIntensity]
    private let entryGrouper = EntryGrouper()
    
    init(entries: [TearEntry], tags: [TagItem], emojiIntensities: [EmojiIntensity]) {
        self.entries = entries
        self.tags = tags
        self.emojiIntensities = emojiIntensities
    }
    
    var availableYears: [Int] {
        statisticsEngine.availableYears
    }
    
    var groupedEntries: [DiarySection] {
        statisticsEngine.diarySections()
    }
    
    func getTag(for entry: TearEntry) -> TagItem? {
        entry.tagId
    }
    
    func entriesForYear(_ year: Int, emoji: EmojiIntensity? = nil, tags: [TagItem]? = nil) -> [TearEntry] {
        let selectedTagIDs = Set(tags?.map(\.id) ?? [])
        return statisticsEngine.entriesForYear(year, emojiID: emoji?.id, tagIDs: selectedTagIDs)
    }
    
    func totalEntriesForYear(_ year: Int) -> Int {
        statisticsEngine.totalEntriesForYear(year)
    }
    
    func getEmoji(for entry: TearEntry) -> EmojiIntensity {
        entry.emojiId ?? emojiIntensities.first ?? EmojiIntensity(emoji: "😶", color: .gray, opacity: 0.5, order: 0)
    }
    
    func emojiStatistics(for year: Int, tags: [TagItem]? = nil) -> [(emoji: String, count: Int)] {
        let selectedTagIDs = Set(tags?.map(\.id) ?? [])
        return statisticsEngine
            .emojiStatistics(for: year, tagIDs: selectedTagIDs)
            .map { ($0.emoji, $0.count) }
    }
    
    func tagStatistics(for year: Int, tags: [TagItem]? = nil) -> [(tag: String, count: Int)] {
        let selectedTags = tags ?? self.tags
        let countsByTag = Dictionary(
            statisticsEngine.tagStatistics(for: year).map { ($0.tagID, $0.count) },
            uniquingKeysWith: { first, _ in first }
        )
        
        return selectedTags.map { ($0.name, countsByTag[$0.id] ?? 0) }
    }
    
    func monthlyDataByIntensity(for year: Int, emoji: EmojiIntensity? = nil, tags: [TagItem]? = nil) -> [(date: Date, intensityCounts: [Int])] {
        let selectedTagIDs = Set(tags?.map(\.id) ?? [])
        var points = statisticsEngine.monthlyPoints(for: year, tagIDs: selectedTagIDs)
        
        if let emoji {
            guard let emojiIndex = emojiIntensities.firstIndex(where: { $0.id == emoji.id }) else {
                return points.map { ($0.monthStart, Array(repeating: 0, count: $0.intensityCounts.count)) }
            }
            
            points = points.map { point in
                let filteredCounts = point.intensityCounts.enumerated().map { index, count in
                    index == emojiIndex ? count : 0
                }
                return StatisticsMonthPoint(monthStart: point.monthStart, intensityCounts: filteredCounts)
            }
        }
        
        return points.map { ($0.monthStart, $0.intensityCounts) }
    }
    
    func statisticsSnapshot(filter: StatisticsFilter) -> StatisticsSnapshot {
        statisticsEngine.snapshot(filter: filter)
    }
    
    func selectedMonthMatches(_ date: Date, selectedMonth: Date?) -> Bool {
        statisticsEngine.matchesMonth(date, selectedMonth: selectedMonth)
    }
    
    func toggledMonthSelection(current: Date?, tappedDate: Date) -> Date? {
        statisticsEngine.toggledMonthSelection(current: current, tappedDate: tappedDate)
    }
    
    func cryingMomentsLabel(for count: Int) -> String {
        CryingMomentsPluralizer.label(for: count)
    }
    
    private var statisticsEngine: StatisticsEngine {
        StatisticsEngine(
            entries: entries,
            tags: tags,
            emojiIntensities: emojiIntensities,
            entryGrouper: entryGrouper
        )
    }
}
