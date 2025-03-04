import SwiftUI

struct TearFormView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var dataManager: TearDataManager
    
    @State var selectedDate: Date
    @State var selectedEmojiId: UUID
    @State var selectedTags: Set<String>
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
                            tags: selectedTags,
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
                ForEach(dataManager.availableTags, id: \.self) { tag in
                    TagButton(tag: tag,
                            isSelected: selectedTags.contains(tag)) {
                        if selectedTags.contains(tag) {
                            selectedTags.remove(tag)
                        } else {
                            selectedTags.insert(tag)
                        }
                    }
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
                        Button(action: { selectedEmojiId = emojiIntensity.id }) {
                            Text(emojiIntensity.emoji)
                                .font(.system(size: 40))
                                .padding()
                                .background(
                                    Circle()
                                        .fill(selectedEmojiId == emojiIntensity.id ?
                                            .blue.opacity(0.2) :
                                                Color(.systemBackground))
                                        .frame(width: 70, height: 70)
                                        .background(Color(.systemBackground))
                                        .clipShape(Circle())
                                        .padding(8)
                                        .background(Color.clear)
                                        .shadow(color: .black.opacity(0.2), radius: 4)
                                )
                        }
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
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.1), radius: 5)
                )
        }
    }
} 
