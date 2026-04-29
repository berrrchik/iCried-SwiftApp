import Foundation
import Combine

@MainActor
final class TagManagementViewModel: ObservableObject {
    @Published private(set) var tags: [TagItem] = []
    @Published var showingAddTagSheet = false
    @Published var isEditing = false
    @Published private(set) var tagToEdit: TagItem?
    @Published private(set) var tagToDelete: TagItem?
    @Published var showingDeleteAlert = false
    
    private let dataManager: TearDataManager
    
    init(dataManager: TearDataManager) {
        self.dataManager = dataManager
        syncFromDataManager()
    }
    
    var footerText: String? {
        isEditing ? "Перетащите теги, чтобы изменить их порядок" : nil
    }
    
    var deleteMessage: String {
        guard let tagToDelete else { return "" }
        return "Тег \(tagToDelete.name) будет удален из всех записей"
    }
    
    func syncFromDataManager() {
        tags = dataManager.tags
    }
    
    func toggleEditing() {
        isEditing.toggle()
    }
    
    func presentEdit(for tag: TagItem) {
        tagToEdit = tag
    }
    
    func dismissEdit() {
        tagToEdit = nil
    }
    
    func presentDelete(for tag: TagItem) {
        tagToDelete = tag
        showingDeleteAlert = true
    }
    
    func dismissDelete() {
        tagToDelete = nil
        showingDeleteAlert = false
    }
    
    func confirmDelete() {
        guard let tagToDelete else { return }
        dataManager.removeTag(tagToDelete.id)
        syncFromDataManager()
        dismissDelete()
    }
    
    func moveTags(from source: IndexSet, to destination: Int) {
        dataManager.moveTag(from: source, to: destination)
        syncFromDataManager()
    }
}
