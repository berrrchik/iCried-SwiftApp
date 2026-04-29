import Foundation
import Combine

@MainActor
final class StatisticsViewModel: ObservableObject {
    @Published var selectedYear: Int {
        didSet { recomputeSnapshot(resetMonthIfNeeded: true) }
    }
    @Published var selectedTagIDs: Set<UUID> = [] {
        didSet { recomputeSnapshot() }
    }
    @Published var selectedEmojiID: UUID? = nil {
        didSet { recomputeSnapshot() }
    }
    @Published var selectedMonth: Date? = nil {
        didSet { recomputeSnapshot() }
    }
    @Published var showingAddTear = false
    @Published var showingDeleteAlert = false
    @Published private(set) var entryToDelete: TearEntry?
    @Published private(set) var isEmpty = true
    @Published private(set) var snapshot = StatisticsSnapshot(
        filteredEntriesCount: 0,
        diarySections: [],
        monthPoints: [],
        emojiItems: [],
        tagItems: []
    )
    
    private let dataManager: any StatisticsDataManaging
    
    init(dataManager: any StatisticsDataManaging) {
        self.dataManager = dataManager
        self.selectedYear = dataManager.availableYears.last ?? Calendar.current.component(.year, from: Date())
        recomputeSnapshot()
    }
    
    var availableTags: [TagItem] {
        dataManager.tags
    }
    
    var availableEmojiIntensities: [EmojiIntensity] {
        dataManager.emojiIntensities
    }
    
    var availableYears: [Int] {
        dataManager.availableYears
    }
    
    func syncFromDataManager() {
        isEmpty = dataManager.entries.isEmpty
        if !availableYears.contains(selectedYear), let lastYear = availableYears.last {
            selectedYear = lastYear
            return
        }
        
        recomputeSnapshot()
    }
    
    func changeYear(by offset: Int) {
        guard let currentIndex = availableYears.firstIndex(of: selectedYear) else { return }
        
        let newIndex = currentIndex + offset
        guard availableYears.indices.contains(newIndex) else { return }
        
        selectedYear = availableYears[newIndex]
    }
    
    func toggleTag(_ tagID: UUID) {
        if selectedTagIDs.contains(tagID) {
            selectedTagIDs.remove(tagID)
        } else {
            selectedTagIDs.insert(tagID)
        }
    }
    
    func toggleEmoji(_ emojiID: UUID) {
        selectedEmojiID = selectedEmojiID == emojiID ? nil : emojiID
    }
    
    func toggleMonth(_ date: Date) {
        selectedMonth = dataManager.toggledMonthSelection(current: selectedMonth, tappedDate: date)
    }
    
    func monthMatches(_ date: Date) -> Bool {
        dataManager.selectedMonthMatches(date, selectedMonth: selectedMonth)
    }
    
    func opacity(for date: Date, emojiID: UUID) -> Double {
        if selectedMonth == nil && selectedEmojiID == nil { return 1.0 }
        
        let monthMatch = selectedMonth == nil || monthMatches(date)
        let emojiMatch = selectedEmojiID == nil || selectedEmojiID == emojiID
        return (monthMatch && emojiMatch) ? 1.0 : 0.3
    }
    
    func presentDelete(for entry: TearEntry) {
        entryToDelete = entry
        showingDeleteAlert = true
    }
    
    func dismissDelete() {
        entryToDelete = nil
        showingDeleteAlert = false
    }
    
    func confirmDelete() {
        guard let entryToDelete else { return }
        dataManager.deleteEntry(entryToDelete)
        syncFromDataManager()
        dismissDelete()
    }
    
    func cryingMomentsLabel() -> String {
        dataManager.cryingMomentsLabel(for: snapshot.filteredEntriesCount)
    }
    
    func addEntry(_ entry: TearEntry) {
        dataManager.addEntry(entry)
        syncFromDataManager()
    }
    
    private func recomputeSnapshot(resetMonthIfNeeded: Bool = false) {
        isEmpty = dataManager.entries.isEmpty
        if resetMonthIfNeeded {
            selectedMonth = nil
        }
        
        snapshot = dataManager.statisticsSnapshot(
            for: StatisticsFilter(
                year: selectedYear,
                selectedMonth: selectedMonth,
                selectedEmojiID: selectedEmojiID,
                selectedTagIDs: selectedTagIDs
            )
        )
    }
}
