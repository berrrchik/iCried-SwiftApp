import SwiftUI
import SwiftData

struct AddTearView: View {
    @Bindable var dataManager: TearDataManager
    
    var body: some View {
        TearFormView(
            dataManager: dataManager,
            title: "Добавить запись",
            onSave: { newDate, newEmojiId, newTagId, newNote in
                let newEntry = TearEntry(
                    date: newDate,
                    emojiId: newEmojiId,
                    tagId: newTagId,
                    note: newNote
                )
                dataManager.addEntry(newEntry)
            }
        )
    }
}

#Preview {
    AddTearView(dataManager: makePreviewDataManager())
}
