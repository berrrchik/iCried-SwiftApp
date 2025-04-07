import Foundation
import SwiftData

@Observable
class TearEntryManager {
    private let modelContext: ModelContext
    var entries: [TearEntry] = []
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadEntries()
    }
    
    private func loadEntries() {
        do {
            let descriptor = FetchDescriptor<TearEntry>(sortBy: [.init(\.date, order: .reverse)])
            let newEntries = try modelContext.fetch(descriptor)
            print("Загружено записей из базы: \(newEntries.count)")
            entries = newEntries
        } catch {
            print("Ошибка при загрузке записей: \(error)")
        }
    }
    
    func reloadEntries() {
        loadEntries()
        print("Записей после перезагрузки: \(entries.count)")
        save()
    }
    
    func addEntry(_ entry: TearEntry) {
        let exists = entries.contains { existing in
            Calendar.current.isDate(existing.date, equalTo: entry.date, toGranularity: .minute) &&
            existing.emojiId == entry.emojiId &&
            existing.tagId == entry.tagId &&
            existing.note == entry.note
        }
        
        if !exists {
            modelContext.insert(entry)
            entries.append(entry)
            save()
        } else {
            print("Запись уже существует, дубликат не добавлен")
        }
    }
    
    func deleteEntry(_ entry: TearEntry) {
        modelContext.delete(entry)
        entries.removeAll { $0.id == entry.id }
        save()
    }
    
    func updateEntry(withId entryId: UUID, newDate: Date, newEmojiId: EmojiIntensity?, newTagId: TagItem?, newNote: String) throws {
        let fetchDescriptor = FetchDescriptor<TearEntry>(predicate: #Predicate { $0.id == entryId })
        if let existingEntry = try modelContext.fetch(fetchDescriptor).first {
            if let newEmojiId = newEmojiId {
                let emojiDescriptor = FetchDescriptor<EmojiIntensity>()
                let allEmojis = try modelContext.fetch(emojiDescriptor)
                if let emojiInContext = allEmojis.first(where: { $0.id == newEmojiId.id }) {
                    existingEntry.emojiId = emojiInContext
                } else {
                    print("Эмодзи с id \(newEmojiId.id) не найден в текущем контексте")
                }
            } else {
                existingEntry.emojiId = nil
            }

            if let newTagId = newTagId {
                let tagDescriptor = FetchDescriptor<TagItem>()
                let allTags = try modelContext.fetch(tagDescriptor)
                if let tagInContext = allTags.first(where: { $0.id == newTagId.id }) {
                    existingEntry.tagId = tagInContext
                } else {
                    print("Тег с id \(newTagId.id) не найден в текущем контексте")
                }
            } else {
                existingEntry.tagId = nil
            }

            existingEntry.date = newDate
            existingEntry.note = newNote
            try modelContext.save()
            
            if let index = entries.firstIndex(where: { $0.id == entryId }) {
                entries[index] = existingEntry
            }
        } else {
            throw NSError(domain: "TearEntryManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "Запись с id \(entryId) не найдена"])
        }
    }

    func save() {
        do {
            try modelContext.save()
        } catch {
            print("Ошибка при сохранении записей: \(error)")
        }
    }
}
