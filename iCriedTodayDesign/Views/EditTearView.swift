import SwiftUI

struct EditTearView: View {
    @ObservedObject var dataManager: TearDataManager
    let entry: TearEntry
    @State private var showingDeleteAlert = false
    
    var body: some View {
        TearFormView(
            dataManager: dataManager,
            selectedDate: entry.date,
            selectedIntensity: entry.intensity,
            selectedTags: entry.tags,
            note: entry.note,
            title: "Редактировать"
        ) { updatedEntry in
            let finalEntry = TearEntry(
                id: entry.id,
                date: updatedEntry.date,
                intensity: updatedEntry.intensity,
                tags: updatedEntry.tags,
                note: updatedEntry.note
            )
            dataManager.updateEntry(finalEntry)
        }
    }
}

#Preview {
    EditTearView(dataManager: TearDataManager(), entry: TearEntry())
}
