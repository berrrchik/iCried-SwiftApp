import SwiftUI
import SwiftData

struct EmojiManagementView: View {
    @Bindable var dataManager: TearDataManager
    @State private var showingAlert = false
    @State private var emojiToDeleteIndex: Int?
    @State private var showingAddEmojiSheet = false
    @State private var showingEditEmojiSheet = false
    @State private var isEditing = false
    @State private var emojiToEdit: EmojiIntensity?
    
    var body: some View {
        VStack(spacing: 16) {
            existingEmojiSection
        }
        .padding(.vertical, 1)
        .navigationTitle("Управление эмодзи")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showingAddEmojiSheet = true } label: {
                    Image(systemName: "plus.circle.fill").font(.title2)
                }
            }
        }
        .sheet(isPresented: $showingAddEmojiSheet) {
            NavigationStack {
                AddEmojiView(dataManager: dataManager, isPresented: $showingAddEmojiSheet)
            }
        }
        .sheet(item: $emojiToEdit) { emoji in
            EditEmojiView(dataManager: dataManager, isPresented: $showingEditEmojiSheet, emojiIntensity: emoji)
        }
        .alert("Удалить эмодзи?", isPresented: $showingAlert) {
            Button("Отмена", role: .cancel) { }
            Button("Удалить", role: .destructive) {
                if let index = emojiToDeleteIndex {
                    dataManager.removeEmojiIntensity(at: index)
                }
                emojiToDeleteIndex = nil
            }
        } message: {
            Text("Эмодзи будет удален из всех записей")
        }
        .environment(\.editMode, Binding(
            get: { isEditing ? .active : .inactive },
            set: { newValue in
                isEditing = newValue == .active
            }
        ))
    }
    
    private var existingEmojiSection: some View {
        List {
            Section(header: customHeader, footer: footerView) {
                if dataManager.emojiIntensities.isEmpty {
                    Text("Нет добавленных эмодзи")
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else {
                    ForEach(dataManager.emojiIntensities.indices, id: \.self) { index in
                        let emoji = dataManager.emojiIntensities[index]
                        HStack(spacing: 16) {
                            Text("\(index + 1)")
                                .foregroundColor(.secondary)
                                .font(.caption)
                                .frame(width: 24)
                            EmojiCell(emoji: emoji)
                            Spacer()
                            if !isEditing {
                                Button {
                                    emojiToEdit = emoji
                                    showingEditEmojiSheet = true
                                } label: {
                                    Image(systemName: "pencil")
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .swipeActions(allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                emojiToDeleteIndex = index
                                showingAlert = true
                            } label: {
                                Label("Удалить", systemImage: "trash")
                            }
                            .disabled(dataManager.emojiIntensities.count <= 1)
                        }
                    }
                    .onMove { indices, destination in
                        dataManager.moveEmojiIntensity(from: indices, to: destination)
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
    
    private var footerView: some View {
        Group {
            if isEditing {
                Text("Перетащите эмодзи, чтобы изменить их порядок")
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
