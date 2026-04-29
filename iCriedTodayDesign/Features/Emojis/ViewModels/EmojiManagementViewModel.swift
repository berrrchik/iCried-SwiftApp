import Foundation
import Combine

@MainActor
final class EmojiManagementViewModel: ObservableObject {
    @Published private(set) var emojiIntensities: [EmojiIntensity] = []
    @Published var showingAddEmojiSheet = false
    @Published var isEditing = false
    @Published private(set) var emojiToEdit: EmojiIntensity?
    @Published private(set) var emojiToDeleteIndex: Int?
    @Published var showingDeleteAlert = false
    
    private let dataManager: TearDataManager
    
    init(dataManager: TearDataManager) {
        self.dataManager = dataManager
        syncFromDataManager()
    }
    
    var footerText: String? {
        isEditing ? "Перетащите эмодзи, чтобы изменить их порядок" : nil
    }
    
    var canDeleteSelectedEmoji: Bool {
        emojiIntensities.count > 1
    }
    
    func syncFromDataManager() {
        emojiIntensities = dataManager.emojiIntensities
    }
    
    func toggleEditing() {
        isEditing.toggle()
    }
    
    func presentEdit(for emoji: EmojiIntensity) {
        emojiToEdit = emoji
    }
    
    func dismissEdit() {
        emojiToEdit = nil
    }
    
    func presentDelete(at index: Int) {
        emojiToDeleteIndex = index
        showingDeleteAlert = true
    }
    
    func dismissDelete() {
        emojiToDeleteIndex = nil
        showingDeleteAlert = false
    }
    
    func confirmDelete() {
        guard let emojiToDeleteIndex else { return }
        dataManager.removeEmojiIntensity(at: emojiToDeleteIndex)
        syncFromDataManager()
        dismissDelete()
    }
    
    func moveEmojis(from source: IndexSet, to destination: Int) {
        dataManager.moveEmojiIntensity(from: source, to: destination)
        syncFromDataManager()
    }
}
