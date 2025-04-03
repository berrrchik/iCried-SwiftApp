import Foundation
import SwiftData
import Combine
import SwiftUI

@Observable
class TearDataManager: DataManagerProtocol {
    private let modelContext: ModelContext
    private let entryManager: TearEntryManager
    private let tagManager: TagManager
    private let emojiManager: EmojiIntensityManager
    private let dataLoader: DataLoader
    private let cloudKitSyncManager: CloudKitSyncManager
    private var dataAnalyzer: DataAnalyzer
    private let duplicateRemover: DuplicateRemover
    
    var syncTrigger = UUID()
    var entries: [TearEntry] { entryManager.entries }
    var tags: [TagItem] { tagManager.tags }
    var emojiIntensities: [EmojiIntensity] { emojiManager.emojiIntensities }
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.entryManager = TearEntryManager(modelContext: modelContext)
        self.tagManager = TagManager(modelContext: modelContext)
        self.emojiManager = EmojiIntensityManager(modelContext: modelContext)
        self.dataLoader = DataLoader(modelContext: modelContext, emojiManager: emojiManager, tagManager: tagManager)
        self.cloudKitSyncManager = CloudKitSyncManager(modelContext: modelContext, entries: [], tags: [], emojiIntensities: [])
        self.duplicateRemover = DuplicateRemover(modelContext: modelContext, entryManager: entryManager, tagManager: tagManager, emojiManager: emojiManager)
        self.dataAnalyzer = DataAnalyzer(entries: entryManager.entries, tags: tagManager.tags, emojiIntensities: emojiManager.emojiIntensities)
        
