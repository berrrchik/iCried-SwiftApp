import SwiftUI

struct TearCard: View {
    let entry: TearEntry
    @ObservedObject var dataManager: TearDataManager
    @State private var showingEditSheet = false
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "d MMMM"
        return formatter.string(from: entry.date)
    }
    
    private var tag: TagItem? {
        dataManager.getTag(for: entry)
    }
    
    var body: some View {
        Button(action: { showingEditSheet = true }) {
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(dataManager.getEmoji(for: entry).emoji)
                        .font(.title)
                    
                    if let tag {
                        Text(tag.name)
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(Color.blue.opacity(0.1)))
                            .foregroundColor(.blue)
                    }
                    
                    Spacer(minLength: 8)
                    
                    Text(formattedDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(entry.note)
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
            .padding(.vertical, 6)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingEditSheet) {
            EditTearView(
                availableTags: dataManager.tags,
                availableEmojiIntensities: dataManager.emojiIntensities,
                entry: entry,
                onSave: { entryID, newDate, newEmojiId, newTagId, newNote in
                    do {
                        try dataManager.updateEntry(
                            withId: entryID,
                            newDate: newDate,
                            newEmojiId: newEmojiId,
                            newTagId: newTagId,
                            newNote: newNote
                        )
                    } catch {
                        debugLog("Ошибка обновления записи: \(error)")
                    }
                }
            )
        }
    }
}
