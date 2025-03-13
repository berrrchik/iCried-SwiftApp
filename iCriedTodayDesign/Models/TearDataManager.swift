import Foundation
import SwiftUI

class TearDataManager: ObservableObject {
    @Published var entries: [TearEntry] = []
    @Published var tags: [TagItem] = [
        TagItem(name: "#Здоровье"),
        TagItem(name: "#Одиночество"),
        TagItem(name: "#Работа"),
        TagItem(name: "#Семья"),
        TagItem(name: "#Фильмы")
    ]
    @Published var emojiIntensities: [EmojiIntensity] = [
        EmojiIntensity(emoji: "🥲", color: .blue, opacity: 0.4),
        EmojiIntensity(emoji: "😢", color: .blue, opacity: 0.7),
        EmojiIntensity(emoji: "😭", color: .blue, opacity: 1.0)
    ]
    private let fileManager = FileManager.default
    
    init() {
        load()
        loadTags()
        loadEmojis()
    }
    
    // MARK: - File Management
    private static func fileURL() throws -> URL {
        try FileManager.default.url(for: .documentDirectory,
                                    in: .userDomainMask,
                                    appropriateFor: nil,
                                    create: false)
        .appendingPathComponent("tearEntries.data")
    }
    
    // MARK: - Data Operations
    func load() {
        do {
            let fileURL = try TearDataManager.fileURL()
            guard let data = try? Data(contentsOf: fileURL) else { return }
            entries = try JSONDecoder().decode([TearEntry].self, from: data)
        } catch {
            print("Ошибка загрузки данных: \(error)")
        }
    }
    
    func save() {
        do {
            let data = try JSONEncoder().encode(entries)
            let outfile = try TearDataManager.fileURL()
            try data.write(to: outfile)
        } catch {
            print("Ошибка сохранения данных: \(error)")
        }
    }
    
    // MARK: - Entry Management
    func addEntry(_ entry: TearEntry) {
        entries.append(entry)
        save()
    }
    
    func deleteEntry(_ entry: TearEntry) {
        if let index = entries.firstIndex(where: { $0.id == entry.id }) {
            entries.remove(at: index)
            save()
        }
    }
    
    func updateEntry(_ entry: TearEntry) {
        if let index = entries.firstIndex(where: { $0.id == entry.id }) {
            entries[index] = entry
            save()
        }
    }
    
    // MARK: - Data Analysis
    
    var groupedEntries: [(month: String, records: [TearEntry])] {
        
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "LLLL yyyy"
        
        let grouped = Dictionary(grouping: entries) { entry in
            let components = calendar.dateComponents([.year, .month], from: entry.date)
            return components
        }
        
        return grouped.sorted { $0.key.year! > $1.key.year! || ($0.key.year! == $1.key.year! && $0.key.month! > $1.key.month!) }
            .map { (month: formatter.string(from: calendar.date(from: $0.key)!).uppercased(), records: $0.value.sorted(by: { $0.date > $1.date })) }
    }
    
    func getTag(for entry: TearEntry) -> TagItem? {
        return tags.first(where: { $0.id == entry.tagId })
    }
    
    func entriesForYear(_ year: Int, emojiId: UUID? = nil, tagId: UUID? = nil) -> [TearEntry] {
        let calendar = Calendar.current
        var filteredEntries = entries.filter { entry in
            calendar.component(.year, from: entry.date) == year
        }
        
        if let emojiId = emojiId {
            filteredEntries = filteredEntries.filter { $0.emojiId == emojiId }
        }
        
        if let tagId = tagId {
            filteredEntries = filteredEntries.filter { $0.tagId == tagId }
        }
        
        filteredEntries.sort(by: { $0.date > $1.date })
        
        print("Filtered entries for year \(year): \(filteredEntries.count) entries")
        return filteredEntries
    }
    
    func totalEntriesForYear(_ year: Int) -> Int {
        entriesForYear(year).count
    }
    
    func getEmoji(for entry: TearEntry) -> EmojiIntensity {
        if let emoji = emojiIntensities.first(where: { $0.id == entry.emojiId }) {
            return emoji
        }
        return emojiIntensities[0]
    }
    
    func emojiStatistics(for year: Int, emojiId: UUID? = nil) -> [(emoji: String, count: Int)] {
        let yearEntries = entriesForYear(year, emojiId: emojiId)
        var emojiCounts: [UUID: Int] = [:]
        
        yearEntries.forEach { entry in
            emojiCounts[entry.emojiId, default: 0] += 1
        }
        
        return emojiIntensities.map { emoji in
            (emoji: emoji.emoji, count: emojiCounts[emoji.id] ?? 0)
        }
        
    }
    
