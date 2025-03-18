import SwiftUI

struct AddTagView: View {
    @ObservedObject var dataManager: TearDataManager
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

#Preview {
    NavigationStack {
        AddTagView(dataManager: TearDataManager(), isPresented: .constant(true))
    }
}
