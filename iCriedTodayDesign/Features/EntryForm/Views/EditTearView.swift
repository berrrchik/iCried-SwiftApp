import SwiftUI
import SwiftData

struct EditTearView: View {
    let availableTags: [TagItem]
    let availableEmojiIntensities: [EmojiIntensity]
    let entry: TearEntry
    let onSave: (UUID, Date, EmojiIntensity?, TagItem?, String) -> Void
    
    var body: some View {
        TearFormView(
            availableTags: availableTags,
            availableEmojiIntensities: availableEmojiIntensities,
            selectedDate: entry.date,
            selectedEmoji: entry.emojiId,
            selectedTag: entry.tagId,
            note: entry.note,
            title: "Редактировать",
            onSave: { newDate, newEmojiId, newTagId, newNote in
                onSave(entry.id, newDate, newEmojiId, newTagId, newNote)
            }
        )
    }
}
