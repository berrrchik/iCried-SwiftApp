import SwiftUI
import SwiftData

struct AddTearView: View {
    @Bindable var dataManager: TearDataManager
    
    var body: some View {
        TearFormView(
            dataManager: dataManager,
            selectedDate: Date(),
            selectedEmojiId: dataManager.emojiIntensities[0].id,
            selectedTagId: nil,
            note: "",
            title: "Новая запись",
            onSave: { entry in
                dataManager.addEntry(entry)
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

