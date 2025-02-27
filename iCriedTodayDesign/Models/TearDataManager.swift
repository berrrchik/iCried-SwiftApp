import Foundation
import SwiftUI

class TearDataManager: ObservableObject {
    @Published var entries: [TearEntry] = []
    private let fileManager = FileManager.default
    
    init() {
        load()
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
            
            var intensityCounts = [0, 0, 0]
            let entriesInMonth = yearEntries.filter {
                calendar.component(.month, from: $0.date) == month
            }
            
            entriesInMonth.forEach { entry in
                intensityCounts[entry.intensity] += 1
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
        var emojiCounts = [0, 0, 0]
        let emojis = ["🥲", "😢", "😭"]
        
        yearEntries.forEach { entry in
            emojiCounts[entry.intensity] += 1
        }
        
        return zip(emojis, emojiCounts).map { (emoji: $0.0, count: $0.1) }
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
