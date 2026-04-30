import Foundation

@MainActor
final class InitialDataSeeder {
    private let emojiRepository: any EmojiRepositoryProtocol
    private let tagRepository: any TagRepositoryProtocol
    private let entryRepository: any EntryRepositoryProtocol
    
    init(
        emojiRepository: any EmojiRepositoryProtocol,
        tagRepository: any TagRepositoryProtocol,
        entryRepository: any EntryRepositoryProtocol
    ) {
        self.emojiRepository = emojiRepository
        self.tagRepository = tagRepository
        self.entryRepository = entryRepository
    }
    
    func seedIfNeeded() {
        emojiRepository.ensureDefaultEmojiScale()
        
        if tagRepository.tags.isEmpty {
            let defaultTags = ["#Здоровье", "#Одиночество", "#Работа", "#Семья", "#Фильмы"]
            defaultTags.forEach { tagRepository.addTag($0) }
        }

        #if DEBUG
        seedDebugEntriesIfNeeded()
        #endif
    }

    #if DEBUG
    private func seedDebugEntriesIfNeeded() {
        guard entryRepository.entries.isEmpty else { return }

        let notes = [
            "Тяжёлый день, не смогла сдержаться",
            "Поссорились дома, сильно задело",
            "После фильма накрыло эмоциями",
            "Накопилась усталость за неделю",
            "Неожиданно стало очень тревожно",
            "Разговор с близким помог немного отпустить",
            "Слёзы из-за перегруза на работе",
            "Поймала себя на чувстве одиночества"
        ]

        let calendar = Calendar.current
        let now = Date()
        let emojis = emojiRepository.emojiIntensities
        let tags = tagRepository.tags

        guard !emojis.isEmpty else { return }

        for dayOffset in 0..<240 {
            guard let day = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { continue }
            let entriesPerDay = (dayOffset % 4 == 0) ? 2 : (dayOffset % 7 == 0 ? 3 : 1)

            for index in 0..<entriesPerDay {
                let hour = 9 + ((dayOffset + index * 3) % 12)
                let minute = (dayOffset * 7 + index * 11) % 60
                guard let dated = calendar.date(
                    bySettingHour: hour,
                    minute: minute,
                    second: 0,
                    of: day
                ) else { continue }

                let emoji = emojis[(dayOffset + index) % emojis.count]
                let tag = tags.isEmpty ? nil : tags[(dayOffset + index * 2) % tags.count]
                let note = notes[(dayOffset + index) % notes.count]

                entryRepository.addEntry(
                    TearEntry(
                        date: dated,
                        emojiId: emoji,
                        tagId: tag,
                        note: note
                    )
                )
            }
        }

        debugLog("DEBUG: сгенерированы тестовые записи (\(entryRepository.entries.count))")
    }
    #endif
}
