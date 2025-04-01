import Foundation
import SwiftData
import CloudKit
import Combine

@Observable
class TearDataManager {
    private var modelContext: ModelContext
    private var cloudSubscription: AnyCancellable?
    
    var entries: [TearEntry] = []
    var tags: [TagItem] = []
    var emojiIntensities: [EmojiIntensity] = []
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadInitialData()
        setupCloudKitSubscription()
    }
    
    private func setupCloudKitSubscription() {
        let subscription = NotificationCenter.default.publisher(for: .NSPersistentStoreRemoteChange)
        cloudSubscription = subscription.sink { [weak self] _ in
            guard let self = self else { return }
        }
    }
    
    func checkCloudKitStatus() {
        CKContainer(identifier: "iCloud.com.berchik.iCriedTodayDesign").accountStatus { status, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Ошибка CloudKit: \(error.localizedDescription)")
                    return
                }
                
                switch status {
                case .available:
                    print("CloudKit доступен")
                case .noAccount:
                    print("Пользователь не вошел в iCloud")
                case .restricted:
                    print("CloudKit ограничен")
                case .couldNotDetermine:
                    print("Не удалось определить статус CloudKit")
                case .temporarilyUnavailable:
                    print("CloudKit временно недоступен")
                @unknown default:
                    print("Неизвестный статус CloudKit")
                }
            }
        }
    }
    
    func syncWithCloudKit() async {
        print("Начинаем синхронизацию с CloudKit...")
        let existingIds = Set(entries.map { $0.id })
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                self.loadInitialData()
                self.removeDuplicates()
                print("Синхронизация с CloudKit завершена")
                
                UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "lastDataRefreshTime")
                
                continuation.resume()
            }
        }
    }
    
    func removeDuplicates() {
        var emojiGroups: [String: [EmojiIntensity]] = [:]
        for emoji in emojiIntensities {
            emojiGroups[emoji.emoji, default: []].append(emoji)
        }
        
        var duplicateEmojisCount = 0
        for (_, group) in emojiGroups where group.count > 1 {
            let sortedGroup = group.sorted { $0.order < $1.order }
            let primaryEmoji = sortedGroup[0]
            
            for duplicateEmoji in sortedGroup.dropFirst() {
                for entry in entries where entry.emojiId?.id == duplicateEmoji.id {
                    entry.emojiId = primaryEmoji
                }
                
                modelContext.delete(duplicateEmoji)
                duplicateEmojisCount += 1
            }
        }
        
        if duplicateEmojisCount > 0 {
            let updatedEmojiDescriptor = FetchDescriptor<EmojiIntensity>(sortBy: [.init(\EmojiIntensity.order, order: .forward)])
            do {
                emojiIntensities = try modelContext.fetch(updatedEmojiDescriptor)
            } catch {
                print("Ошибка при обновлении эмодзи: \(error)")
            }
        }
        
        var tagGroups: [String: [TagItem]] = [:]
        for tag in tags {
            tagGroups[tag.name.lowercased(), default: []].append(tag)
        }
        
        var duplicateTagsCount = 0
        for (_, group) in tagGroups where group.count > 1 {
            let sortedGroup = group.sorted { $0.order < $1.order }
            let primaryTag = sortedGroup[0]
            
            for duplicateTag in sortedGroup.dropFirst() {
                for entry in entries where entry.tagId?.id == duplicateTag.id {
                    entry.tagId = primaryTag
                }
                modelContext.delete(duplicateTag)
                duplicateTagsCount += 1
            }
        }
        
        if duplicateTagsCount > 0 {
            let updatedTagDescriptor = FetchDescriptor<TagItem>(sortBy: [.init(\TagItem.order, order: .forward)])
            do {
                tags = try modelContext.fetch(updatedTagDescriptor)
            } catch {
                print("Ошибка при обновлении тегов: \(error)")
            }
        }
        
        var uniqueEntryIds = Set<UUID>()
        var duplicateEntries: [TearEntry] = []
        
        for entry in entries {
            if uniqueEntryIds.contains(entry.id) {
                duplicateEntries.append(entry)
            } else {
                uniqueEntryIds.insert(entry.id)
            }
        }
        
        var uniqueContentSignatures = Set<String>()
        var contentDuplicates: [TearEntry] = []
        
        for entry in entries {
            if !duplicateEntries.contains(where: { $0.id == entry.id }) {
                let signature = "\(entry.date.timeIntervalSince1970)-\(entry.emojiId?.id.uuidString ?? "")-\(entry.tagId?.id.uuidString ?? "")-\(entry.note)"
                if uniqueContentSignatures.contains(signature) {
                    contentDuplicates.append(entry)
                } else {
                    uniqueContentSignatures.insert(signature)
                }
            }
        }
        
        duplicateEntries.append(contentsOf: contentDuplicates)
        
        for duplicateEntry in duplicateEntries {
            modelContext.delete(duplicateEntry)
        }
        
        if !duplicateEntries.isEmpty {
            entries.removeAll { entry in
                duplicateEntries.contains { $0.id == entry.id }
            }
            print("Удалено \(duplicateEntries.count) дубликатов записей")
        }
        
        save()
        
        print("Удаление дубликатов завершено. Удалено: \(duplicateEmojisCount) эмодзи, \(duplicateTagsCount) тегов")
    }
    
    private func loadInitialData() {
        do {
            let emojiDescriptor = FetchDescriptor<EmojiIntensity>(
                sortBy: [.init(\EmojiIntensity.order, order: .forward)]
            )
            emojiIntensities = try modelContext.fetch(emojiDescriptor)
            
            if emojiIntensities.isEmpty {
                let defaultEmojis = [
                    ("🥲", 0.4),
                    ("😢", 0.7),
                    ("😭", 1.0)
                ]
                
                for (index, (emoji, opacity)) in defaultEmojis.enumerated() {
                    let newEmoji = EmojiIntensity(
                        emoji: emoji,
                        color: .blue,
                        opacity: opacity,
                        order: index
                    )
                    modelContext.insert(newEmoji)
                    emojiIntensities.append(newEmoji)
                }
            }
            
            let tagDescriptor = FetchDescriptor<TagItem>(
                sortBy: [.init(\TagItem.order, order: .forward)]
            )
            tags = try modelContext.fetch(tagDescriptor)
            
            if tags.isEmpty {
                let defaultTags = [
                    "#Здоровье",
                    "#Одиночество",
                    "#Работа",
                    "#Семья",
                    "#Фильмы"
                ]
                
                for (index, tagName) in defaultTags.enumerated() {
                    let newTag = TagItem(name: tagName)
                    newTag.order = index
                    modelContext.insert(newTag)
                    tags.append(newTag)
                }
            }
            
            let entryDescriptor = FetchDescriptor<TearEntry>(
                sortBy: [.init(\TearEntry.date, order: .reverse)]
            )
            entries = try modelContext.fetch(entryDescriptor)
            
            if emojiIntensities.count > 0 || tags.count > 0 {
                try modelContext.save()
            }
            
        } catch {
            print("Ошибка при загрузке данных: \(error)")
        }
    }
    
    
    var availableYears: [Int] {
        Set(entries.map { Calendar.current.component(.year, from: $0.date) }).sorted()
    }
    
    // MARK: - Entry Management
    
    func addEntry(_ entry: TearEntry) {
        let existingEntry = entries.first { existingEntry in
            let sameDate = Calendar.current.isDate(existingEntry.date, equalTo: entry.date, toGranularity: .minute)
            let sameEmoji = existingEntry.emojiId == entry.emojiId
            let sameTag = existingEntry.tagId == entry.tagId
            let sameNote = existingEntry.note == entry.note
            
            return sameDate && sameEmoji && sameTag && sameNote
        }
        
        if existingEntry == nil {
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
    
    func updateEntry(_ existingEntry: TearEntry, with updatedEntry: TearEntry) {
        existingEntry.date = updatedEntry.date
        existingEntry.emojiId = updatedEntry.emojiId
        existingEntry.tagId = updatedEntry.tagId
        existingEntry.note = updatedEntry.note
        
        save()
        
        if let index = entries.firstIndex(where: { $0.id == existingEntry.id }) {
            entries[index] = existingEntry
        }
    }
    
    // MARK: - Tag Management
    
    func addTag(_ name: String) {
        let normalizedName = name.trimmingCharacters(in: .whitespaces)
        if !tags.contains(where: { $0.name.lowercased() == normalizedName.lowercased() }) {
            let tag = TagItem(name: normalizedName)
            tag.order = tags.count
            modelContext.insert(tag)
            tags.append(tag)
            save()
        } else {
            print("Тег '\(name)' уже существует, дубликат не добавлен")
        }
    }
    
    func removeTag(_ tagId: UUID) {
        if let tag = tags.first(where: { $0.id == tagId }) {
            modelContext.delete(tag)
            tags.removeAll { $0.id == tagId }
            
            entries.forEach { entry in
                if entry.tagId?.id == tagId {
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
        if !emojiIntensities.contains(where: { $0.emoji == emoji.emoji }) {
            emoji.order = emojiIntensities.count
            modelContext.insert(emoji)
            emojiIntensities.append(emoji)
            save()
        } else {
            print("Эмодзи '\(emoji.emoji)' уже существует, дубликат не добавлен")
        }
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
        return entry.tagId
    }
    
    func entriesForYear(_ year: Int, emoji: EmojiIntensity? = nil, tags: [TagItem]? = nil) -> [TearEntry] {
        let calendar = Calendar.current
        return entries.filter { entry in
            let entryYear = calendar.component(.year, from: entry.date)
            let yearMatches = entryYear == year
            let emojiMatches = emoji == nil || entry.emojiId?.id == emoji?.id
            let tagMatches = tags == nil || (entry.tagId != nil && tags!.contains { $0.id == entry.tagId!.id })
            
            return yearMatches && emojiMatches && tagMatches
        }
    }
    
    func totalEntriesForYear(_ year: Int) -> Int {
        entriesForYear(year).count
    }
    
    func getEmoji(for entry: TearEntry) -> EmojiIntensity {
        return entry.emojiId ?? emojiIntensities[0]
    }
    
    func emojiStatistics(for year: Int, tags: [TagItem]? = nil) -> [(emoji: String, count: Int)] {
        let yearEntries = entriesForYear(year, tags: tags)
        var emojiCounts: [UUID: Int] = [:]
        
        yearEntries.forEach { entry in
            if let emojiId = entry.emojiId?.id {
                emojiCounts[emojiId, default: 0] += 1
            }
        }
        
        return emojiIntensities.map { emoji in
            (emoji: emoji.emoji, count: emojiCounts[emoji.id] ?? 0)
        }
    }
    
    func tagStatistics(for year: Int, tags: [TagItem]? = nil) -> [(tag: String, count: Int)] {
        let yearEntries = entriesForYear(year, tags: tags)
        var tagCounts: [UUID: Int] = [:]
        
        yearEntries.compactMap { $0.tagId?.id }.forEach { tagId in
            tagCounts[tagId, default: 0] += 1
        }
        
        let targetTags = tags ?? self.tags
        
        return targetTags.map { tag in
            (tag: tag.name, count: tagCounts[tag.id] ?? 0)
        }
    }
    
    func monthlyDataByIntensity(for year: Int, emoji: EmojiIntensity? = nil, tags: [TagItem]? = nil) -> [(date: Date, intensityCounts: [Int])] {
        let calendar = Calendar.current
        let yearEntries = entriesForYear(year, emoji: emoji, tags: tags)
       
        return (1...12).map { month in
            let components = DateComponents(year: year, month: month, day: 1)
            let monthStart = calendar.date(from: components) ?? Date()
            
            var emojiCounts: [UUID: Int] = [:]
            let entriesInMonth = yearEntries.filter {
                calendar.component(.month, from: $0.date) == month
            }
            
            entriesInMonth.forEach { entry in
                if let emojiId = entry.emojiId?.id {
                    emojiCounts[emojiId, default: 0] += 1
                }
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
            print("Данные успешно сохранены")
        } catch {
            print("Ошибка при сохранении: \(error)")
            if let nsError = error as NSError? {
                print("Детали ошибки: \(nsError.localizedDescription)")
                print("Код ошибки: \(nsError.code)")
            }
        }
    }
}
