import Foundation
import SwiftUI

class TearDataManager: ObservableObject {
    @Published var entries: [TearEntry] = []
    @Published var availableTags: [String] = ["#Фильмы", "#Семья", "#Здоровье", "#Работа", "#Одиночество"]
    @Published var emojiIntensities: [EmojiIntensity] = [
        EmojiIntensity(emoji: "🥲", color: .blue.opacity(0.4)),
        EmojiIntensity(emoji: "😢", color: .blue.opacity(0.7)),
        EmojiIntensity(emoji: "😭", color: .blue)
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
        let grouped = Dictionary(grouping: entries) { entry in
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "ru_RU")
            formatter.dateFormat = "LLLL yyyy"
            return formatter.string(from: entry.date)
        }
        return grouped.sorted { $0.key > $1.key }
            .map { (month: $0.key.uppercased(), records: $0.value) }
    }
    
    func entriesForYear(_ year: Int) -> [TearEntry] {
        let calendar = Calendar.current
        return entries.filter { entry in
            calendar.component(.year, from: entry.date) == year
        }
    }
    
    func totalEntriesForYear(_ year: Int) -> Int {
        entriesForYear(year).count
    }
    
    func monthlyDataByIntensity(for year: Int) -> [(date: Date, intensityCounts: [Int])] {
        let calendar = Calendar.current
        let yearEntries = entriesForYear(year)
        
        return (1...12).map { month in
            let components = DateComponents(year: year, month: month, day: 1)
            let monthStart = calendar.date(from: components) ?? Date()
            
            var intensityCounts = Array(repeating: 0, count: emojiIntensities.count)
            let entriesInMonth = yearEntries.filter {
                calendar.component(.month, from: $0.date) == month
            }
            
            entriesInMonth.forEach { entry in
                if entry.intensity < emojiIntensities.count {
                    intensityCounts[entry.intensity] += 1
                }
            }
            
            return (date: monthStart, intensityCounts: intensityCounts)
        }
    }
    
    func tagStatistics(for year: Int) -> [TagStatistic] {
        let yearEntries = entriesForYear(year)
        var tagCounts: [String: Int] = [:]
        
        yearEntries.forEach { entry in
            entry.tags.forEach { tag in
                tagCounts[tag, default: 0] += 1
            }
        }
        
        return tagCounts
            .map { TagStatistic(tag: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }
    
    func emojiStatistics(for year: Int) -> [(emoji: String, count: Int)] {
        let yearEntries = entriesForYear(year)
        var emojiCounts = Array(repeating: 0, count: emojiIntensities.count)
        
        yearEntries.forEach { entry in
            if entry.intensity < emojiIntensities.count {
                emojiCounts[entry.intensity] += 1
            }
        }
        
        return zip(emojiIntensities.map { $0.emoji }, emojiCounts).map { (emoji: $0.0, count: $0.1) }
    }
    
    // MARK: - Tag Management
    func addTag(_ tag: String) {
        if !availableTags.contains(tag) {
            availableTags.append(tag)
            saveTags()
        }
    }
    
    func removeTag(_ tag: String) {
        if let index = availableTags.firstIndex(of: tag) {
            availableTags.remove(at: index)
            // Удаляем тег из всех записей
            for i in entries.indices {
                entries[i].tags.remove(tag)
            }
            saveTags()
            save() // Сохраняем изменения в записях
        }
    }
    
    private func saveTags() {
        if let data = try? JSONEncoder().encode(availableTags) {
            UserDefaults.standard.set(data, forKey: "availableTags")
        }
    }
    
    private func loadTags() {
        if let data = UserDefaults.standard.data(forKey: "availableTags"),
           let tags = try? JSONDecoder().decode([String].self, from: data) {
            availableTags = tags
        }
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
    
    func updateEmojiIntensity(_ emoji: EmojiIntensity, at index: Int) {
        guard index >= 0 && index < emojiIntensities.count else { return }
        emojiIntensities[index] = emoji
        saveEmojis()
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

// MARK: - Supporting Types
extension TearDataManager {
    struct TagStatistic: Identifiable {
        let id = UUID()
        let tag: String
        let count: Int
        
        var emoji: String {
            switch tag {
            case "#Media": return "😐"
            case "#Family": return "😢"
            case "#Health": return "😭"
            case "#Work": return "😫"
            case "#Loneliness": return "🥺"
            default: return "😢"
            }
        }
    }
}
