import Foundation
import Combine

struct TearFormSavePayload {
    let date: Date
    let selectedEmoji: EmojiIntensity?
    let selectedTag: TagItem?
    let note: String
}

@MainActor
final class TearFormViewModel: ObservableObject {
    let availableTags: [TagItem]
    let availableEmojiIntensities: [EmojiIntensity]
    
    @Published var selectedDate: Date
    @Published var selectedEmoji: EmojiIntensity?
    @Published var selectedTag: TagItem?
    @Published var note: String
    
    init(
        availableTags: [TagItem],
        availableEmojiIntensities: [EmojiIntensity],
        selectedDate: Date = Date(),
        selectedEmoji: EmojiIntensity? = nil,
        selectedTag: TagItem? = nil,
        note: String = ""
    ) {
        self.availableTags = availableTags
        self.availableEmojiIntensities = availableEmojiIntensities
        self.selectedDate = selectedDate
        self.selectedEmoji = selectedEmoji ?? availableEmojiIntensities.first
        self.selectedTag = selectedTag
        self.note = note
    }
    
    var trimmedNote: String {
        note.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var isFormValid: Bool {
        !trimmedNote.isEmpty && selectedTag != nil && selectedEmoji != nil
    }
    
    var missingEmojiMessage: String? {
        availableEmojiIntensities.isEmpty ? "Сначала добавьте хотя бы один эмодзи в настройках." : nil
    }
    
    var savePayload: TearFormSavePayload? {
        guard isFormValid else { return nil }
        
        return TearFormSavePayload(
            date: selectedDate,
            selectedEmoji: selectedEmoji,
            selectedTag: selectedTag,
            note: trimmedNote
        )
    }
}
