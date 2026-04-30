import Foundation

@MainActor
final class HeatmapViewModel: ObservableObject {
    @Published var selectedYear: Int
    @Published var selectedMonth: Int
    @Published var selectedDay: Date? = nil
    @Published var showingDayDetail = false
    @Published private(set) var daySummaries: [HeatmapDaySummary] = []

    private let dataManager: any StatisticsDataManaging

    init(dataManager: any StatisticsDataManaging) {
        self.dataManager = dataManager
        self.selectedYear = dataManager.availableYears.last ?? Calendar.current.component(.year, from: Date())
        self.selectedMonth = Calendar.current.component(.month, from: Date())
        self.selectedMonth = defaultMonth(for: selectedYear)
        loadDaySummaries()
    }

    func loadDaySummaries() {
        let engine = HeatmapEngine(
            entries: dataManager.entries,
            emojiIntensities: dataManager.emojiIntensities
        )
        daySummaries = engine.daySummaries(for: selectedYear, month: selectedMonth)
    }

    func selectDay(_ date: Date) {
        selectedDay = date
        showingDayDetail = true
    }

    func dismissDayDetail() {
        showingDayDetail = false
        selectedDay = nil
    }

    func entriesForSelectedDay() -> [TearEntry] {
        guard let day = selectedDay else { return [] }
        return dataManager.entriesForDay(day)
    }

    func changeYear(by offset: Int) {
        guard let currentIndex = dataManager.availableYears.firstIndex(of: selectedYear) else { return }
        let newIndex = currentIndex + offset
        guard dataManager.availableYears.indices.contains(newIndex) else { return }
        selectedYear = dataManager.availableYears[newIndex]
        selectedMonth = defaultMonth(for: selectedYear)
        loadDaySummaries()
    }

    func selectMonth(_ month: Int) {
        guard availableMonths.contains(month) else { return }
        selectedMonth = month
        loadDaySummaries()
    }

    func goToPreviousMonth() {
        guard let index = availableMonths.firstIndex(of: selectedMonth) else { return }
        if index > 0 {
            selectedMonth = availableMonths[index - 1]
            loadDaySummaries()
            return
        }

        guard let yearIndex = dataManager.availableYears.firstIndex(of: selectedYear), yearIndex > 0 else { return }
        let previousYear = dataManager.availableYears[yearIndex - 1]
        selectedYear = previousYear
        selectedMonth = 12
        loadDaySummaries()
    }

    func goToNextMonth() {
        guard let index = availableMonths.firstIndex(of: selectedMonth) else { return }
        if index < availableMonths.count - 1 {
            selectedMonth = availableMonths[index + 1]
            loadDaySummaries()
            return
        }

        guard let yearIndex = dataManager.availableYears.firstIndex(of: selectedYear),
              yearIndex < dataManager.availableYears.count - 1 else { return }
        let nextYear = dataManager.availableYears[yearIndex + 1]
        selectedYear = nextYear
        selectedMonth = defaultMonth(for: nextYear)
        loadDaySummaries()
    }

    func syncFromDataManager() {
        if !dataManager.availableYears.contains(selectedYear),
           let latestYear = dataManager.availableYears.last {
            selectedYear = latestYear
        }

        if !availableMonths.contains(selectedMonth) {
            selectedMonth = defaultMonth(for: selectedYear)
        }
        loadDaySummaries()
    }

    var availableMonths: [Int] {
        let calendar = Calendar.current
        let now = Date()
        let currentYear = calendar.component(.year, from: now)
        let currentMonth = calendar.component(.month, from: now)

        if selectedYear != currentYear {
            return Array(1...12)
        }

        let futureMonthsWithEntries = Set(
            dataManager.entries.compactMap { entry -> Int? in
                let year = calendar.component(.year, from: entry.date)
                let month = calendar.component(.month, from: entry.date)
                guard year == currentYear, month > currentMonth else { return nil }
                return month
            }
        )

        let baseMonths = Set(1...currentMonth)
        return Array(baseMonths.union(futureMonthsWithEntries)).sorted()
    }

    private func defaultMonth(for year: Int) -> Int {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        let currentMonth = calendar.component(.month, from: Date())

        if year == currentYear, availableMonths.contains(currentMonth) {
            return currentMonth
        }

        return availableMonths.last ?? 1
    }
}
