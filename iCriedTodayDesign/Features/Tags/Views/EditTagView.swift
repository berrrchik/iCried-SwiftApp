import SwiftUI
import SwiftData

struct EditTagView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var isPresented: Bool
    var tag: TagItem
    let onSave: (UUID, String) -> Void
    @State private var editedTag = ""
    
    var body: some View {
        NavigationStack {
            VStack {
                TextField("Редактировать тег", text: $editedTag)
                    .font(.title3)
                    .textInputAutocapitalization(.never)
                    .onAppear {
                        editedTag = tag.name
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Редактировать тег")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Сохранить") {
                        saveTag()
                        dismiss()
                    }
                    .disabled(editedTag.count < 2)
                }
            }
        }
    }
    
    private func saveTag() {
        let updatedTag = editedTag.trimmingCharacters(in: .whitespaces)
        if updatedTag.count >= 2 {
            onSave(tag.id, updatedTag)
            isPresented = false
        }
    }
}

//#Preview {
//    let config = ModelConfiguration(isStoredInMemoryOnly: true)
//    let container = try! ModelContainer(for: TagItem.self, EmojiIntensity.self, TearEntry.self, configurations: config)
//    
//    NavigationStack {
//        EditTagView(dataManager: TearDataManager(modelContext: ModelContext(container)), isPresented: .constant(true), tag: TagItem(name: "хештег"))
//    }
//}
