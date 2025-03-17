import SwiftUI

struct AddEmojiView: View {
    @ObservedObject var dataManager: TearDataManager
    @Binding var isPresented: Bool
    @State private var newEmoji = ""
    @State private var selectedColor = Color.blue
    @State private var opacity: Double = 1.0
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack {
                        Text(newEmoji)
                            .font(.system(size: 80))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                        TextField("Эмодзи", text: $newEmoji)
                            .font(.title3)
                            .multilineTextAlignment(.center)
                            .onChange(of: newEmoji) { newValue in
                                if newValue.count > 1 {
                                    newEmoji = String(newValue.prefix(1))
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                } header: {
                    Text("Эмодзи")
                }
                Section {
                    ColorPicker("Выберите цвет", selection: $selectedColor, supportsOpacity: false)
                        .padding(.vertical, 16)
                    
                    VStack(spacing: 8) {
                        HStack {
                            Text("Прозрачность")
                            Spacer()
                            Text("\(Int(opacity * 100))%")
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $opacity, in: 0.1...1.0)
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Настройка цвета")
                }
                Section {
                    HStack(spacing: 16) {
                        Text("Предпросмотр")
                        Spacer()
                        Text(newEmoji)
                            .font(.title)
                        Circle()
                            .fill(selectedColor.opacity(opacity))
                            .frame(width: 35, height: 35)
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .navigationTitle("Добавить эмодзи")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Отмена") {
                    isPresented = false
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Добавить") {
                    addEmoji()
                }
                .disabled(newEmoji.isEmpty)
            }
        }
    }
    
    private func addEmoji() {
        let emoji = EmojiIntensity(emoji: newEmoji, color: selectedColor, opacity: opacity)
        dataManager.addEmojiIntensity(emoji)
        isPresented = false
    }
}

#Preview {
    NavigationStack {
        AddEmojiView(dataManager: TearDataManager(), isPresented: .constant(true))
    }
}
