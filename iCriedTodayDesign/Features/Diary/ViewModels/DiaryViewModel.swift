import Foundation
import Combine

@MainActor
final class DiaryViewModel: ObservableObject {
    @Published private(set) var sections: [DiarySection] = []
    @Published var showingAddTear = false
    @Published var showingDeleteAlert = false
    @Published private(set) var entryToDelete: TearEntry?
    
    private let dataManager: TearDataManager
    
    init(dataManager: TearDataManager) {
        self.dataManager = dataManager
        syncFromDataManager()
    }
    
    func syncFromDataManager() {
        sections = dataManager.groupedEntries
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
}
