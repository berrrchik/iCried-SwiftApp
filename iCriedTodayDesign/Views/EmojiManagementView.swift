import SwiftUI

struct EmojiManagementView: View {
    @ObservedObject var dataManager: TearDataManager
    @State private var newEmoji = ""
    @State private var selectedColor = Color.blue
    @State private var showingAlert = false
    @State private var emojiToDeleteIndex: Int?
    @State private var editingEmojiIndex: Int?
    @State private var showingEditSheet = false
    @State private var isEditing = false
    
    var body: some View {
        List {
            Section {
                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        TextField("", text: $newEmoji)
                            .font(.system(size: 30))
                            .frame(width: 80)
                            .multilineTextAlignment(.center)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .onChange(of: newEmoji) { newValue in
                                if newValue.count > 1 {
                                    newEmoji = String(newValue.prefix(1))
                                }
                            }
                        
                        VStack(alignment: .leading) {
                            
                            ColorPicker("", selection: $selectedColor, supportsOpacity: false)
                                .labelsHidden()
                                .scaleEffect(CGSize(width: 1.2, height: 1.2))
                        }
                        
                        Spacer()
                        
                        Button {
                            withAnimation {
                                addEmoji()
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.blue)
                        }
                        .disabled(newEmoji.isEmpty)
                    }
                }
                .padding(.vertical, 1)
            } header: {
                Text("Добавить эмодзи")
            } footer: {
                Text("Выберите один эмодзи и цвет для него")
            }
            
            Section {
                if dataManager.emojiIntensities.isEmpty {
                    Text("Нет добавленных эмодзи")
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else {
                    ForEach(dataManager.emojiIntensities) { emoji in
                        if isEditing {
                            HStack(spacing: 16) {
                                Text("\(dataManager.emojiIntensities.firstIndex(where: { $0.id == emoji.id })! + 1)")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                                    .frame(width: 24)
                                
                                EmojiCell(emoji: emoji)
                            }
                        } else {
                            NavigationLink {
                                if let index = dataManager.emojiIntensities.firstIndex(where: { $0.id == emoji.id }) {
                                    EditEmojiView(dataManager: dataManager, emojiIndex: index)
                                }
                            } label: {
                                HStack(spacing: 16) {
                                    Text("\(dataManager.emojiIntensities.firstIndex(where: { $0.id == emoji.id })! + 1)")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                        .frame(width: 24)
                                    
                                    EmojiCell(emoji: emoji)
                                }
                            }
                            .swipeActions(allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    if let index = dataManager.emojiIntensities.firstIndex(where: { $0.id == emoji.id }) {
                                        emojiToDeleteIndex = index
                                        showingAlert = true
                                    }
                                } label: {
                                    Label("Удалить", systemImage: "trash")
                                }
                                .disabled(dataManager.emojiIntensities.count <= 1)
                            }
                        }
                    }
                    .onMove { indices, destination in
                        dataManager.moveEmojiIntensity(from: indices, to: destination)
                    }
                }
            } header: {
                Text("Существующие эмодзи")
            } footer: {
                isEditing ? Text("Перетащите эмодзи, чтобы изменить их порядок") : nil
            }
        }
        .navigationTitle("Управление эмодзи")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
                    .onChange(of: isEditing) { _ in
                        // Обновляем UI при изменении режима редактирования
                        dataManager.objectWillChange.send()
                    }
            }
        }
        .environment(\.editMode, Binding(
            get: { isEditing ? .active : .inactive },
            set: { newValue in
                isEditing = newValue == .active
            }
        ))
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
    }
    
    private func addEmoji() {
        if !newEmoji.isEmpty {
            let emoji = EmojiIntensity(emoji: newEmoji, color: selectedColor)
            dataManager.addEmojiIntensity(emoji)
            newEmoji = ""
            selectedColor = .blue
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
    NavigationView {
        EmojiManagementView(dataManager: TearDataManager())
    }
}
