import SwiftUI
import SwiftData

struct TearFormView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: TearFormViewModel
    
    let title: String
    let onSave: (Date, EmojiIntensity?, TagItem?, String) -> Void
    
    init(availableTags: [TagItem],
         availableEmojiIntensities: [EmojiIntensity],
         selectedDate: Date = Date(),
         selectedEmoji: EmojiIntensity? = nil,
         selectedTag: TagItem? = nil,
         note: String = "",
         title: String,
        onSave: @escaping (Date, EmojiIntensity?, TagItem?, String) -> Void) {
        _viewModel = StateObject(
            wrappedValue: TearFormViewModel(
                availableTags: availableTags,
                availableEmojiIntensities: availableEmojiIntensities,
                selectedDate: selectedDate,
                selectedEmoji: selectedEmoji,
                selectedTag: selectedTag,
                note: note
            )
        )
        self.title = title
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationStack {
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
                        guard let savePayload = viewModel.savePayload else { return }
                        onSave(savePayload.date, savePayload.selectedEmoji, savePayload.selectedTag, savePayload.note)
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .disabled(!viewModel.isFormValid)
                }
            }
        }
    }
    
    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Что случилось?")
                .font(.headline)
            
            TextEditor(text: $viewModel.note)
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
                ForEach(viewModel.availableTags) { tag in
                    TagButton(
                        tagName: tag.name,
                        isSelected: viewModel.selectedTag?.id == tag.id,
                        action: {
                            viewModel.selectedTag = tag
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
            
            if let missingEmojiMessage = viewModel.missingEmojiMessage {
                Text(missingEmojiMessage)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(viewModel.availableEmojiIntensities) { emojiIntensity in
                            EmojiButton(
                                emoji: emojiIntensity.emoji,
                                count: nil,
                                color: emojiIntensity.color,
                                isSelected: viewModel.selectedEmoji?.id == emojiIntensity.id,
                                action: {
                                    viewModel.selectedEmoji = emojiIntensity
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
    }
    
    private var dateSection: some View {
        HStack(spacing: 20) {
            Text("Когда это случилось?")
                .font(.headline)
            
            DatePicker("", selection: $viewModel.selectedDate, displayedComponents: [.date, .hourAndMinute])
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
