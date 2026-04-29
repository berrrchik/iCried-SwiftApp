import Foundation
import Combine

@MainActor
final class DiaryViewModel: ObservableObject {
    @Published private(set) var sections: [DiarySection] = []
    @Published private(set) var isEmpty = true
    @Published var showingAddTear = false
    @Published var showingDeleteAlert = false
    @Published private(set) var entryToDelete: TearEntry?
    
    private let dataManager: any DiaryDataManaging
    
    init(dataManager: any DiaryDataManaging) {
        self.dataManager = dataManager
        syncFromDataManager()
    }
    
    var availableTags: [TagItem] {
        dataManager.tags
    }
    
    var availableEmojiIntensities: [EmojiIntensity] {
        dataManager.emojiIntensities
    }
    
    func syncFromDataManager() {
        sections = dataManager.groupedEntries
        isEmpty = dataManager.entries.isEmpty
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
    
    func refresh() async {
        await dataManager.refreshData()
        syncFromDataManager()
    }
    
    func addEntry(_ entry: TearEntry) {
        dataManager.addEntry(entry)
        syncFromDataManager()
    }
}
