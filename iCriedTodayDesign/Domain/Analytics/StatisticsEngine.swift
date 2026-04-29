import Foundation

struct StatisticsEngine {
    private let entries: [TearEntry]
    private let tags: [TagItem]
    private let emojiIntensities: [EmojiIntensity]
    private let entryGrouper: EntryGrouper
    private let calendar: Calendar
    
    init(
        entries: [TearEntry],
        tags: [TagItem],
        emojiIntensities: [EmojiIntensity],
        entryGrouper: EntryGrouper = EntryGrouper(),
        calendar: Calendar = .current
    ) {
        self.entries = entries
        self.tags = tags
        self.emojiIntensities = emojiIntensities
        self.entryGrouper = entryGrouper
        self.calendar = calendar
    }
    
    var availableYears: [Int] {
        Set(entries.map { calendar.component(.year, from: $0.date) }).sorted()
    }
    
    func diarySections() -> [DiarySection] {
        entryGrouper.group(entries)
    }
    
    func entriesForYear(_ year: Int, emojiID: UUID? = nil, tagIDs: Set<UUID> = []) -> [TearEntry] {
        entries.filter { entry in
            calendar.component(.year, from: entry.date) == year &&
            (emojiID == nil || entry.emojiId?.id == emojiID) &&
            (tagIDs.isEmpty || (entry.tagId != nil && tagIDs.contains(entry.tagId!.id)))
        }
    }
    
    func totalEntriesForYear(_ year: Int) -> Int {
        entriesForYear(year).count
    }
    
    func emojiStatistics(for year: Int, tagIDs: Set<UUID> = []) -> [EmojiStatItem] {
        let yearEntries = entriesForYear(year, tagIDs: tagIDs)
        let counts = Dictionary(yearEntries.compactMap { $0.emojiId?.id }.map { ($0, 1) }, uniquingKeysWith: +)
        
        return emojiIntensities.map {
            EmojiStatItem(emojiID: $0.id, emoji: $0.emoji, count: counts[$0.id] ?? 0)
        }
    }
    
    func tagStatistics(for year: Int) -> [TagStatItem] {
        let yearEntries = entriesForYear(year)
        let counts = Dictionary(yearEntries.compactMap { $0.tagId?.id }.map { ($0, 1) }, uniquingKeysWith: +)
        
        return tags.map {
            TagStatItem(tagID: $0.id, name: $0.name, count: counts[$0.id] ?? 0)
        }
    }
    
    func monthlyPoints(for year: Int, tagIDs: Set<UUID> = []) -> [StatisticsMonthPoint] {
        let yearEntries = entriesForYear(year, tagIDs: tagIDs)
        
        return (1...12).compactMap { month in
            guard let monthStart = calendar.date(from: DateComponents(year: year, month: month, day: 1)) else {
                return nil
            }
            
            let monthEntries = yearEntries.filter { calendar.component(.month, from: $0.date) == month }
            let counts = Dictionary(monthEntries.compactMap { $0.emojiId?.id }.map { ($0, 1) }, uniquingKeysWith: +)
            let intensityCounts = emojiIntensities.map { counts[$0.id] ?? 0 }
            
            return StatisticsMonthPoint(monthStart: monthStart, intensityCounts: intensityCounts)
        }
    }
    
    func snapshot(filter: StatisticsFilter) -> StatisticsSnapshot {
        let filteredEntries = monthFilteredEntries(
            year: filter.year,
            selectedMonth: filter.selectedMonth,
            selectedEmojiID: filter.selectedEmojiID,
            selectedTagIDs: filter.selectedTagIDs
        )
        
        return StatisticsSnapshot(
            filteredEntriesCount: filteredEntries.count,
            diarySections: entryGrouper.group(filteredEntries),
            monthPoints: monthlyPoints(for: filter.year, tagIDs: filter.selectedTagIDs),
            emojiItems: emojiStatistics(for: filter.year, tagIDs: filter.selectedTagIDs),
            tagItems: tagStatistics(for: filter.year)
        )
    }
    
    func toggledMonthSelection(current: Date?, tappedDate: Date) -> Date? {
        matchesMonth(tappedDate, selectedMonth: current) ? nil : tappedDate
    }
    
    func matchesMonth(_ date: Date, selectedMonth: Date?) -> Bool {
        entryGrouper.matchesMonth(date, selectedMonth: selectedMonth)
    }
    
    private func monthFilteredEntries(
        year: Int,
        selectedMonth: Date?,
        selectedEmojiID: UUID?,
        selectedTagIDs: Set<UUID>
    ) -> [TearEntry] {
        let yearEntries = entriesForYear(year, emojiID: selectedEmojiID, tagIDs: selectedTagIDs)
        
        guard let selectedMonth else {
            return yearEntries
        }
        
        return yearEntries.filter { entryGrouper.matchesMonth($0.date, selectedMonth: selectedMonth) }
    }
}
