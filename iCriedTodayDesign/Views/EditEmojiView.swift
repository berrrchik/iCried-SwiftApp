import SwiftUI

struct EditEmojiView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var dataManager: TearDataManager
    let emojiIndex: Int
    
    @State private var emoji: String
    @State private var color: Color
    @State private var opacity: Double
    
    init(dataManager: TearDataManager, emojiIndex: Int) {
        self.dataManager = dataManager
        self.emojiIndex = emojiIndex
        
        let emojiIntensity = dataManager.emojiIntensities[emojiIndex]
        _emoji = State(initialValue: emojiIntensity.emoji)
        _color = State(initialValue: emojiIntensity.color)
        _opacity = State(initialValue: emojiIntensity.opacity)
    }
    
    var body: some View {
        Form {
            Section {
                VStack(spacing: 20) {
                    Text(emoji)
                        .font(.system(size: 80))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                    
                    TextField("Эмодзи", text: $emoji)
                        .font(.title)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .onChange(of: emoji) { newValue in
                            if newValue.count > 1 {
                                emoji = String(newValue.prefix(1))
                            }
                        }
                }
            } header: {
                Text("Эмодзи")
            }
            
            Section {
                VStack(spacing: 16) {
                    ColorPicker("Выберите цвет", selection: $color, supportsOpacity: false)
                        .padding(.vertical, 8)
                    
                    VStack(spacing: 8) {
                        HStack {
                            Text("Прозрачность")
                            Spacer()
                            Text("\(Int(opacity * 100))%")
                                .foregroundColor(.secondary)
                        }
                        
                        Slider(value: $opacity, in: 0.1...1.0) { editing in
                            // Добавить haptic feedback при необходимости
                        }
                    }
                }
            } header: {
                Text("Настройка цвета")
            }
            
            Section {
                HStack(spacing: 16) {
                    Text("Предпросмотр")
                    Spacer()
                    Text(emoji)
                        .font(.title)
                    Circle()
                        .fill(color.opacity(opacity))
                        .frame(width: 35, height: 35)
                }
                .padding(.vertical, 8)
            }
        }
        .navigationTitle("Редактировать эмодзи")
        .navigationBarTitleDisplayMode(.inline)
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
    
    private func saveChanges() {
        var updatedEmoji = EmojiIntensity(emoji: emoji, color: color, opacity: opacity)
        updatedEmoji.id = dataManager.emojiIntensities[emojiIndex].id
        dataManager.updateEmojiIntensity(updatedEmoji, at: emojiIndex)
    }
}

#Preview {
    EditEmojiView(dataManager: TearDataManager(), emojiIndex: 0)
}
