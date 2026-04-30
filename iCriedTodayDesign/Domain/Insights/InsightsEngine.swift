import Foundation

protocol InsightsGenerating {
    func generateInsight(type: InsightType, filter: StatisticsFilter) -> InsightSummary?
}

final class InsightsEngine: InsightsGenerating {
    private let entries: [TearEntry]
    private let tags: [TagItem]
    private let emojiIntensities: [EmojiIntensity]
    private let calendar: Calendar

    init(entries: [TearEntry], tags: [TagItem], emojiIntensities: [EmojiIntensity], calendar: Calendar = .current) {
        self.entries = entries
        self.tags = tags
        self.emojiIntensities = emojiIntensities
        self.calendar = calendar
    }

    func generateInsight(type: InsightType, filter: StatisticsFilter) -> InsightSummary? {
        switch type {
        case .thisMonth:
            return thisMonthInsight(filter: filter)
        case .topTrigger:
            return topTriggerInsight(filter: filter)
        case .mostUsedEmoji:
            return mostUsedEmojiInsight(filter: filter)
        case .yearSummary:
            return yearSummaryInsight(filter: filter)
        }
    }

    private func thisMonthInsight(filter: StatisticsFilter) -> InsightSummary? {
        let now = Date()
        let year = calendar.component(.year, from: now)
        let month = calendar.component(.month, from: now)

        guard let currentMonthStart = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
              let previousMonthStart = calendar.date(byAdding: .month, value: -1, to: currentMonthStart) else {
            return nil
        }

        let currentCount = entries.count { isSameMonth($0.date, as: currentMonthStart) }
        let previousCount = entries.count { isSameMonth($0.date, as: previousMonthStart) }
        guard currentCount > 0 || previousCount > 0 else { return nil }

        let monthName = monthName(for: currentMonthStart)
        let secondary: String
        if currentCount == previousCount {
            secondary = "Столько же"
        } else if currentCount > previousCount {
            secondary = "На \(currentCount - previousCount) больше, чем в прошлом месяце"
        } else {
            secondary = "На \(previousCount - currentCount) меньше, чем в прошлом месяце"
        }

        return InsightSummary(
            type: .thisMonth,
            title: "Этот месяц",
            primaryStat: "За \(monthName): \(currentCount) записей",
            secondaryStat: secondary,
            emoji: nil,
            accentColorHex: nil
        )
    }

    private func topTriggerInsight(filter: StatisticsFilter) -> InsightSummary? {
        let yearEntries = entries.filter { calendar.component(.year, from: $0.date) == filter.year }
        let taggedEntries = yearEntries.compactMap { $0.tagId?.name }
        guard !taggedEntries.isEmpty else { return nil }

        let counts = Dictionary(taggedEntries.map { ($0, 1) }, uniquingKeysWith: +)
        let sorted = counts.sorted {
            if $0.value != $1.value { return $0.value > $1.value }
            return $0.key.localizedCaseInsensitiveCompare($1.key) == .orderedAscending
        }
        guard let top = sorted.first else { return nil }
        let percentage = Int((Double(top.value) / Double(taggedEntries.count)) * 100.0)

        return InsightSummary(
            type: .topTrigger,
            title: "Главный триггер",
            primaryStat: top.key,
            secondaryStat: "\(top.value) раз (\(percentage)%)",
            emoji: nil,
            accentColorHex: nil
        )
    }

    private func mostUsedEmojiInsight(filter: StatisticsFilter) -> InsightSummary? {
        let yearEntries = entries.filter {
            calendar.component(.year, from: $0.date) == filter.year && $0.emojiId != nil
        }
        guard !yearEntries.isEmpty else { return nil }

        let counts = Dictionary(yearEntries.compactMap { $0.emojiId?.id }.map { ($0, 1) }, uniquingKeysWith: +)
        guard !counts.isEmpty else { return nil }

        // Tie-break rule: lower EmojiIntensity.order wins for equal counts.
        let winnerID = counts.keys.min { lhs, rhs in
            let lhsCount = counts[lhs] ?? 0
            let rhsCount = counts[rhs] ?? 0
            if lhsCount != rhsCount { return lhsCount > rhsCount }
            let lhsOrder = emojiIntensities.first(where: { $0.id == lhs })?.order ?? Int.max
            let rhsOrder = emojiIntensities.first(where: { $0.id == rhs })?.order ?? Int.max
            return lhsOrder < rhsOrder
        }
        guard let winnerID,
              let emojiModel = emojiIntensities.first(where: { $0.id == winnerID }) else {
            return nil
        }

        return InsightSummary(
            type: .mostUsedEmoji,
            title: "Самое частое состояние",
            primaryStat: emojiModel.emoji,
            secondaryStat: "\(counts[winnerID] ?? 0) раз",
            emoji: emojiModel.emoji,
            accentColorHex: emojiModel.colorHex
        )
    }

    private func yearSummaryInsight(filter: StatisticsFilter) -> InsightSummary? {
        let yearEntries = entries.filter { calendar.component(.year, from: $0.date) == filter.year }
        let total = yearEntries.count
        guard total > 0 else { return nil }

        let monthCounts = Dictionary(yearEntries.map { (calendar.component(.month, from: $0.date), 1) }, uniquingKeysWith: +)
        let topMonth = monthCounts.max { lhs, rhs in
            if lhs.value != rhs.value { return lhs.value < rhs.value }
            return lhs.key > rhs.key
        }?.key ?? 1

        let monthDate = calendar.date(from: DateComponents(year: filter.year, month: topMonth, day: 1)) ?? Date()
        let monthName = monthName(for: monthDate)

        return InsightSummary(
            type: .yearSummary,
            title: "\(filter.year) год",
            primaryStat: "\(total) моментов грусти",
            secondaryStat: "Самый активный месяц: \(monthName)",
            emoji: nil,
            accentColorHex: nil
        )
    }

    private func isSameMonth(_ date: Date, as monthDate: Date) -> Bool {
        calendar.component(.year, from: date) == calendar.component(.year, from: monthDate) &&
        calendar.component(.month, from: date) == calendar.component(.month, from: monthDate)
    }

    private func monthName(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "LLLL"
        return formatter.string(from: date)
    }
}
