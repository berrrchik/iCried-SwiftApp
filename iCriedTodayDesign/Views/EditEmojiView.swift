import SwiftUI

struct EditEmojiView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var dataManager: TearDataManager
    let emojiIndex: Int
    
    @State private var emoji: String
    @State private var color: Color
    
    init(dataManager: TearDataManager, emojiIndex: Int) {
        self.dataManager = dataManager
        self.emojiIndex = emojiIndex
        
        let emojiIntensity = dataManager.emojiIntensities[emojiIndex]
        _emoji = State(initialValue: emojiIntensity.emoji)
        _color = State(initialValue: emojiIntensity.color)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Эмодзи", text: $emoji)
                        .onChange(of: emoji) { newValue in
                            if newValue.count > 1 {
                                emoji = String(newValue.prefix(1))
                            }
                        }
                        .font(.title)
                    
                    ColorPicker("Цвет", selection: $color)
                }
                
                Section {
                    HStack {
                        Text("Предпросмотр")
                        Spacer()
                        Text(emoji)
                            .font(.title)
                        Circle()
                            .fill(color)
                            .frame(width: 30, height: 30)
                            .cornerRadius(4)
                    }
                }
                
            }
            .navigationTitle("Редактировать")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Сохранить") {
                        saveChanges()
                        dismiss()
                    }
                    .disabled(emoji.isEmpty)
                }
            }
            .navigationBarBackButtonHidden()

        }
    }
    
    private func saveChanges() {
        var updatedEmoji = EmojiIntensity(emoji: emoji, color: color)
        updatedEmoji.id = dataManager.emojiIntensities[emojiIndex].id
        dataManager.updateEmojiIntensity(updatedEmoji, at: emojiIndex)
    }
}

#Preview {
    EditEmojiView(dataManager: TearDataManager(), emojiIndex: 0)
} 
