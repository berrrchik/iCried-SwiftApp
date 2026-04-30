import Foundation

struct HeatmapEngine {
    private let entries: [TearEntry]
    private let emojiIntensities: [EmojiIntensity]
    private let calendar: Calendar

    init(entries: [TearEntry], emojiIntensities: [EmojiIntensity], calendar: Calendar = .current) {
        self.entries = entries
        self.emojiIntensities = emojiIntensities
        self.calendar = calendar
    }

    func daySummaries(for year: Int, month: Int? = nil) -> [HeatmapDaySummary] {
        if let month {
            return daySummariesForMonth(year: year, month: month)
        }

        return (1...12)
            .flatMap { daySummariesForMonth(year: year, month: $0) }
            .sorted { $0.date < $1.date }
    }

    func intensityLevel(for score: Double) -> Int {
        if score <= 0 { return 0 }
        if score <= 1 { return 1 }
        if score <= 3 { return 2 }
        if score <= 5 { return 3 }
        return 4
    }

    private func daySummariesForMonth(year: Int, month: Int) -> [HeatmapDaySummary] {
        guard let monthStart = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
              let dayRange = calendar.range(of: .day, in: .month, for: monthStart) else {
            return []
        }

        return dayRange.compactMap { day -> HeatmapDaySummary? in
            guard let date = calendar.date(from: DateComponents(year: year, month: month, day: day)) else {
                return nil
            }
            return summaryForDay(date)
        }
    }

    private func summaryForDay(_ date: Date) -> HeatmapDaySummary {
        let start = calendar.startOfDay(for: date)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else {
            return HeatmapDaySummary(
                id: stableUUID(from: date.description),
                date: start,
                entryCount: 0,
                dominantEmojiID: nil,
                intensityScore: 0.0
            )
        }

        let dayEntries = entries.filter { $0.date >= start && $0.date < end }
        let entryCount = dayEntries.count

        let opacities = dayEntries.compactMap { entry -> Double? in
            guard let emojiID = entry.emojiId?.id else { return nil }
            return emojiIntensities.first(where: { $0.id == emojiID })?.opacity
        }

        let intensityScore: Double
        if entryCount == 0 || opacities.isEmpty {
            intensityScore = 0.0
        } else {
            intensityScore = opacities.reduce(0, +) / Double(opacities.count)
        }

        let dominantEmojiID = dominantEmoji(for: dayEntries)

        return HeatmapDaySummary(
            id: stableUUID(from: date.description),
            date: start,
            entryCount: entryCount,
            dominantEmojiID: dominantEmojiID,
            intensityScore: intensityScore
        )
    }

    private func dominantEmoji(for dayEntries: [TearEntry]) -> UUID? {
        let emojiCounts = Dictionary(dayEntries.compactMap { $0.emojiId?.id }.map { ($0, 1) }, uniquingKeysWith: +)
        guard !emojiCounts.isEmpty else { return nil }

        return emojiCounts.keys.min { lhs, rhs in
            let lhsCount = emojiCounts[lhs] ?? 0
            let rhsCount = emojiCounts[rhs] ?? 0
            if lhsCount != rhsCount {
                return lhsCount > rhsCount
            }

            let lhsOrder = emojiIntensities.first(where: { $0.id == lhs })?.order ?? Int.max
            let rhsOrder = emojiIntensities.first(where: { $0.id == rhs })?.order ?? Int.max
            return lhsOrder < rhsOrder
        }
    }
}
