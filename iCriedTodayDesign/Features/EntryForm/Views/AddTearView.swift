import SwiftUI
import SwiftData

struct AddTearView: View {
    let availableTags: [TagItem]
    let availableEmojiIntensities: [EmojiIntensity]
    let onSave: (TearEntry) -> Void
    
    var body: some View {
        TearFormView(
            availableTags: availableTags,
            availableEmojiIntensities: availableEmojiIntensities,
            title: "Добавить запись",
            onSave: { newDate, newEmojiId, newTagId, newNote in
                let newEntry = TearEntry(
                    date: newDate,
                    emojiId: newEmojiId,
                    tagId: newTagId,
                    note: newNote
                )
                onSave(newEntry)
            }
        )
    }
}

#Preview {
    let previewManager = makePreviewDataManager()
    AddTearView(
        availableTags: previewManager.tags,
        availableEmojiIntensities: previewManager.emojiIntensities,
        onSave: { _ in }
    )
}
