import SwiftUI
import SwiftData

struct AddTagView: View {
    @Bindable var dataManager: TearDataManager
    @Binding var isPresented: Bool
    @State private var newTag = ""
    
    var body: some View {
        NavigationStack {
            VStack {
                TextField("Новый тег", text: $newTag)
                    .font(.title3)
                    .textInputAutocapitalization(.never)
                    .onChange(of: newTag) { newValue in
                        if !newValue.hasPrefix("#") {
                            newTag = "#" + newValue.trimmingCharacters(in: .whitespaces)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Добавить тег")
            .navigationBarTitleDisplayMode(.inline)
            
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Добавить") {
                        addTag()
                    }
                }
            }
        }
    }
    
    private func addTag() {
        let tag = newTag.trimmingCharacters(in: .whitespaces)
        if tag.count >= 2 {
            dataManager.addTag(tag)
            isPresented = false
        }
    }
}

//#Preview {
//    let config = ModelConfiguration(isStoredInMemoryOnly: true)
//    let container = try! ModelContainer(for: TagItem.self, EmojiIntensity.self, TearEntry.self, configurations: config)
//    
//    return NavigationStack {
//        AddTagView(dataManager: TearDataManager(modelContext: ModelContext(container)), isPresented: .constant(true))
//    }
//}
