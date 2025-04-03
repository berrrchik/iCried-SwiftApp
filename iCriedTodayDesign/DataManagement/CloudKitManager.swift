import Foundation
import CloudKit
import Combine
import SwiftData

@Observable
class CloudKitSyncManager {
    private var cloudSubscription: AnyCancellable?
    private let container = CKContainer(identifier: "iCloud.com.berchik.iCriedTodayDesign")
    private let database: CKDatabase
    private let modelContext: ModelContext
    private var entries: [TearEntry]
    private var tags: [TagItem]
    private var emojiIntensities: [EmojiIntensity]
    
    init(modelContext: ModelContext, entries: [TearEntry], tags: [TagItem], emojiIntensities: [EmojiIntensity]) {
        self.modelContext = modelContext
        self.entries = entries
        self.tags = tags
        self.emojiIntensities = emojiIntensities
        self.database = container.privateCloudDatabase
        setupCloudKitSubscription()
    }
    
    private func setupCloudKitSubscription() {
        let subscription = NotificationCenter.default.publisher(for: .NSPersistentStoreRemoteChange)
        cloudSubscription = subscription.sink { [weak self] _ in
            guard let self = self else { return }
            print("Обнаружено изменение в CloudKit, можно запустить синхронизацию")
        }
    }
    
