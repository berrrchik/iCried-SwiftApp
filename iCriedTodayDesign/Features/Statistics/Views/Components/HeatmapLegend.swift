import SwiftUI

struct HeatmapLegend: View {
    var body: some View {
        HStack(spacing: 4) {
            Text("Нет записей")
                .font(.caption2)
                .foregroundColor(.secondary)

            RoundedRectangle(cornerRadius: 3)
                .fill(Color(.systemFill))
                .frame(width: 14, height: 14)

            RoundedRectangle(cornerRadius: 3)
                .fill(Color.accentColor.opacity(0.25))
                .frame(width: 14, height: 14)

            RoundedRectangle(cornerRadius: 3)
                .fill(Color.accentColor.opacity(0.50))
                .frame(width: 14, height: 14)

            RoundedRectangle(cornerRadius: 3)
                .fill(Color.accentColor.opacity(0.75))
                .frame(width: 14, height: 14)

            RoundedRectangle(cornerRadius: 3)
                .fill(Color.accentColor.opacity(1.00))
                .frame(width: 14, height: 14)

            Text("6+")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Шкала плотности: от нет записей до 6 и более")
    }
}
