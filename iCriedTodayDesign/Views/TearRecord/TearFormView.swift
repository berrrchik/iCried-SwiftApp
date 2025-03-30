import SwiftUI
import SwiftData

struct TearFormView: View {
    @Environment(\.dismiss) var dismiss
    @Bindable var dataManager: TearDataManager

    @State var selectedDate: Date
    @State var selectedEmoji: EmojiIntensity?
    @State var selectedTag: TagItem?          
    @State var note: String
    
    let title: String
    let onSave: (TearEntry) -> Void
    
    var isFormValid: Bool {
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedNote.isEmpty && selectedTag != nil
    }
    
    init(dataManager: TearDataManager,
         selectedDate: Date = Date(),
         selectedEmoji: EmojiIntensity? = nil,
         selectedTag: TagItem? = nil,
         note: String = "",
         title: String,
         onSave: @escaping (TearEntry) -> Void) {
        self.dataManager = dataManager
        self._selectedDate = State(initialValue: selectedDate)
        self._selectedEmoji = State(initialValue: selectedEmoji ?? dataManager.emojiIntensities.first!)
        self._selectedTag = State(initialValue: selectedTag)
        self._note = State(initialValue: note)
        self.title = title
        self.onSave = onSave
    }
    
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
                        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
                        let entry = TearEntry(
                            date: selectedDate,
                            emojiId: selectedEmoji,
                            tagId: selectedTag,
                            note: trimmedNote
                        )
                        onSave(entry)
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .disabled(!isFormValid)
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
            Text("Какая причина?")
                .font(.headline)
            
            FlowLayout(spacing: 12) {
                ForEach(dataManager.tags) { tag in
                    TagButton(
                        tagName: tag.name,
                        isSelected: selectedTag?.id == tag.id,
                        action: {
                            selectedTag = tag
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
                            isSelected: selectedEmoji?.id == emojiIntensity.id,
                            action: {
                                selectedEmoji = emojiIntensity
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
                .padding([.all], 8)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.1), radius: 5)
                )
                .environment(\.locale, Locale(identifier: "ru_RU"))
        }
    }
}
