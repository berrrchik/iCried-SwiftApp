import Foundation
import SwiftData
import Combine

@MainActor
final class TearDataManager: ObservableObject, DataManagerProtocol, DiaryDataManaging, StatisticsDataManaging, TagDataManaging, EntryFormDataProviding, EntryDisplayProviding {
    private let entryRepository: any EntryRepositoryProtocol
    private let tagRepository: any TagRepositoryProtocol
    private let emojiRepository: any EmojiRepositoryProtocol
    private let initialDataSeeder: InitialDataSeeder
    private var dataAnalyzer: DataAnalyzer
    private var remoteChangeObserver: AnyCancellable?
    
    @Published var refreshTrigger = UUID()
    var entries: [TearEntry] { entryRepository.entries }
    var tags: [TagItem] { tagRepository.tags }
    var emojiIntensities: [EmojiIntensity] { emojiRepository.emojiIntensities }
    
    init(modelContext: ModelContext) {
        self.entryRepository = EntryRepository(modelContext: modelContext)
        self.tagRepository = TagRepository(modelContext: modelContext)
        self.emojiRepository = EmojiRepository(modelContext: modelContext)
        self.initialDataSeeder = InitialDataSeeder(
            emojiRepository: emojiRepository,
            tagRepository: tagRepository,
            entryRepository: entryRepository
        )
        self.dataAnalyzer = DataAnalyzer(
            entries: entryRepository.entries,
            tags: tagRepository.tags,
            emojiIntensities: emojiRepository.emojiIntensities
        )
        
        initialDataSeeder.seedIfNeeded()
        updateAnalyzer()
        observeRemoteChanges()
    }
    
    // MARK: - Entry Management
    
    func addEntry(_ entry: TearEntry) {
        entryRepository.addEntry(entry)
        updateAnalyzer()
        debugLog("Добавлена новая запись: \(entry.note)")
    }
    
    func deleteEntry(_ entry: TearEntry) {
        entryRepository.deleteEntry(entry)
        updateAnalyzer()
        debugLog("Удалена запись: \(entry.note)")
    }
    
    func updateEntry(withId entryId: UUID, newDate: Date, newEmojiId: EmojiIntensity?, newTagId: TagItem?, newNote: String) throws {
        try entryRepository.updateEntry(withId: entryId, newDate: newDate, newEmojiId: newEmojiId, newTagId: newTagId, newNote: newNote)
        updateAnalyzer()
        debugLog("Обновлена запись с id: \(entryId)")
    }
    
    // MARK: - Tag Management
    
    func addTag(_ name: String) {
        tagRepository.addTag(name)
        updateAnalyzer()
        debugLog("Добавлен тег: \(name)")
    }
    
    func updateTag(withId tagId: UUID, newName: String) {
        tagRepository.updateTag(withId: tagId, newName: newName)
        updateAnalyzer()
        debugLog("Обновлён тег с ID: \(tagId)")
    }
    
    func removeTag(_ tagId: UUID) {
        tagRepository.removeTag(tagId)
        updateAnalyzer()
        debugLog("Удалён тег с ID: \(tagId)")
    }
    
    func moveTag(from source: IndexSet, to destination: Int) {
        tagRepository.moveTag(from: source, to: destination)
        updateAnalyzer()
        debugLog("Теги перемещены")
    }
    
    // MARK: - Data Analysis
    
    func updateAnalyzer() {
        dataAnalyzer = DataAnalyzer(
            entries: entryRepository.entries,
            tags: tagRepository.tags,
            emojiIntensities: emojiRepository.emojiIntensities
        )
        refreshTrigger = UUID()
        debugLog("Анализатор данных обновлён")
    }
    
    var availableYears: [Int] { dataAnalyzer.availableYears }
    
    var groupedEntries: [DiarySection] {
        let result = dataAnalyzer.groupedEntries
        debugLog("Количество записей в groupedEntries: \(result.reduce(0) { $0 + $1.records.count })")
        return result
    }
    
