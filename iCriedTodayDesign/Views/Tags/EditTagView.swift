import SwiftUI

struct EditTagView: View {
    @ObservedObject var dataManager: TearDataManager
    @Environment(\.dismiss) var dismiss
    @Binding var isPresented: Bool
    var tag: TagItem
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
                    }
                    .disabled(editedTag.count < 2)
                }
            }
        }
    }
    
    private func saveTag() {
        let updatedTag = editedTag.trimmingCharacters(in: .whitespaces)
        if updatedTag.count >= 2 {
            if let index = dataManager.tags.firstIndex(where: { $0.id == tag.id }) {
                var updatedTagItem = tag
                updatedTagItem.name = updatedTag
                dataManager.tags[index] = updatedTagItem
                dataManager.saveTags()
                isPresented = false
            }
        }
    }
}

#Preview {
    NavigationStack {
        EditTagView(dataManager: TearDataManager(), isPresented: .constant(true), tag: TagItem(name: "#Одиночество"))
    }
}
