import SwiftUI
import SwiftData

struct EditEmojiView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var isPresented: Bool
    var emojiIntensity: EmojiIntensity
    let existingEmojiIntensities: [EmojiIntensity]
    let onSave: (EmojiIntensity, Int) -> Void
    
    @State private var emoji: String
    @State private var color: Color
    @State private var opacity: Double
    
    init(isPresented: Binding<Bool>, emojiIntensity: EmojiIntensity, existingEmojiIntensities: [EmojiIntensity], onSave: @escaping (EmojiIntensity, Int) -> Void) {
        self._isPresented = isPresented
        self.emojiIntensity = emojiIntensity
        self.existingEmojiIntensities = existingEmojiIntensities
        self.onSave = onSave
        
        _emoji = State(initialValue: emojiIntensity.emoji)
        _color = State(initialValue: emojiIntensity.color)
        _opacity = State(initialValue: emojiIntensity.opacity)
    }
    
    var body: some View {
        NavigationStack {
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
                            
                            Slider(value: $opacity, in: 0.1...1.0)
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
                
                ToolbarItem(placement: .topBarTrailing) {
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
        var updatedEmoji = EmojiIntensity(emoji: emoji, color: color, opacity: opacity)
        updatedEmoji.id = emojiIntensity.id
        if let index = existingEmojiIntensities.firstIndex(where: { $0.id == emojiIntensity.id }) {
            onSave(updatedEmoji, index)
            isPresented = false
        }
    }
}

//struct EditEmojiView_Previews: PreviewProvider {
//    static var previews: some View {
//        let mockEmojiIntensity = EmojiIntensity(emoji: "🥲", color: .blue, opacity: 0.8)
//        let mockDataManager = TearDataManager(modelContext: ModelContext(ModelContainer()))
//        return EditEmojiView(dataManager: mockDataManager, isPresented: .constant(true), emojiIntensity: mockEmojiIntensity)
//    }
//}