    func getTag(for entry: TearEntry) -> TagItem? { dataAnalyzer.getTag(for: entry) }
    func entriesForYear(_ year: Int, emoji: EmojiIntensity? = nil, tags: [TagItem]? = nil) -> [TearEntry] {
        dataAnalyzer.entriesForYear(year, emoji: emoji, tags: tags)
    }
    func totalEntriesForYear(_ year: Int) -> Int { dataAnalyzer.totalEntriesForYear(year) }
    func getEmoji(for entry: TearEntry) -> EmojiIntensity { dataAnalyzer.getEmoji(for: entry) }
    func emojiStatistics(for year: Int, tags: [TagItem]? = nil) -> [(emoji: String, count: Int)] {
        dataAnalyzer.emojiStatistics(for: year, tags: tags)
    }
    func tagStatistics(for year: Int, tags: [TagItem]? = nil) -> [(tag: String, count: Int)] {
        dataAnalyzer.tagStatistics(for: year, tags: tags)
    }
    func monthlyDataByIntensity(for year: Int, emoji: EmojiIntensity? = nil, tags: [TagItem]? = nil) -> [(date: Date, intensityCounts: [Int])] {
        dataAnalyzer.monthlyDataByIntensity(for: year, emoji: emoji, tags: tags)
    }
    func statisticsSnapshot(for filter: StatisticsFilter) -> StatisticsSnapshot {
        dataAnalyzer.statisticsSnapshot(filter: filter)
    }
    func entriesForDay(_ date: Date) -> [TearEntry] {
        let statisticsEngine = StatisticsEngine(
            entries: entries,
            tags: tags,
            emojiIntensities: emojiIntensities
        )
        return statisticsEngine.entriesForDay(date)
    }
    func buildExportSummary(filter: StatisticsFilter) -> ExportSummary {
        let snapshot = statisticsSnapshot(for: filter)
        let topTags = snapshot.tagItems
            .filter { $0.count > 0 }
            .sorted { $0.count > $1.count }
            .prefix(5)
            .map { (name: $0.name, count: $0.count) }
        let emojiStats = snapshot.emojiItems
            .filter { $0.count > 0 }
            .sorted { $0.count > $1.count }
            .map { (emoji: $0.emoji, count: $0.count) }

        let periodTitle: String
        if let month = filter.selectedMonth {
            periodTitle = month.formatted(.dateTime.month(.wide).year().locale(Locale(identifier: "ru_RU")))
        } else {
            periodTitle = "\(filter.year) год"
        }

        return ExportSummary(
            periodTitle: periodTitle,
            totalEntries: snapshot.filteredEntriesCount,
            topTags: Array(topTags),
            emojiStats: emojiStats,
            heatmapSnapshot: nil
        )
    }
    func buildInsightSummary(type: InsightType, filter: StatisticsFilter) -> InsightSummary? {
        nil
    }
    func selectedMonthMatches(_ date: Date, selectedMonth: Date?) -> Bool {
        dataAnalyzer.selectedMonthMatches(date, selectedMonth: selectedMonth)
    }
    func toggledMonthSelection(current: Date?, tappedDate: Date) -> Date? {
        dataAnalyzer.toggledMonthSelection(current: current, tappedDate: tappedDate)
    }
    func cryingMomentsLabel(for count: Int) -> String {
        dataAnalyzer.cryingMomentsLabel(for: count)
    }
    
    // MARK: - Refresh

    func refreshData() async {
        reloadFromStore(reason: "user refresh")
    }

    private func reloadRepositories() {
        entryRepository.reloadEntries()
        tagRepository.reloadTags()
        emojiRepository.reloadEmojiIntensities()
    }
    
    private func reloadFromStore(reason: String) {
        reloadRepositories()
        updateAnalyzer()
        debugLog("Данные обновлены из локального store: \(reason)")
    }
    
    private func observeRemoteChanges() {
        remoteChangeObserver = NotificationCenter.default
            .publisher(for: .NSPersistentStoreRemoteChange)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                Task { @MainActor in
                    guard let self else { return }
                    self.reloadFromStore(reason: "remote change")
                }
            }
    }
}
