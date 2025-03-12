import SwiftUI

struct TearFormView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var dataManager: TearDataManager
    
    @State var selectedDate: Date
    @State var selectedEmojiId: UUID
    @State var selectedTagId: UUID
    @State var note: String
    
    let title: String
    let onSave: (TearEntry) -> Void
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    noteSection
                    tagsSection
                    intensitySection
                    dateSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Сохранить") {
                        let entry = TearEntry(
                            date: selectedDate,
                            emojiId: selectedEmojiId,
                            tagId: selectedTagId,
                            note: note
                        )
                        onSave(entry)
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
        }
    }
    
    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Что случилось?")
                .font(.headline)
            
            TextEditor(text: $note)
                .frame(height: 100)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.1), radius: 5)
                )
        }
    }
    
    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Причина")
                .font(.headline)
            
            FlowLayout(spacing: 12) {
                ForEach(dataManager.tags) { tag in
                    TagButton(
                        tagName: tag.name,
                        isSelected: selectedTagId == tag.id,
                        action: {
                            selectedTagId = tag.id
                        }
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private var intensitySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Насколько сильно?")
                .font(.headline)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(dataManager.emojiIntensities) { emojiIntensity in
                        EmojiButton(
                            emoji: emojiIntensity.emoji,
                            count: nil,
                            color: emojiIntensity.color,
                            isSelected: selectedEmojiId == emojiIntensity.id,
                            action: {
                                selectedEmojiId = emojiIntensity.id
                            },
                            isCountVisible: false,
                            fontSize: 40
                        )
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    private var dateSection: some View {
        HStack(spacing: 20) {
            Text("Когда это случилось?")
                .font(.headline)
            
            DatePicker("", selection: $selectedDate, displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(.compact)
                .labelsHidden()
                .padding([.all], 10)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.1), radius: 5)
                )
                .environment(\.locale, Locale(identifier: "ru_RU"))
        }
    }
}
