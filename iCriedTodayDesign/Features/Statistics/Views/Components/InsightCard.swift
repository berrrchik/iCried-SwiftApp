import SwiftUI

struct InsightCard: View {
    let insight: InsightSummary

    var body: some View {
        ZStack {
            backgroundGradient
            VStack(alignment: .leading, spacing: 12) {
                Spacer()

                if let emoji = insight.emoji {
                    Text(emoji)
                        .font(.system(size: 64))
                }

                Text(insight.title)
                    .font(.caption)
                    .textCase(.uppercase)
                    .foregroundColor(.white.opacity(0.7))

                Text(insight.primaryStat)
                    .font(.title.bold())
                    .foregroundColor(.white)

                if let secondary = insight.secondaryStat {
                    Text(secondary)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.85))
                }

                Spacer()

                HStack {
                    Spacer()
                    Text("iCriedToday")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .padding(24)
        }
        .frame(width: 300, height: 375)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var backgroundGradient: some View {
        let base = Color(hex: insight.accentColorHex ?? "#5B7BE9") ?? Color.accentColor
        return LinearGradient(
            colors: [base, base.opacity(0.6)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

#Preview {
    VStack(spacing: 16) {
        InsightCard(insight: InsightSummary(type: .thisMonth, title: "Этот месяц", primaryStat: "За апрель: 18 записей", secondaryStat: "На 3 больше, чем в прошлом месяце", emoji: nil, accentColorHex: nil))
        InsightCard(insight: InsightSummary(type: .topTrigger, title: "Главный триггер", primaryStat: "#Работа", secondaryStat: "12 раз (40%)", emoji: nil, accentColorHex: nil))
        InsightCard(insight: InsightSummary(type: .mostUsedEmoji, title: "Самое частое состояние", primaryStat: "🥲", secondaryStat: "21 раз", emoji: "🥲", accentColorHex: "#5B7BE9"))
        InsightCard(insight: InsightSummary(type: .yearSummary, title: "2026 год", primaryStat: "176 моментов грусти", secondaryStat: "Самый активный месяц: апрель", emoji: nil, accentColorHex: nil))
    }
}
