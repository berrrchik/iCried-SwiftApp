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
    func testStatisticsViewModelUpdatesSnapshotForFilterTransitions() throws {
        let container = try makeInMemoryContainer()
        let manager = TearDataManager(modelContext: ModelContext(container))
        let workTag = TagItem(name: "#Phase5Work")
        let familyTag = TagItem(name: "#Phase5Family")
        
        manager.addTag(workTag.name)
        manager.addTag(familyTag.name)
        
        let savedWorkTag = try XCTUnwrap(manager.tags.first(where: { $0.name == workTag.name }))
        let savedFamilyTag = try XCTUnwrap(manager.tags.first(where: { $0.name == familyTag.name }))
        let savedLightEmoji = try XCTUnwrap(manager.emojiIntensities.first(where: { $0.emoji == "🥲" }))
        let savedDeepEmoji = try XCTUnwrap(manager.emojiIntensities.first(where: { $0.emoji == "😭" }))
        
        manager.addEntry(makeEntry(year: 2040, month: 4, day: 1, note: "Work April", emoji: savedDeepEmoji, tag: savedWorkTag))
        manager.addEntry(makeEntry(year: 2040, month: 4, day: 2, note: "Family April", emoji: savedLightEmoji, tag: savedFamilyTag))
        manager.addEntry(makeEntry(year: 2040, month: 5, day: 1, note: "Work May", emoji: savedDeepEmoji, tag: savedWorkTag))
        
        let viewModel = StatisticsViewModel(dataManager: manager)
        viewModel.selectedYear = 2040
        
        XCTAssertEqual(viewModel.snapshot.filteredEntriesCount, 3)
        
        viewModel.toggleTag(savedWorkTag.id)
        XCTAssertEqual(viewModel.snapshot.filteredEntriesCount, 2)
        
        viewModel.toggleEmoji(savedDeepEmoji.id)
        XCTAssertEqual(viewModel.snapshot.filteredEntriesCount, 2)
        
        viewModel.toggleMonth(Calendar(identifier: .gregorian).date(from: DateComponents(year: 2040, month: 4, day: 1))!)
        XCTAssertEqual(viewModel.snapshot.filteredEntriesCount, 1)
        
        viewModel.toggleMonth(Calendar(identifier: .gregorian).date(from: DateComponents(year: 2040, month: 4, day: 1))!)
        XCTAssertEqual(viewModel.snapshot.filteredEntriesCount, 2)
    }
    
    @MainActor
    func testTearFormViewModelValidatesAndBuildsSavePayload() {
        let tag = TagItem(name: "#Form")
        let emoji = EmojiIntensity(emoji: "😢", color: .blue, opacity: 0.7, order: 0)
        let viewModel = TearFormViewModel(
            availableTags: [tag],
            availableEmojiIntensities: [emoji],
            selectedEmoji: emoji,
            selectedTag: tag,
            note: "   "
        )
        
        XCTAssertFalse(viewModel.isFormValid)
        XCTAssertNil(viewModel.savePayload)
        
        viewModel.note = "  Valid note  "
        
        XCTAssertTrue(viewModel.isFormValid)
        XCTAssertEqual(viewModel.savePayload?.note, "Valid note")
        XCTAssertEqual(viewModel.savePayload?.selectedTag?.id, tag.id)
        XCTAssertEqual(viewModel.savePayload?.selectedEmoji?.id, emoji.id)
    }
    
    @MainActor
    func testDiaryViewModelDeletesPendingEntry() throws {
        let container = try makeInMemoryContainer()
        let manager = TearDataManager(modelContext: ModelContext(container))
        manager.addTag("#DiaryDelete")
        let tag = try XCTUnwrap(manager.tags.first(where: { $0.name == "#DiaryDelete" }))
        let savedEmoji = try XCTUnwrap(manager.emojiIntensities.first(where: { $0.emoji == "😢" }))
        let entry = makeEntry(year: 2041, note: "Delete me", emoji: savedEmoji, tag: tag)
        manager.addEntry(entry)
        
        let viewModel = DiaryViewModel(dataManager: manager)
        viewModel.presentDelete(for: entry)
        
        XCTAssertTrue(viewModel.showingDeleteAlert)
        
        viewModel.confirmDelete()
        
        XCTAssertFalse(viewModel.showingDeleteAlert)
        XCTAssertFalse(manager.entries.contains { $0.id == entry.id })
    }
    
    @MainActor
    func testTagManagementViewModelSupportsEditMoveAndDeleteFlows() throws {
        let container = try makeInMemoryContainer()
        let manager = TearDataManager(modelContext: ModelContext(container))
        manager.addTag("#Phase5A")
        manager.addTag("#Phase5B")
        
        let viewModel = TagManagementViewModel(dataManager: manager)
        let firstTag = try XCTUnwrap(viewModel.tags.first(where: { $0.name == "#Phase5A" }))
        let secondTag = try XCTUnwrap(viewModel.tags.first(where: { $0.name == "#Phase5B" }))
        
        viewModel.presentEdit(for: firstTag)
        XCTAssertEqual(viewModel.tagToEdit?.id, firstTag.id)
        viewModel.dismissEdit()
        XCTAssertNil(viewModel.tagToEdit)
        
        let fromIndex = try XCTUnwrap(viewModel.tags.firstIndex(where: { $0.id == secondTag.id }))
        let toIndex = try XCTUnwrap(viewModel.tags.firstIndex(where: { $0.id == firstTag.id }))
        viewModel.moveTags(from: IndexSet(integer: fromIndex), to: toIndex)
        
        let movedIndex = try XCTUnwrap(viewModel.tags.firstIndex(where: { $0.id == secondTag.id }))
        XCTAssertLessThanOrEqual(movedIndex, toIndex)
        
        viewModel.presentDelete(for: firstTag)
        XCTAssertTrue(viewModel.showingDeleteAlert)
        viewModel.confirmDelete()
        
        XCTAssertFalse(viewModel.tags.contains { $0.id == firstTag.id })
    }
    
    @MainActor
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
        let emoji = try XCTUnwrap(manager.emojiIntensities.first(where: { $0.emoji == "😢" }))
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
    func testEmojiRepositoryEnsuresDefaultScale() throws {
        let container = try makeInMemoryContainer()
        let repository = EmojiRepository(modelContext: ModelContext(container))

        repository.ensureDefaultEmojiScale()
        XCTAssertEqual(repository.emojiIntensities.map(\.emoji), ["🥲", "😢", "😭"])

        repository.ensureDefaultEmojiScale()
        XCTAssertEqual(repository.emojiIntensities.count, 3)
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
