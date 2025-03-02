import SwiftUI

struct EmojiManagementView: View {
    @ObservedObject var dataManager: TearDataManager
    @State private var newEmoji = ""
    @State private var selectedColor = Color.blue
    @State private var showingAlert = false
    @State private var emojiToDeleteIndex: Int?
    @State private var editingEmojiIndex: Int?
    @State private var showingEditSheet = false
    
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
                            .font(.title2)
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
                    ForEach(Array(dataManager.emojiIntensities.enumerated()), id: \.element.id) { index, emoji in
                        NavigationLink {
                            EditEmojiView(dataManager: dataManager, emojiIndex: index)
                        } label: {
                            HStack {
                                Text(emoji.emoji)
                                    .font(.title)
                                
                                Rectangle()
                                    .fill(emoji.color)
                                    .frame(width: 30, height: 20)
                                    .cornerRadius(4)
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
                }
            } header: {
                Text("Существующие эмодзи")
            }
        }
        .navigationTitle("Управление эмодзи")
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
