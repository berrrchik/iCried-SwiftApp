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

//#Preview {
//    AddTearView(dataManager: TearDataManager(modelContext: ModelContext()))
//}
