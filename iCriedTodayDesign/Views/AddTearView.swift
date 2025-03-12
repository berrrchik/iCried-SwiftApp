import SwiftUI

struct AddTearView: View {
    @ObservedObject var dataManager: TearDataManager
    
    var body: some View {
        TearFormView(
            dataManager: dataManager,
            selectedDate: Date(),
            selectedEmojiId: dataManager.emojiIntensities[0].id,
            selectedTagId: dataManager.tags[0].id, //не должен выбираться первый хештег, пофиксить
            note: "",
            title: "Новая запись",
            onSave: { entry in
                dataManager.addEntry(entry)
            }
        )
    }
}

#Preview {
    AddTearView(dataManager: TearDataManager())
}
