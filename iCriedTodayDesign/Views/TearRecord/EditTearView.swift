import SwiftUI
import SwiftData

struct EditTearView: View {
    @Bindable var dataManager: TearDataManager
    let entry: TearEntry
    
    var body: some View {
        TearFormView(
            dataManager: dataManager,
            selectedDate: entry.date,
            selectedEmojiId: entry.emojiId,
            selectedTagId: entry.tagId,
            note: entry.note,
            title: "Редактировать",
            onSave: { updatedEntry in
                var newEntry = updatedEntry
                newEntry.id = entry.id 
                dataManager.updateEntry(newEntry)
            }
        )
    }
}
