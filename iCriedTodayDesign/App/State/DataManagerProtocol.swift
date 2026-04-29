import Foundation

@MainActor
protocol DataManagerProtocol: AnyObject {
    var entries: [TearEntry] { get }
    var tags: [TagItem] { get }
    var emojiIntensities: [EmojiIntensity] { get }
    var refreshTrigger: UUID { get }
    
    func addEntry(_ entry: TearEntry)
    func deleteEntry(_ entry: TearEntry)
    func updateEntry(withId entryId: UUID, newDate: Date, newEmojiId: EmojiIntensity?, newTagId: TagItem?, newNote: String) throws
    func refreshData() async
    func getTag(for entry: TearEntry) -> TagItem?
    func getEmoji(for entry: TearEntry) -> EmojiIntensity

    func addTag(_ name: String)
    func updateTag(withId tagId: UUID, newName: String)
    func removeTag(_ tagId: UUID)
    func moveTag(from source: IndexSet, to destination: Int)
    
}

@MainActor
protocol DiaryDataManaging: AnyObject {
    var entries: [TearEntry] { get }
    var groupedEntries: [DiarySection] { get }
    var tags: [TagItem] { get }
    var emojiIntensities: [EmojiIntensity] { get }
    var refreshTrigger: UUID { get }
    func addEntry(_ entry: TearEntry)
    func deleteEntry(_ entry: TearEntry)
    func refreshData() async
}

@MainActor
protocol StatisticsDataManaging: AnyObject {
    var entries: [TearEntry] { get }
    var tags: [TagItem] { get }
    var emojiIntensities: [EmojiIntensity] { get }
    var refreshTrigger: UUID { get }
    var availableYears: [Int] { get }
    func addEntry(_ entry: TearEntry)
    func deleteEntry(_ entry: TearEntry)
    func statisticsSnapshot(for filter: StatisticsFilter) -> StatisticsSnapshot
    func selectedMonthMatches(_ date: Date, selectedMonth: Date?) -> Bool
    func toggledMonthSelection(current: Date?, tappedDate: Date) -> Date?
    func cryingMomentsLabel(for count: Int) -> String
    func entriesForDay(_ date: Date) -> [TearEntry]
    func buildExportSummary(filter: StatisticsFilter) -> ExportSummary
    func buildInsightSummary(type: InsightType, filter: StatisticsFilter) -> InsightSummary?
}

@MainActor
protocol TagDataManaging: AnyObject {
    var tags: [TagItem] { get }
    var refreshTrigger: UUID { get }
    func addTag(_ name: String)
    func updateTag(withId tagId: UUID, newName: String)
    func removeTag(_ tagId: UUID)
    func moveTag(from source: IndexSet, to destination: Int)
}

@MainActor
protocol EntryFormDataProviding: AnyObject {
    var tags: [TagItem] { get }
    var emojiIntensities: [EmojiIntensity] { get }
}

@MainActor
protocol EntryDisplayProviding: AnyObject {
    func getTag(for entry: TearEntry) -> TagItem?
    func getEmoji(for entry: TearEntry) -> EmojiIntensity
}
