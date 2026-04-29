import SwiftUI
import SwiftData

struct TagManagementView: View {
    @ObservedObject var dataManager: TearDataManager
    @StateObject private var viewModel: TagManagementViewModel
    
    init(dataManager: TearDataManager) {
        self.dataManager = dataManager
        _viewModel = StateObject(wrappedValue: TagManagementViewModel(dataManager: dataManager))
    }
    
    var body: some View {
        VStack {
            existingTagsSection
        }
        .padding(.vertical, 1)
        .navigationTitle("Управление тегами")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { viewModel.showingAddTagSheet = true }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                }
            }
        }
        .sheet(isPresented: $viewModel.showingAddTagSheet) {
            AddTagView(
                isPresented: $viewModel.showingAddTagSheet,
                onAdd: { tag in
                    viewModel.addTag(tag)
                }
            )
        }
        .sheet(item: Binding(
            get: { viewModel.tagToEdit },
            set: { _ in viewModel.dismissEdit() }
        )) { tag in
            EditTagView(
                isPresented: Binding(
                    get: { viewModel.tagToEdit != nil },
                    set: { if !$0 { viewModel.dismissEdit() } }
                ),
                tag: tag,
                onSave: { tagID, name in
                    viewModel.saveTag(id: tagID, name: name)
                }
            )
        }
        .alert("Удалить тег?", isPresented: $viewModel.showingDeleteAlert) {
            Button("Отмена", role: .cancel) { }
            Button("Удалить", role: .destructive) {
                viewModel.confirmDelete()
            }
        } message: {
            Text(viewModel.deleteMessage)
        }
        .environment(\.editMode, Binding(
            get: { viewModel.isEditing ? .active : .inactive },
            set: { newValue in
                viewModel.isEditing = newValue == .active
            }
        ))
        .onAppear {
            viewModel.syncFromDataManager()
        }
        .onChange(of: dataManager.refreshTrigger) { _ in
            viewModel.syncFromDataManager()
        }
    }
    
    private var existingTagsSection: some View {
        List {
            Section(header: customHeader, footer: footerView) {
                if viewModel.tags.isEmpty {
                    Text("Нет добавленных тегов")
                        .foregroundColor(.gray)
                } else {
                    ForEach(viewModel.tags.indices, id: \.self) { index in
                        let tag = viewModel.tags[index]
                        HStack {
                            Text("\(index + 1)")
                                .foregroundColor(.secondary)
                                .font(.caption)
                            Text(tag.name)
                            Spacer()
                            if !viewModel.isEditing {
                                Button {
                                    viewModel.presentEdit(for: tag)
                                } label: {
                                    Image(systemName: "pencil")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .swipeActions(allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                viewModel.presentDelete(for: tag)
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .onMove { indices, destination in
                        viewModel.moveTags(from: indices, to: destination)
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
    
    private var footerView: some View {
        Group {
            if let footerText = viewModel.footerText {
                Text(footerText)
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
                viewModel.toggleEditing()
            }) {
                Text(viewModel.isEditing ? "Готово" : "Редактировать")
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
        TagManagementView(dataManager: makePreviewDataManager())
    }
}
