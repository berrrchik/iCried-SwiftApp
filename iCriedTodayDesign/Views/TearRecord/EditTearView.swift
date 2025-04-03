import SwiftUI
import SwiftData

struct EditTearView: View {
    @Bindable var dataManager: TearDataManager
    let entry: TearEntry
    
    var body: some View {
        TearFormView(
            dataManager: dataManager,
            selectedDate: entry.date,
            selectedEmoji: entry.emojiId,
            selectedTag: entry.tagId,
            note: entry.note,
            title: "Редактировать",
            onSave: { newDate, newEmojiId, newTagId, newNote in
                do {
                    try dataManager.updateEntry(
                        withId: entry.id,
                        newDate: newDate,
                        newEmojiId: newEmojiId,
                        newTagId: newTagId,
                        newNote: newNote
                    )
                } catch {
                    print("Ошибка обновления записи: \(error)")
                }
            }
        )
    }
}
