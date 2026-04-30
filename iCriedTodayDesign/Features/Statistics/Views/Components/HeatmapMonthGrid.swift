import SwiftUI

struct HeatmapMonthGrid: View {
    let daySummaries: [HeatmapDaySummary]
    let year: Int
    let month: Int
    let onDayTap: (Date) -> Void

    private var paddingCells: Int {
        let calendar = Calendar(identifier: .gregorian)
        guard let firstDay = calendar.date(from: DateComponents(year: year, month: month, day: 1)) else {
            return 0
        }
        let weekday = calendar.component(.weekday, from: firstDay)
        return (weekday + 5) % 7
    }

    private var monthTitle: String {
        daySummaries.first?.date.formatted(.dateTime.month(.wide).locale(Locale(identifier: "ru_RU"))) ?? ""
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(monthTitle.capitalized)
                .font(.headline)
                .padding(.bottom, 2)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(minimum: 32)), count: 7), spacing: 4) {
                ForEach(["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"], id: \.self) { label in
                    Text(label)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                ForEach(0..<paddingCells, id: \.self) { _ in
                    HeatmapDayCell(summary: nil, onTap: {})
                }

                ForEach(daySummaries) { summary in
                    HeatmapDayCell(summary: summary, onTap: { onDayTap(summary.date) })
                }
            }
        }
    }
}
