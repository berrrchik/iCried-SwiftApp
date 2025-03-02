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
                    
                    ColorPicker("Цвет", selection: $color)
                }
                
                Section {
                    HStack {
                        Text("Предпросмотр")
                        Spacer()
                        Text(emoji)
                            .font(.title)
                        Rectangle()
                            .fill(color)
                            .frame(width: 30, height: 20)
                            .cornerRadius(4)
                    }
                }
            }
            .navigationTitle("Редактировать эмодзи")
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
        }
    }
    
    private func saveChanges() {
        let updatedEmoji = EmojiIntensity(emoji: emoji, color: color)
        dataManager.updateEmojiIntensity(updatedEmoji, at: emojiIndex)
    }
}

#Preview {
    EditEmojiView(dataManager: TearDataManager(), emojiIndex: 0)
} 
