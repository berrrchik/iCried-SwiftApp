import SwiftUI
struct AddTearView: View {
    @ObservedObject var dataManager: TearDataManager
    
    var body: some View {
        TearFormView(
            dataManager: dataManager,
            selectedDate: Date(),
            selectedIntensity: 1,
            selectedTags: [],
            note: "",
            title: "Новая запись"
        ) { entry in
            dataManager.addEntry(entry)
        }
    }
} 