    func checkCloudKitStatus() {
        container.accountStatus { status, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Ошибка CloudKit: \(error.localizedDescription)")
                    return
                }
                switch status {
                case .available: print("CloudKit доступен")
                case .noAccount: print("Пользователь не вошел в iCloud")
                case .restricted: print("CloudKit ограничен")
                case .couldNotDetermine: print("Не удалось определить статус CloudKit")
                case .temporarilyUnavailable: print("CloudKit временно недоступен")
                @unknown default: print("Неизвестный статус CloudKit")
                }
            }
        }
    }
    
    func syncWithCloudKit(entries: [TearEntry], tags: [TagItem], emojiIntensities: [EmojiIntensity]) async {
        self.entries = entries
        self.tags = tags
        self.emojiIntensities = emojiIntensities
        
        print("Начинаем синхронизацию с CloudKit...")
        
        do {
            try await fetchRecordsFromCloudKit()
            try await uploadLocalChangesToCloudKit()
            try modelContext.save()
            print("Синхронизация с CloudKit завершена")
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "lastDataRefreshTime")
        } catch {
            print("Ошибка синхронизации с CloudKit: \(error.localizedDescription)")
        }
    }
    
    private func fetchRecordsFromCloudKit() async throws {
        let recordTypes = ["TearEntry", "TagItem", "EmojiIntensity"]
        
        for recordType in recordTypes {
            let query = CKQuery(recordType: recordType, predicate: NSPredicate(value: true))
            let (records, _) = try await database.records(matching: query)
            
            for (_, result) in records {
                switch result {
                case .success(let record):
                    switch recordType {
                    case "TearEntry":
                        try updateOrInsertTearEntry(from: record)
                    case "TagItem":
                        try updateOrInsertTagItem(from: record)
                    case "EmojiIntensity":
                        try updateOrInsertEmojiIntensity(from: record)
                    default:
                        break
                    }
                case .failure(let error):
                    print("Ошибка загрузки записи \(recordType): \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func uploadLocalChangesToCloudKit() async throws {
        for entry in entries {
            let record = CKRecord(recordType: "TearEntry", recordID: CKRecord.ID(recordName: entry.id.uuidString))
            record["date"] = entry.date as NSDate
            record["emojiId"] = entry.emojiId?.id.uuidString
            record["tagId"] = entry.tagId?.id.uuidString
            record["note"] = entry.note
            
            try await saveRecord(record)
        }
        
        for tag in tags {
            let record = CKRecord(recordType: "TagItem", recordID: CKRecord.ID(recordName: tag.id.uuidString))
            record["name"] = tag.name
            record["order"] = tag.order
            
            try await saveRecord(record)
        }
        
        for emoji in emojiIntensities {
            let record = CKRecord(recordType: "EmojiIntensity", recordID: CKRecord.ID(recordName: emoji.id.uuidString))
            record["emoji"] = emoji.emoji
            record["colorHex"] = emoji.colorHex
            record["opacity"] = emoji.opacity
            record["order"] = emoji.order
            
            try await saveRecord(record)
        }
    }
    
    private func saveRecord(_ record: CKRecord) async throws {
        do {
            let existingRecord = try await database.record(for: record.recordID)
            let _ = try await database.save(record)
            print("Сохранена запись: \(record.recordType) с ID \(record.recordID.recordName)")
        } catch CKError.unknownItem {
            let _ = try await database.save(record)
            print("Создана новая запись: \(record.recordType) с ID \(record.recordID.recordName)")
        } catch {
            print("Ошибка сохранения записи \(record.recordType): \(error.localizedDescription)")
            throw error
        }
    }
    
    private func updateOrInsertTearEntry(from record: CKRecord) throws {
        let id = UUID(uuidString: record.recordID.recordName) ?? UUID()
        if let existingEntry = entries.first(where: { $0.id == id }) {
            existingEntry.date = (record["date"] as? Date) ?? existingEntry.date
            existingEntry.note = (record["note"] as? String) ?? existingEntry.note
            if let emojiIdString = record["emojiId"] as? String, let emojiId = UUID(uuidString: emojiIdString) {
                existingEntry.emojiId = emojiIntensities.first { $0.id == emojiId }
            }
            if let tagIdString = record["tagId"] as? String, let tagId = UUID(uuidString: tagIdString) {
                existingEntry.tagId = tags.first { $0.id == tagId }
            }
        } else {
            let newEntry = TearEntry(
                date: (record["date"] as? Date) ?? Date(),
                emojiId: emojiIntensities.first { $0.id == UUID(uuidString: record["emojiId"] as? String ?? "") },
                tagId: tags.first { $0.id == UUID(uuidString: record["tagId"] as? String ?? "") },
                note: record["note"] as? String ?? ""
            )
            newEntry.id = id
            modelContext.insert(newEntry)
            entries.append(newEntry)
        }
    }
    
    private func updateOrInsertTagItem(from record: CKRecord) throws {
        let id = UUID(uuidString: record.recordID.recordName) ?? UUID()
        if let existingTag = tags.first(where: { $0.id == id }) {
            existingTag.name = (record["name"] as? String) ?? existingTag.name
            existingTag.order = (record["order"] as? Int) ?? existingTag.order
        } else {
            let newTag = TagItem(name: record["name"] as? String ?? "")
            newTag.id = id
            newTag.order = record["order"] as? Int ?? tags.count
            modelContext.insert(newTag)
            tags.append(newTag)
        }
    }
    
    private func updateOrInsertEmojiIntensity(from record: CKRecord) throws {
        let id = UUID(uuidString: record.recordID.recordName) ?? UUID()
        if let existingEmoji = emojiIntensities.first(where: { $0.id == id }) {
            existingEmoji.emoji = (record["emoji"] as? String) ?? existingEmoji.emoji
            existingEmoji.colorHex = (record["colorHex"] as? String) ?? existingEmoji.colorHex
            existingEmoji.opacity = (record["opacity"] as? Double) ?? existingEmoji.opacity
            existingEmoji.order = (record["order"] as? Int) ?? existingEmoji.order
        } else {
            let newEmoji = EmojiIntensity(
                emoji: record["emoji"] as? String ?? "",
                color: .blue,
                opacity: record["opacity"] as? Double ?? 1.0,
                order: record["order"] as? Int ?? emojiIntensities.count
            )
            newEmoji.id = id
            newEmoji.colorHex = (record["colorHex"] as? String) ?? ""
            modelContext.insert(newEmoji)
            emojiIntensities.append(newEmoji)
        }
    }
}
