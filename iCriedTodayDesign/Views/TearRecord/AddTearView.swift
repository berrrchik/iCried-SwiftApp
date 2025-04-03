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
    do {
        let container = try ModelContainer(for: TearEntry.self, EmojiIntensity.self, TagItem.self)
        let modelContext = ModelContext(container)
        let dataManager = TearDataManager(modelContext: modelContext)
        return AddTearView(dataManager: dataManager)
    } catch {
        return Text("Ошибка при создании ModelContainer: \(error.localizedDescription)")
    }
}

