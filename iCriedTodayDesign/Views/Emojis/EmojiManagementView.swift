import SwiftUI
import SwiftData

struct EmojiManagementView: View {
    @Bindable var dataManager: TearDataManager
    @StateObject private var viewModel: EmojiManagementViewModel
    
    init(dataManager: TearDataManager) {
        self.dataManager = dataManager
        _viewModel = StateObject(wrappedValue: EmojiManagementViewModel(dataManager: dataManager))
    }
    
    var body: some View {
        VStack(spacing: 16) {
            existingEmojiSection
        }
        .padding(.vertical, 1)
        .navigationTitle("Управление эмодзи")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { viewModel.showingAddEmojiSheet = true } label: {
                    Image(systemName: "plus.circle.fill").font(.title2)
                }
            }
        }
        .sheet(isPresented: $viewModel.showingAddEmojiSheet) {
            NavigationStack {
                AddEmojiView(dataManager: dataManager, isPresented: $viewModel.showingAddEmojiSheet)
            }
        }
        .sheet(item: Binding(
            get: { viewModel.emojiToEdit },
            set: { _ in viewModel.dismissEdit() }
        )) { emoji in
            EditEmojiView(
                dataManager: dataManager,
                isPresented: Binding(
                    get: { viewModel.emojiToEdit != nil },
                    set: { if !$0 { viewModel.dismissEdit() } }
                ),
                emojiIntensity: emoji
            )
        }
        .alert("Удалить эмодзи?", isPresented: $viewModel.showingDeleteAlert) {
            Button("Отмена", role: .cancel) { }
            Button("Удалить", role: .destructive) {
                viewModel.confirmDelete()
            }
        } message: {
            Text("Эмодзи будет удален из всех записей")
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
    
    private var existingEmojiSection: some View {
        List {
            Section(header: customHeader, footer: footerView) {
                if viewModel.emojiIntensities.isEmpty {
                    Text("Нет добавленных эмодзи")
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else {
                    ForEach(viewModel.emojiIntensities.indices, id: \.self) { index in
                        let emoji = viewModel.emojiIntensities[index]
                        HStack(spacing: 16) {
                            Text("\(index + 1)")
                                .foregroundColor(.secondary)
                                .font(.caption)
                                .frame(width: 24)
                            EmojiCell(emoji: emoji)
                            Spacer()
                            if !viewModel.isEditing {
                                Button {
                                    viewModel.presentEdit(for: emoji)
                                } label: {
                                    Image(systemName: "pencil")
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .swipeActions(allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                viewModel.presentDelete(at: index)
                            } label: {
                                Label("Удалить", systemImage: "trash")
                            }
                            .disabled(!viewModel.canDeleteSelectedEmoji)
                        }
                    }
                    .onMove { indices, destination in
                        viewModel.moveEmojis(from: indices, to: destination)
                    }
                }
            }
        }
    }
    
    private var customHeader: some View {
        HStack {
            Text("Эмодзи")
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
    
    private var footerView: some View {
        Group {
            if let footerText = viewModel.footerText {
                Text(footerText)
            }
        }
    }
    
}

private struct EmojiCell: View {
    let emoji: EmojiIntensity
    
    var body: some View {
        HStack(spacing: 16) {
            Text(emoji.emoji)
                .font(.system(size: 32))
                .frame(width: 60, height: 60)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 4) {
                Circle()
                    .fill(emoji.color)
                    .frame(width: 24, height: 24)
                
                Text("Прозрачность: \(Int(emoji.opacity * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        EmojiManagementView(dataManager: makePreviewDataManager())
    }
}
