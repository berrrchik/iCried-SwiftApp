import SwiftUI

struct TagManagementView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var dataManager: TearDataManager
    @State private var showingAddTagSheet = false
    @State private var showingEditTagSheet = false
    @State private var tagToEdit: TagItem?
    @State private var showingAlert = false
    @State private var tagToDelete: TagItem?
    @State private var isEditing = false
    
    var body: some View {
        NavigationStack {
            VStack() {
                existingTagsSection
            }
            .navigationTitle("Управление тегами")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing:4) {
                            Image(systemName: "chevron.left")
                                .font(.title3)
                                .fontWeight(.semibold)
                            Text("Назад")
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingAddTagSheet = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                            .font(.title2)
                    }
                }
            }
            .navigationBarBackButtonHidden(true)
            .sheet(isPresented: $showingAddTagSheet) {
                AddTagView(dataManager: dataManager, isPresented: $showingAddTagSheet)
            }
            .sheet(item: $tagToEdit) { tag in
                EditTagView(dataManager: dataManager, isPresented: $showingEditTagSheet, tag: tag)
            }
            .alert("Удалить тег?", isPresented: $showingAlert) {
                Button("Отмена", role: .cancel) { }
                Button("Удалить", role: .destructive) {
                    if let tag = tagToDelete {
                        dataManager.removeTag(tag.id)
                    }
                    tagToDelete = nil
                }
            } message: {
                if let tag = tagToDelete {
                    Text("Тег \(tag.name) будет удален из всех записей")
                }
            }
            .environment(\.editMode, Binding(
                get: { isEditing ? .active : .inactive },
                set: { newValue in
                    isEditing = newValue == .active
                }
            ))
            
        }
    }
    
    private var existingTagsSection: some View {
        List {
            Section(header: customHeader, footer: footerView) {
                if dataManager.tags.isEmpty {
                    Text("Нет добавленных тегов")
                        .foregroundColor(.gray)
                } else {
                    ForEach(dataManager.tags.indices, id: \.self) { index in
                        let tag = dataManager.tags[index]
                        HStack {
                            Text("\(index + 1)")
                                .foregroundColor(.secondary)
                                .font(.caption)
                            Text(tag.name)
                            Spacer()
                            if !isEditing {
                                Button {
                                    tagToEdit = tag
                                    showingEditTagSheet = true
                                } label: {
                                }
                            }
                        }
                        .swipeActions(allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                tagToDelete = tag
                                showingAlert = true
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .onMove { indices, destination in
                        dataManager.moveTag(from: indices, to: destination)
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
    
    private var footerView: some View {
        Group {
            if isEditing {
                Text("Перетащите теги, чтобы изменить их порядок")
            }
        }
    }
    
    private var customHeader: some View {
        HStack {
            Text("Теги")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            Spacer()
            Button(action: {
                isEditing.toggle()
            }) {
                Text(isEditing ? "Готово" : "Редактировать")
                    .foregroundColor(.blue)
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(.horizontal)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    NavigationStack {
        TagManagementView(dataManager: TearDataManager())
    }
}
