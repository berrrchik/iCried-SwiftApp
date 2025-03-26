import Foundation
import SwiftUI
import SwiftData

@Observable
class TearDataManager {
    private var modelContext: ModelContext
    
    var entries: [TearEntry] = []
    var tags: [TagItem] = []
    var emojiIntensities: [EmojiIntensity] = []
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadInitialData()
    }
    
    private func loadInitialData() {
        do {
            let emojiDescriptor = FetchDescriptor<EmojiIntensity>(sortBy: [.init(\EmojiIntensity.order, order: .forward)])
            emojiIntensities = try modelContext.fetch(emojiDescriptor)
            
            if emojiIntensities.isEmpty {
                let defaultEmojis = [
                    EmojiIntensity(emoji: "🥲", color: .blue, opacity: 0.4, order: 0),
                    EmojiIntensity(emoji: "😢", color: .blue, opacity: 0.7, order: 1),
                    EmojiIntensity(emoji: "😭", color: .blue, opacity: 1.0, order: 2)
                ]
                
                for emoji in defaultEmojis {
                    modelContext.insert(emoji)
                    emojiIntensities.append(emoji)
                }
            }
            
            let tagDescriptor = FetchDescriptor<TagItem>(sortBy: [.init(\TagItem.order, order: .forward)])
            tags = try modelContext.fetch(tagDescriptor)
            
            if tags.isEmpty {
                let defaultTags = [
                    "#Здоровье", "#Одиночество", "#Работа",
                    "#Семья", "#Фильмы"
                ].enumerated().map { TagItem(name: $0.element, order: $0.offset) }
                
                for tag in defaultTags {
                    modelContext.insert(tag)
                    tags.append(tag)
                }
            }
            
            let entryDescriptor = FetchDescriptor<TearEntry>()
            entries = try modelContext.fetch(entryDescriptor)
            
        } catch {
            print("Ошибка при загрузке данных: \(error)")
        }
    }
    
    
    var availableYears: [Int] {
        Set(entries.map { Calendar.current.component(.year, from: $0.date) }).sorted()
    }
    
    // MARK: - Entry Management
    
    func addEntry(_ entry: TearEntry) {
        modelContext.insert(entry)
        entries.append(entry)
        save()
    }
    
    func deleteEntry(_ entry: TearEntry) {
        modelContext.delete(entry)
        entries.removeAll { $0.id == entry.id }
        save()
    }
    
    func updateEntry(_ entry: TearEntry) {
        if let index = entries.firstIndex(where: { $0.id == entry.id }) {
            entries[index] = entry
            save()
        }
    }
    
    // MARK: - Tag Management
    
    func addTag(_ name: String) {
        let tag = TagItem(name: name)
        modelContext.insert(tag)
        tags.append(tag)
        save()
    }
    
    func removeTag(_ tagId: UUID) {
        if let tag = tags.first(where: { $0.id == tagId }) {
            modelContext.delete(tag)
            tags.removeAll { $0.id == tagId }
            
            entries.forEach { entry in
                if entry.tagId == tagId {
                    entry.tagId = nil
                }
            }
            save()
        }
    }
    
    func moveTag(from source: IndexSet, to destination: Int) {
        let oldOrder = tags.map { $0.id }
        tags.move(fromOffsets: source, toOffset: destination)
        let newOrder = tags.map { $0.id }

        if oldOrder != newOrder {
            for (index, tag) in tags.enumerated() {
                tag.order = index
            }
            save()
        }
    }
    
    // MARK: - Emoji Management
    
    func addEmojiIntensity(_ emoji: EmojiIntensity) {
        modelContext.insert(emoji)
        emojiIntensities.append(emoji)
        save()
    }
    
    func removeEmojiIntensity(at index: Int) {
        guard index >= 0 && index < emojiIntensities.count else { return }
        let emoji = emojiIntensities[index]
        modelContext.delete(emoji)
        emojiIntensities.remove(at: index)
        save()
    }
    
    func updateEmojiIntensity(_ updatedEmoji: EmojiIntensity, at index: Int) {
        guard index >= 0 && index < emojiIntensities.count else { return }
        
        let originalEmoji = emojiIntensities[index]
        
        originalEmoji.emoji = updatedEmoji.emoji
        originalEmoji.colorHex = updatedEmoji.colorHex
        originalEmoji.opacity = updatedEmoji.opacity
        
        save()
    }

    func moveEmojiIntensity(from source: IndexSet, to destination: Int) {
        let oldOrder = emojiIntensities.map { $0.id }
        emojiIntensities.move(fromOffsets: source, toOffset: destination)
        let newOrder = emojiIntensities.map { $0.id }

        if oldOrder != newOrder {
            for (index, emoji) in emojiIntensities.enumerated() {
                emoji.order = index
            }
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
    
    func entriesForYear(_ year: Int, emojiId: UUID? = nil, tagIds: [UUID]? = nil) -> [TearEntry] {
        let calendar = Calendar.current
        return entries.filter { entry in
            let entryYear = calendar.component(.year, from: entry.date)
            
            let yearMatches = entryYear == year
            let emojiMatches = emojiId == nil || entry.emojiId == emojiId
            let tagMatches = tagIds == nil || (entry.tagId != nil && tagIds!.contains(entry.tagId!))
            
            return yearMatches && emojiMatches && tagMatches
        }
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
    
    func emojiStatistics(for year: Int, tagIds: [UUID]? = nil) -> [(emoji: String, count: Int)] {
        let calendar = Calendar.current
        let yearEntries = entries.filter { entry in
            let entryYear = calendar.component(.year, from: entry.date)
            
            // Проверяем соответствие году и тегам
            let yearMatches = entryYear == year
            let tagMatches = tagIds == nil || (entry.tagId != nil && tagIds!.contains(entry.tagId!))
            
            return yearMatches && tagMatches
        }
        
        var emojiCounts: [UUID: Int] = [:]
        yearEntries.forEach { entry in
            emojiCounts[entry.emojiId, default: 0] += 1
        }
        
        return emojiIntensities.map { emoji in
            (emoji: emoji.emoji, count: emojiCounts[emoji.id] ?? 0)
        }
    }
    
    func tagStatistics(for year: Int, tagIds: [UUID]? = nil) -> [(tag: String, count: Int)] {
        let yearEntries = entriesForYear(year, tagIds: tagIds)
        var tagCounts: [UUID: Int] = [:]
        
        yearEntries.compactMap { $0.tagId }.forEach { tagId in
            tagCounts[tagId, default: 0] += 1
        }
        
        return tags.map { tag in
            (tag: tag.name, count: tagCounts[tag.id] ?? 0)
        }
    }
    
    func monthlyDataByIntensity(for year: Int, emojiId: UUID? = nil, tagIds: [UUID]? = nil) -> [(date: Date, intensityCounts: [Int])] {
        let calendar = Calendar.current
        
        let yearEntries = entries.filter { entry in
            let entryYear = calendar.component(.year, from: entry.date)
            
            let yearMatches = entryYear == year
            let emojiMatches = emojiId == nil || entry.emojiId == emojiId
            let tagMatches = tagIds == nil || (entry.tagId != nil && tagIds!.contains(entry.tagId!))
            
            return yearMatches && emojiMatches && tagMatches
        }
        
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
    
    func save() {
        do {
            try modelContext.save()
        } catch {
            print("Ошибка при сохранении: \(error)")
        }
    }
}
