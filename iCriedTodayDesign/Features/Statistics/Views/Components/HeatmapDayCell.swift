import SwiftUI

struct HeatmapDayCell: View {
    let summary: HeatmapDaySummary?
    let onTap: () -> Void

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(cellColor)

            Text(dayLabel)
                .font(.caption2)
                .foregroundColor(summary == nil ? .clear : .primary)
        }
        .frame(minWidth: 32, minHeight: 32)
        .onTapGesture {
            if summary != nil {
                onTap()
            }
        }
        .accessibilityLabel(accessibilityText)
        .accessibilityIdentifier("heatmap_day_\(summary?.date.timeIntervalSince1970 ?? 0)")
    }

    private var dayLabel: String {
        guard let date = summary?.date else { return "" }
        return String(Calendar.current.component(.day, from: date))
    }

    private var cellColor: Color {
        guard let count = summary?.entryCount else { return .clear }
        switch count {
        case 0: return Color(.systemFill)
        case 1: return Color.accentColor.opacity(0.25)
        case 2...3: return Color.accentColor.opacity(0.50)
        case 4...5: return Color.accentColor.opacity(0.75)
        default: return Color.accentColor.opacity(1.00)
        }
    }

    private var accessibilityText: String {
        guard let summary else { return "" }
        let day = Calendar.current.component(.day, from: summary.date)
        return "День \(day), \(summary.entryCount) записей"
    }
}
