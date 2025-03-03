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
                HStack {
                    TextField("Новый эмодзи", text: $newEmoji)
                        .onChange(of: newEmoji) { newValue in
                            if newValue.count > 1 {
                                newEmoji = String(newValue.prefix(1))
                            }
                        }
                    
                    ColorPicker("", selection: $selectedColor)
                        .labelsHidden()
                    
                    Button {
                        addEmoji()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                            .font(.title)
                    }
                    .disabled(newEmoji.isEmpty)
                }
            } header: {
                Text("Добавить эмодзи")
            } footer: {
                Text("Выберите один символ эмодзи и его цвет")
            }
            
            Section {
                if dataManager.emojiIntensities.isEmpty {
                    Text("Нет добавленных эмодзи")
                        .foregroundColor(.gray)
                } else {
                    ForEach(dataManager.emojiIntensities) { emoji in
                        if isEditing {
                            HStack {
                                Text("\(dataManager.emojiIntensities.firstIndex(where: { $0.id == emoji.id })! + 1)")
                                    .foregroundColor(.gray)
                                    .font(.caption)
                                Text(emoji.emoji)
                                    .font(.largeTitle)
                                
                                Circle()
                                    .fill(emoji.color)
                                    .frame(width: 30, height: 30)
                                    .cornerRadius(4)
                            }
                        } else {
                            NavigationLink {
                                if let index = dataManager.emojiIntensities.firstIndex(where: { $0.id == emoji.id }) {
                                    EditEmojiView(dataManager: dataManager, emojiIndex: index)
                                }
                            } label: {
                                HStack {
                                    Text("\(dataManager.emojiIntensities.firstIndex(where: { $0.id == emoji.id })! + 1)")
                                        .foregroundColor(.gray)
                                        .font(.caption)
                                    Text(emoji.emoji)
                                        .font(.largeTitle)
                                    
                                    Circle()
                                        .fill(emoji.color)
                                        .frame(width: 30, height: 30)
                                        .cornerRadius(4)
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
                        print("Перемещение из \(indices) в \(destination)")
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

#Preview {
    NavigationView {
        EmojiManagementView(dataManager: TearDataManager())
    }
}