    func tagStatistics(for year: Int, tagId: UUID? = nil) -> [(tag: String, count: Int)] {
        let yearEntries = entriesForYear(year, tagId: tagId)
        var tagCounts: [UUID: Int] = [:]
        
        yearEntries.compactMap { $0.tagId }.forEach { tagId in
            tagCounts[tagId, default: 0] += 1
        }
        
        return tags.map { tag in
            (tag: tag.name, count: tagCounts[tag.id] ?? 0)
        }
    }
    
    func monthlyDataByIntensity(for year: Int, emojiId: UUID? = nil, tagId: UUID? = nil) -> [(date: Date, intensityCounts: [Int])] {
        let calendar = Calendar.current
        let yearEntries = entriesForYear(year, emojiId: emojiId, tagId: tagId)
        
        return (1...12).map { month in
            let components = DateComponents(year: year, month: month, day: 1)
            let monthStart = calendar.date(from: components) ?? Date()
            
            var emojiCounts: [UUID: Int] = [:]
            let entriesInMonth = yearEntries.filter {
                calendar.component(.month, from: $0.date) == month
            }
            
            entriesInMonth.forEach { entry in
                emojiCounts[entry.emojiId, default: 0] += 1
            }
            
            let intensityCounts = emojiIntensities.map { emoji in
                emojiCounts[emoji.id] ?? 0
            }
            
            return (date: monthStart, intensityCounts: intensityCounts)
        }
    }
    
    
    // MARK: - Tag Management
    func addTag(_ name: String) {
        let tag = TagItem(name: name)
        tags.append(tag)
        saveTags()
    }
    
    func removeTag(_ tagId: UUID) {
        tags.removeAll { $0.id == tagId }
        
        for index in entries.indices {
            if entries[index].tagId == tagId {
                entries[index].tagId = nil
            }
        }

        saveTags()
        save()
    }

    private func saveTags() {
        if let data = try? JSONEncoder().encode(tags) {
            print("💾 Сохранение тегов: \(tags.map { $0.name })")
            UserDefaults.standard.set(data, forKey: "tags")
        }
    }
    
    private func loadTags() {
        if let data = UserDefaults.standard.data(forKey: "tags"),
           let loadedTags = try? JSONDecoder().decode([TagItem].self, from: data) {
            tags = loadedTags
            print("Tags loaded from UserDefaults: \(tags.map { $0.name })")
        }
    }
    
    private func updateEntriesWithLoadedTags() {
        for (index, entry) in entries.enumerated() {
            var mutableEntry = entry
            if !tags.contains(where: { $0.id == mutableEntry.tagId }) {
                mutableEntry.tagId = nil
                entries[index] = mutableEntry
            }
        }
        save()
    }
    
    // MARK: - Emoji Management
    func addEmojiIntensity(_ emoji: EmojiIntensity) {
        emojiIntensities.append(emoji)
        saveEmojis()
    }
    
    func removeEmojiIntensity(at index: Int) {
        guard index >= 0 && index < emojiIntensities.count else { return }
        emojiIntensities.remove(at: index)
        saveEmojis()
    }
    
    func updateEmojiIntensity(_ updatedEmoji: EmojiIntensity, at index: Int) {
        guard index >= 0 && index < emojiIntensities.count else { return }
        let originalId = emojiIntensities[index].id
        var newEmoji = updatedEmoji
        newEmoji.id = originalId
        emojiIntensities[index] = newEmoji
        saveEmojis()
    }
    
    func moveEmojiIntensity(from source: IndexSet, to destination: Int) {
        let oldOrder = emojiIntensities.map { $0.id }
        
        emojiIntensities.move(fromOffsets: source, toOffset: destination)
        
        let newOrder = emojiIntensities.map { $0.id }
        let orderChanged = oldOrder != newOrder
        
        if orderChanged {
            objectWillChange.send()
            saveEmojis()
            
            print("Эмодзи перемещены: \(oldOrder) -> \(newOrder)")
        } else {
            print("Порядок эмодзи не изменился")
        }
    }
    
    private func saveEmojis() {
        if let data = try? JSONEncoder().encode(emojiIntensities) {
            UserDefaults.standard.set(data, forKey: "emojiIntensities")
        }
    }
    
    private func loadEmojis() {
        if let data = UserDefaults.standard.data(forKey: "emojiIntensities"),
           let emojis = try? JSONDecoder().decode([EmojiIntensity].self, from: data) {
            emojiIntensities = emojis
        }
    }
}
