//
//  iCriedTodayDesignTests.swift
//  iCriedTodayDesignTests
//
//  Created by Анастасия Берчик on 2/19/25.
//

import XCTest
import SwiftUI
import SwiftData
@testable import iCriedTodayDesign

final class iCriedTodayDesignTests: XCTestCase {
    func testGroupedEntriesSortsByMonthDescending() {
        let calendar = Calendar(identifier: .gregorian)
        let sadness = EmojiIntensity(emoji: "😢", color: .blue, opacity: 0.7, order: 0)
        let tag = TagItem(name: "#Работа")
        let januaryEntry = TearEntry(
            date: calendar.date(from: DateComponents(year: 2025, month: 1, day: 10))!,
            emojiId: sadness,
            tagId: tag,
            note: "January"
        )
        let marchEntry = TearEntry(
            date: calendar.date(from: DateComponents(year: 2025, month: 3, day: 5))!,
            emojiId: sadness,
            tagId: tag,
            note: "March"
        )
        let decemberEntry = TearEntry(
            date: calendar.date(from: DateComponents(year: 2024, month: 12, day: 25))!,
            emojiId: sadness,
            tagId: tag,
            note: "December"
        )
        
        let analyzer = DataAnalyzer(
            entries: [januaryEntry, decemberEntry, marchEntry],
            tags: [tag],
            emojiIntensities: [sadness]
        )
        
        let groupedDates = analyzer.groupedEntries.compactMap { section in
            section.records.first?.date
        }
        
        XCTAssertEqual(groupedDates.count, 3)
        XCTAssertEqual(calendar.component(.month, from: groupedDates[0]), 3)
        XCTAssertEqual(calendar.component(.year, from: groupedDates[0]), 2025)
        XCTAssertEqual(calendar.component(.month, from: groupedDates[1]), 1)
        XCTAssertEqual(calendar.component(.year, from: groupedDates[1]), 2025)
        XCTAssertEqual(calendar.component(.month, from: groupedDates[2]), 12)
        XCTAssertEqual(calendar.component(.year, from: groupedDates[2]), 2024)
    }
    
