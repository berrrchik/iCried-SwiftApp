import Foundation

struct EntryGrouper {
    private let calendar: Calendar
    private let formatter: DateFormatter
    
    init(
        calendar: Calendar = .current,
        locale: Locale = Locale(identifier: "ru_RU")
    ) {
        self.calendar = calendar
        self.formatter = DateFormatter()
        self.formatter.locale = locale
        self.formatter.dateFormat = "LLLL yyyy"
    }
    
    func group(_ entries: [TearEntry]) -> [DiarySection] {
        let grouped = Dictionary(grouping: entries) { entry in
            monthStart(for: entry.date)
        }
        
        return grouped
            .sorted { $0.key > $1.key }
            .map { monthStart, records in
                DiarySection(
                    monthStart: monthStart,
                    monthTitle: formatter.string(from: monthStart).uppercased(),
                    records: records.sorted { $0.date > $1.date }
                )
            }
    }
    
    func monthStart(for date: Date) -> Date {
        let components = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: components) ?? date
    }
    
    func matchesMonth(_ date: Date, selectedMonth: Date?) -> Bool {
        guard let selectedMonth else { return false }
        return calendar.isDate(selectedMonth, equalTo: date, toGranularity: .month)
    }
}
