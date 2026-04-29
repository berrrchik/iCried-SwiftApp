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
    
    func testDiarySectionsUseUppercasedRussianMonthTitles() {
        let calendar = Calendar(identifier: .gregorian)
        let sadness = EmojiIntensity(emoji: "😢", color: .blue, opacity: 0.7, order: 0)
        let tag = TagItem(name: "#Работа")
        let entry = TearEntry(
            date: calendar.date(from: DateComponents(year: 2025, month: 3, day: 14))!,
            emojiId: sadness,
            tagId: tag,
            note: "March"
        )
        
        let analyzer = DataAnalyzer(
            entries: [entry],
            tags: [tag],
            emojiIntensities: [sadness]
        )
        
        XCTAssertEqual(analyzer.groupedEntries.first?.monthTitle, "МАРТ 2025")
    }
    
    func testStatisticsEngineTogglesSelectedMonthOffWhenTappedAgain() {
        let engine = StatisticsEngine(entries: [], tags: [], emojiIntensities: [])
        let calendar = Calendar(identifier: .gregorian)
        let tappedMonth = calendar.date(from: DateComponents(year: 2025, month: 4, day: 1))!
        
        let selectedMonth = engine.toggledMonthSelection(current: nil, tappedDate: tappedMonth)
        let deselectedMonth = engine.toggledMonthSelection(current: selectedMonth, tappedDate: tappedMonth)
        
        XCTAssertEqual(selectedMonth, tappedMonth)
        XCTAssertNil(deselectedMonth)
    }
    
    func testStatisticsSnapshotAppliesMonthAndEmojiFiltersToDiaryResults() {
        let calendar = Calendar(identifier: .gregorian)
        let lightSadness = EmojiIntensity(emoji: "🥲", color: .blue, opacity: 0.4, order: 0)
        let deepSadness = EmojiIntensity(emoji: "😭", color: .blue, opacity: 1.0, order: 1)
        let tag = TagItem(name: "#Работа")
        let aprilMatch = TearEntry(
            date: calendar.date(from: DateComponents(year: 2025, month: 4, day: 5))!,
            emojiId: deepSadness,
            tagId: tag,
            note: "April match"
        )
        let aprilOtherEmoji = TearEntry(
            date: calendar.date(from: DateComponents(year: 2025, month: 4, day: 6))!,
            emojiId: lightSadness,
            tagId: tag,
            note: "April other emoji"
        )
        let mayMatch = TearEntry(
            date: calendar.date(from: DateComponents(year: 2025, month: 5, day: 1))!,
            emojiId: deepSadness,
            tagId: tag,
            note: "May match"
        )
        
        let engine = StatisticsEngine(
            entries: [aprilMatch, aprilOtherEmoji, mayMatch],
            tags: [tag],
            emojiIntensities: [lightSadness, deepSadness]
        )
        
        let snapshot = engine.snapshot(
            filter: StatisticsFilter(
                year: 2025,
                selectedMonth: calendar.date(from: DateComponents(year: 2025, month: 4, day: 1)),
                selectedEmojiID: deepSadness.id,
                selectedTagIDs: []
            )
        )
        
        XCTAssertEqual(snapshot.filteredEntriesCount, 1)
        XCTAssertEqual(snapshot.diarySections.count, 1)
        XCTAssertEqual(snapshot.diarySections.first?.records.first?.id, aprilMatch.id)
    }
    
    func testStatisticsSnapshotSupportsMultipleSelectedTags() {
        let workTag = TagItem(name: "#Работа")
        let familyTag = TagItem(name: "#Семья")
        let otherTag = TagItem(name: "#Учеба")
        let sadness = EmojiIntensity(emoji: "😢", color: .blue, opacity: 0.7, order: 0)
        
        let workEntry = makeEntry(note: "Work", emoji: sadness, tag: workTag)
        let familyEntry = makeEntry(day: 2, note: "Family", emoji: sadness, tag: familyTag)
        let studyEntry = makeEntry(day: 3, note: "Study", emoji: sadness, tag: otherTag)
        
        let engine = StatisticsEngine(
            entries: [workEntry, familyEntry, studyEntry],
            tags: [workTag, familyTag, otherTag],
            emojiIntensities: [sadness]
        )
        
        let filteredEntries = engine.entriesForYear(
            2025,
            tagIDs: Set([workTag.id, familyTag.id])
        )
        
        XCTAssertEqual(filteredEntries.count, 2)
        XCTAssertTrue(filteredEntries.contains { $0.id == workEntry.id })
        XCTAssertTrue(filteredEntries.contains { $0.id == familyEntry.id })
    }
    
    func testCryingMomentsPluralizerHandlesRussianEdgeCases() {
        XCTAssertEqual(CryingMomentsPluralizer.label(for: 1), "Момент грусти")
        XCTAssertEqual(CryingMomentsPluralizer.label(for: 2), "Момента грусти")
        XCTAssertEqual(CryingMomentsPluralizer.label(for: 5), "Моментов грусти")
        XCTAssertEqual(CryingMomentsPluralizer.label(for: 11), "Моментов грусти")
        XCTAssertEqual(CryingMomentsPluralizer.label(for: 21), "Момент грусти")
        XCTAssertEqual(CryingMomentsPluralizer.label(for: 24), "Момента грусти")
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
        let entryRepository = EntryRepository(modelContext: modelContext)
        let tagRepository = TagRepository(modelContext: modelContext)
        let emojiRepository = EmojiRepository(modelContext: modelContext)
        
        let firstTag = TagItem(name: "#Работа", order: 0)
        let duplicateTag = TagItem(name: "#работа", order: 1)
        duplicateTag.id = UUID()
        modelContext.insert(firstTag)
        modelContext.insert(duplicateTag)
        try modelContext.save()
        
        tagRepository.reloadTags()
        
        let duplicateRemover = DuplicateRemover(
            entryRepository: entryRepository,
            tagRepository: tagRepository,
            emojiRepository: emojiRepository
        )
        
        duplicateRemover.removeDuplicates()
        
        XCTAssertEqual(tagRepository.tags.filter { $0.name.lowercased() == "#работа" }.count, 1)
    }
    
    @MainActor
    func testEntryRepositorySupportsAddEditDelete() throws {
        let container = try makeInMemoryContainer()
        let modelContext = ModelContext(container)
        let repository = EntryRepository(modelContext: modelContext)
        let emoji = EmojiIntensity(emoji: "😢", color: .blue, opacity: 0.7, order: 0)
        let tag = TagItem(name: "#Работа")
        modelContext.insert(emoji)
        modelContext.insert(tag)
        try modelContext.save()
        let entry = TearEntry(date: Date(), emojiId: emoji, tagId: tag, note: "Before")
        
        repository.addEntry(entry)
        XCTAssertTrue(repository.entries.contains { $0.id == entry.id })
        
        try repository.updateEntry(
            withId: entry.id,
            newDate: entry.date,
            newEmojiId: nil,
            newTagId: nil,
            newNote: "After"
        )
        
        XCTAssertEqual(repository.entries.first(where: { $0.id == entry.id })?.note, "After")
        
        repository.deleteEntry(entry)
        XCTAssertFalse(repository.entries.contains { $0.id == entry.id })
    }
    
    @MainActor
    func testTagRepositorySupportsAddEditDeleteAndReorder() throws {
        let container = try makeInMemoryContainer()
        let repository = TagRepository(modelContext: ModelContext(container))
        
        repository.addTag("#Один")
        repository.addTag("#Два")
        repository.addTag("#Три")
        
        guard let secondTag = repository.tags.first(where: { $0.name == "#Два" }) else {
            return XCTFail("Expected second tag to exist")
        }
        
        repository.updateTag(withId: secondTag.id, newName: "#ДваОбновлён")
        XCTAssertTrue(repository.tags.contains { $0.name == "#ДваОбновлён" })
        
        repository.moveTag(from: IndexSet(integer: 2), to: 0)
        XCTAssertEqual(repository.tags.first?.name, "#Три")
        
        repository.removeTag(secondTag.id)
        XCTAssertFalse(repository.tags.contains { $0.id == secondTag.id })
    }
    
    @MainActor
    func testEmojiRepositorySupportsAddEditDeleteAndReorder() throws {
        let container = try makeInMemoryContainer()
        let repository = EmojiRepository(modelContext: ModelContext(container))
        
        repository.addEmojiIntensity(EmojiIntensity(emoji: "🥲", color: .blue, opacity: 0.4, order: 0))
        repository.addEmojiIntensity(EmojiIntensity(emoji: "😢", color: .blue, opacity: 0.7, order: 1))
        repository.addEmojiIntensity(EmojiIntensity(emoji: "😭", color: .blue, opacity: 1.0, order: 2))
        
        var updatedEmoji = EmojiIntensity(emoji: "😶", color: .red, opacity: 0.5, order: 1)
        updatedEmoji.id = repository.emojiIntensities[1].id
        repository.updateEmojiIntensity(updatedEmoji, at: 1)
        XCTAssertEqual(repository.emojiIntensities[1].emoji, "😶")
        
        repository.moveEmojiIntensity(from: IndexSet(integer: 2), to: 0)
        XCTAssertEqual(repository.emojiIntensities.first?.emoji, "😭")
        
        repository.removeEmojiIntensity(at: 1)
        XCTAssertEqual(repository.emojiIntensities.count, 2)
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