    func testEntriesForYearFiltersBySelectedTag() {
        let calendar = Calendar(identifier: .gregorian)
        let sadness = EmojiIntensity(emoji: "😢", color: .blue, opacity: 0.7, order: 0)
        let workTag = TagItem(name: "#Работа")
        let familyTag = TagItem(name: "#Семья")
        let matchingEntry = TearEntry(
            date: calendar.date(from: DateComponents(year: 2025, month: 2, day: 3))!,
            emojiId: sadness,
            tagId: workTag,
            note: "Work"
        )
        let otherTagEntry = TearEntry(
            date: calendar.date(from: DateComponents(year: 2025, month: 2, day: 4))!,
            emojiId: sadness,
            tagId: familyTag,
            note: "Family"
        )
        let noTagEntry = TearEntry(
            date: calendar.date(from: DateComponents(year: 2025, month: 2, day: 5))!,
            emojiId: sadness,
            tagId: nil,
            note: "No tag"
        )
        
        let analyzer = DataAnalyzer(
            entries: [matchingEntry, otherTagEntry, noTagEntry],
            tags: [workTag, familyTag],
            emojiIntensities: [sadness]
        )
        
        let filtered = analyzer.entriesForYear(2025, tags: [workTag])
        
        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered.first?.id, matchingEntry.id)
    }
    
    func testEntriesForYearFiltersBySelectedEmoji() {
        let calendar = Calendar(identifier: .gregorian)
        let lightSadness = EmojiIntensity(emoji: "🥲", color: .blue, opacity: 0.4, order: 0)
        let deepSadness = EmojiIntensity(emoji: "😭", color: .blue, opacity: 1.0, order: 1)
        let tag = TagItem(name: "#Здоровье")
        let matchingEntry = TearEntry(
            date: calendar.date(from: DateComponents(year: 2025, month: 4, day: 1))!,
            emojiId: deepSadness,
            tagId: tag,
            note: "Deep sadness"
        )
        let otherEmojiEntry = TearEntry(
            date: calendar.date(from: DateComponents(year: 2025, month: 4, day: 2))!,
            emojiId: lightSadness,
            tagId: tag,
            note: "Light sadness"
        )
        
        let analyzer = DataAnalyzer(
            entries: [matchingEntry, otherEmojiEntry],
            tags: [tag],
            emojiIntensities: [lightSadness, deepSadness]
        )
        
        let filtered = analyzer.entriesForYear(2025, emoji: deepSadness)
        
        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered.first?.id, matchingEntry.id)
    }
    
    @MainActor
    func testRefreshDataReloadsEntriesFromStore() async throws {
        let container = try makeInMemoryContainer()
        let modelContext = ModelContext(container)
        let manager = TearDataManager(modelContext: modelContext)
        let entry = makeEntry(note: "Remote reload")
        
        modelContext.insert(entry)
        try modelContext.save()
        
        await manager.refreshData()
        
        XCTAssertTrue(manager.entries.contains { $0.id == entry.id })
    }
    
    @MainActor
    func testLocalCRUDWorksWithoutManualCloudKitManager() throws {
        let container = try makeInMemoryContainer()
        let modelContext = ModelContext(container)
        let manager = TearDataManager(modelContext: modelContext)
        let emoji = EmojiIntensity(emoji: "😶‍🌫️", color: .blue, opacity: 0.5, order: 99)
        
        manager.addEmojiIntensity(emoji)
        manager.addTag("#Тест")
        
        guard let createdTag = manager.tags.first(where: { $0.name == "#Тест" }) else {
            return XCTFail("Expected tag to be added to the local store")
        }
        
        let entry = TearEntry(
            date: Date(),
            emojiId: emoji,
            tagId: createdTag,
            note: "Local CRUD"
        )
        
        manager.addEntry(entry)
        XCTAssertTrue(manager.entries.contains { $0.id == entry.id })
        
        manager.deleteEntry(entry)
        XCTAssertFalse(manager.entries.contains { $0.id == entry.id })
    }
    
    @MainActor
    func testDuplicateRemoverCollapsesDuplicateTags() throws {
        let container = try makeInMemoryContainer()
        let modelContext = ModelContext(container)
        let entryManager = TearEntryManager(modelContext: modelContext)
        let tagManager = TagManager(modelContext: modelContext)
        let emojiManager = EmojiIntensityManager(modelContext: modelContext)
        
        let firstTag = TagItem(name: "#Работа", order: 0)
        let duplicateTag = TagItem(name: "#работа", order: 1)
        duplicateTag.id = UUID()
        modelContext.insert(firstTag)
        modelContext.insert(duplicateTag)
        try modelContext.save()
        
        tagManager.reloadTags()
        
        let duplicateRemover = DuplicateRemover(
            modelContext: modelContext,
            entryManager: entryManager,
            tagManager: tagManager,
            emojiManager: emojiManager
        )
        
        duplicateRemover.removeDuplicates()
        
        XCTAssertEqual(tagManager.tags.filter { $0.name.lowercased() == "#работа" }.count, 1)
    }
    
    private func makeEntry(
        year: Int = 2025,
        month: Int = 1,
        day: Int = 1,
        note: String,
        emoji: EmojiIntensity? = nil,
        tag: TagItem? = nil
    ) -> TearEntry {
        let calendar = Calendar(identifier: .gregorian)
        return TearEntry(
            date: calendar.date(from: DateComponents(year: year, month: month, day: day))!,
            emojiId: emoji,
            tagId: tag,
            note: note
        )
    }
    
    @MainActor
    private func makeInMemoryContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: TearEntry.self,
            EmojiIntensity.self,
            TagItem.self,
            configurations: configuration
        )
    }
}
