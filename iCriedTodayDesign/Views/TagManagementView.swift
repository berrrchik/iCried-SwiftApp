import SwiftUI
struct TagManagementView: View {
    @ObservedObject var dataManager: TearDataManager
    @State private var newTag = ""
    @State private var showingAlert = false
    @State private var tagToDelete: TagItem?
    
    var body: some View {
        List {
            Section {
                HStack {
                    TextField("Новый тег", text: $newTag)
                        .font(.title3)
                        .textInputAutocapitalization(.never)
                        .onChange(of: newTag) { newValue in
                            if !newValue.hasPrefix("#") {
                                newTag = "#" + newValue.trimmingCharacters(in: .whitespaces)
                            }
                        }
                    
                    Button {
                        addTag()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                            .font(.title)
                    }
                    .disabled(newTag.count < 2)
                }
            } header: {
                Text("Добавить тег")
                    .font(.subheadline)
            }
            
            Section {
                if dataManager.tags.isEmpty {
                    Text("Нет добавленных тегов")
                        .foregroundColor(.gray)
                } else {
                    ForEach(dataManager.tags.sorted(by: { $0.name < $1.name })) { tag in
                        HStack {
                            Text(tag.name)
                            Spacer()
                            Button {
                                tagToDelete = tag
                                showingAlert = true
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
            } header: {
                Text("Существующие теги")
                    .font(.subheadline)
            }
        }
        .navigationTitle("Управление тегами")
        .alert("Удалить тег?", isPresented: $showingAlert) {
            Button("Отмена", role: .cancel) { }
            Button("Удалить", role: .destructive) {
                if let tag = tagToDelete {
                    dataManager.removeTag(tag.id)
                }
                tagToDelete = nil
            }
        } message: {
            //при удалении хештега записи присваивается другой хештег, пофиксить
            if let tag = tagToDelete {
                Text("Тег \(tag.name) будет удален из всех записей")
            }
        }
    }
    
    private func addTag() {
        let tag = newTag.trimmingCharacters(in: .whitespaces)
        if tag.count >= 2 {
            dataManager.addTag(tag)
            newTag = ""
        }
    }
}