        dataLoader.loadInitialData()
        removeDuplicates()
        updateAnalyzer()
    }
    
    // MARK: - Entry Management
    
    func addEntry(_ entry: TearEntry) {
        entryManager.addEntry(entry)
        updateAnalyzer()
        save()
        print("Добавлена новая запись: \(entry.note)")
    }
    
    func deleteEntry(_ entry: TearEntry) {
        entryManager.deleteEntry(entry)
        updateAnalyzer()
        save()
        print("Удалена запись: \(entry.note)")
    }
    
    func updateEntry(withId entryId: UUID, newDate: Date, newEmojiId: EmojiIntensity?, newTagId: TagItem?, newNote: String) throws {
        try entryManager.updateEntry(withId: entryId, newDate: newDate, newEmojiId: newEmojiId, newTagId: newTagId, newNote: newNote)
        updateAnalyzer()
        save()
        print("Обновлена запись с id: \(entryId)")
    }
    
    // MARK: - Tag Management
    
    func addTag(_ name: String) {
        tagManager.addTag(name)
        updateAnalyzer()
        save()
        print("Добавлен тег: \(name)")
    }
    
    func removeTag(_ tagId: UUID) {
        tagManager.removeTag(tagId)
        updateAnalyzer()
        save()
        print("Удалён тег с ID: \(tagId)")
    }
    
    func moveTag(from source: IndexSet, to destination: Int) {
        tagManager.moveTag(from: source, to: destination)
        updateAnalyzer()
        save()
        print("Теги перемещены")
    }
    
    // MARK: - Emoji Management
    
    func addEmojiIntensity(_ emoji: EmojiIntensity) {
        emojiManager.addEmojiIntensity(emoji)
        updateAnalyzer()
        save()
        print("Добавлен эмодзи: \(emoji.emoji)")
    }
    
    func removeEmojiIntensity(at index: Int) {
        let emoji = emojiIntensities[index]
        emojiManager.removeEmojiIntensity(at: index)
        updateAnalyzer()
        save()
        print("Удалён эмодзи: \(emoji.emoji)")
    }
    
    func updateEmojiIntensity(_ updatedEmoji: EmojiIntensity, at index: Int) {
        emojiManager.updateEmojiIntensity(updatedEmoji, at: index)
        updateAnalyzer()
        save()
        print("Обновлён эмодзи: \(updatedEmoji.emoji)")
    }
    
    func moveEmojiIntensity(from source: IndexSet, to destination: Int) {
        emojiManager.moveEmojiIntensity(from: source, to: destination)
        updateAnalyzer()
        save()
        print("Эмодзи перемещены")
    }
    
    // MARK: - Persistence
    
    func save() {
        do {
            entryManager.save()
            tagManager.save()
            emojiManager.save()
            try modelContext.save()
            print("Данные успешно сохранены в локальной базе")
        } catch {
            print("Ошибка сохранения данных: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Data Analysis
    
    private func updateAnalyzer() {
        dataAnalyzer = DataAnalyzer(entries: entryManager.entries, tags: tagManager.tags, emojiIntensities: emojiManager.emojiIntensities)
        print("Анализатор данных обновлён")
    }
    
    var availableYears: [Int] { dataAnalyzer.availableYears }
    var groupedEntries: [(month: String, records: [TearEntry])] { dataAnalyzer.groupedEntries }
    func getTag(for entry: TearEntry) -> TagItem? { dataAnalyzer.getTag(for: entry) }
    func entriesForYear(_ year: Int, emoji: EmojiIntensity? = nil, tags: [TagItem]? = nil) -> [TearEntry] {
        dataAnalyzer.entriesForYear(year, emoji: emoji, tags: tags)
    }
    func totalEntriesForYear(_ year: Int) -> Int { dataAnalyzer.totalEntriesForYear(year) }
    func getEmoji(for entry: TearEntry) -> EmojiIntensity { dataAnalyzer.getEmoji(for: entry) }
    func emojiStatistics(for year: Int, tags: [TagItem]? = nil) -> [(emoji: String, count: Int)] {
        dataAnalyzer.emojiStatistics(for: year, tags: tags)
    }
    func tagStatistics(for year: Int, tags: [TagItem]? = nil) -> [(tag: String, count: Int)] {
        dataAnalyzer.tagStatistics(for: year, tags: tags)
    }
    func monthlyDataByIntensity(for year: Int, emoji: EmojiIntensity? = nil, tags: [TagItem]? = nil) -> [(date: Date, intensityCounts: [Int])] {
        dataAnalyzer.monthlyDataByIntensity(for: year, emoji: emoji, tags: tags)
    }
    
    // MARK: - CloudKit Sync and Duplicates
    
    func removeDuplicates() {
        duplicateRemover.removeDuplicates()
        updateAnalyzer()
        save()
        print("Дубликаты удалены")
    }
    
//    func syncWithCloudKit() async {
//        cloudKitSyncManager.checkCloudKitStatus()
//        
//        await cloudKitSyncManager.syncWithCloudKit(
//            entries: entryManager.entries,
//            tags: tagManager.tags,
//            emojiIntensities: emojiManager.emojiIntensities
//        )
//        
//        entryManager.reloadEntries()
//        tagManager.reloadTags()
//        emojiManager.reloadEmojiIntensities()
//        updateAnalyzer()
//        print("Синхронизация с CloudKit выполнена")
//    }
    
    // В TearDataManager.swift
    func syncWithCloudKit() async {
        cloudKitSyncManager.checkCloudKitStatus()
        
        await cloudKitSyncManager.syncWithCloudKit(
            entries: entryManager.entries,
            tags: tagManager.tags,
            emojiIntensities: emojiManager.emojiIntensities
        )
        
        await MainActor.run {
            print("Данные ДО обновления:")
            print("Записей: \(entryManager.entries.count)")
            print("Тегов: \(tagManager.tags.count)")
            print("Эмодзи: \(emojiManager.emojiIntensities.count)")
            
            entryManager.reloadEntries()
            tagManager.reloadTags()
            emojiManager.reloadEmojiIntensities()
            
            print("\nДанные ПОСЛЕ обновления:")
            print("Записей: \(entryManager.entries.count)")
            print("Тегов: \(tagManager.tags.count)")
            print("Эмодзи: \(emojiManager.emojiIntensities.count)")
            
            updateAnalyzer()
            syncTrigger = UUID()
        }
    }
    
}
