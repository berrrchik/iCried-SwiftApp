import Foundation
import UIKit

protocol ReportGenerating {
    func generatePDF(summary: ExportSummary, entries: [TearEntry]) async -> Data
    func generateCSV(entries: [TearEntry], tags: [TagItem], emojis: [EmojiIntensity]) async -> String
}

final class ReportGenerator: ReportGenerating {
    func generatePDF(summary: ExportSummary, entries: [TearEntry]) async -> Data {
        let pageBounds = CGRect(x: 0, y: 0, width: 595.2, height: 841.8)
        let renderer = UIGraphicsPDFRenderer(bounds: pageBounds)
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ru_RU")
        dateFormatter.dateFormat = "dd.MM.yyyy HH:mm"
        let monthFormatter = DateFormatter()
        monthFormatter.locale = Locale(identifier: "ru_RU")
        monthFormatter.dateFormat = "LLLL yyyy"

        return renderer.pdfData { context in
            context.beginPage()
            let cgContext = context.cgContext
            var currentY: CGFloat = 60

            drawCentered(
                "Отчёт — iCriedToday",
                atY: currentY,
                in: pageBounds,
                attributes: [
                    .font: UIFont.boldSystemFont(ofSize: 24),
                    .foregroundColor: UIColor.black
                ]
            )
            currentY += 40

            drawCentered(
                summary.periodTitle,
                atY: currentY,
                in: pageBounds,
                attributes: [
                    .font: UIFont.systemFont(ofSize: 16, weight: .medium),
                    .foregroundColor: UIColor.darkGray
                ]
            )
            currentY += 40

            drawText(
                "Всего моментов грусти: \(summary.totalEntries)",
                at: CGPoint(x: 50, y: currentY),
                attributes: [
                    .font: UIFont.boldSystemFont(ofSize: 14),
                    .foregroundColor: UIColor.black
                ]
            )
            currentY += 40

            drawText(
                "Теги",
                at: CGPoint(x: 50, y: currentY),
                attributes: [
                    .font: UIFont.systemFont(ofSize: 12, weight: .semibold),
                    .foregroundColor: UIColor.black
                ]
            )
            currentY += 20

            for tag in summary.topTags {
                ensurePageSpace(currentY: &currentY, minRequiredY: 760, context: context)
                drawText(
                    "\(tag.name) — \(tag.count)",
                    at: CGPoint(x: 50, y: currentY),
                    attributes: [
                        .font: UIFont.systemFont(ofSize: 12),
                        .foregroundColor: UIColor.black
                    ]
                )
                currentY += 20
            }

            ensurePageSpace(currentY: &currentY, minRequiredY: 760, context: context)
            drawText(
                "Эмодзи",
                at: CGPoint(x: 50, y: currentY),
                attributes: [
                    .font: UIFont.systemFont(ofSize: 12, weight: .semibold),
                    .foregroundColor: UIColor.black
                ]
            )
            currentY += 20

            for item in summary.emojiStats {
                ensurePageSpace(currentY: &currentY, minRequiredY: 760, context: context)
                drawText(
                    "\(item.emoji) — \(item.count)",
                    at: CGPoint(x: 50, y: currentY),
                    attributes: [
                        .font: UIFont.systemFont(ofSize: 12),
                        .foregroundColor: UIColor.black
                    ]
                )
                currentY += 20
            }

            let sortedEntries = entries.sorted { $0.date > $1.date }
            if !sortedEntries.isEmpty {
                ensurePageSpace(currentY: &currentY, minRequiredY: 730, context: context)
                currentY += 10
                drawText(
                    "Записи по месяцам",
                    at: CGPoint(x: 50, y: currentY),
                    attributes: [
                        .font: UIFont.systemFont(ofSize: 12, weight: .semibold),
                        .foregroundColor: UIColor.black
                    ]
                )
                currentY += 22

                let groupedByMonth = Dictionary(grouping: sortedEntries) { entry in
                    let components = calendar.dateComponents([.year, .month], from: entry.date)
                    return calendar.date(from: DateComponents(year: components.year, month: components.month, day: 1)) ?? entry.date
                }
                let monthKeys = groupedByMonth.keys.sorted(by: >)

                for monthKey in monthKeys {
                    ensurePageSpace(currentY: &currentY, minRequiredY: 730, context: context)
                    drawText(
                        monthFormatter.string(from: monthKey).capitalized,
                        at: CGPoint(x: 50, y: currentY),
                        attributes: [
                            .font: UIFont.systemFont(ofSize: 12, weight: .semibold),
                            .foregroundColor: UIColor.black
                        ]
                    )
                    currentY += 18

                    for entry in groupedByMonth[monthKey] ?? [] {
                        ensurePageSpace(currentY: &currentY, minRequiredY: 740, context: context)
                        let emoji = entry.emojiId?.emoji ?? "—"
                        let tag = entry.tagId?.name ?? "без тега"
                        let note = compactNote(entry.note)
                        let line = "• \(dateFormatter.string(from: entry.date))  \(emoji)  \(tag)  \(note)"
                        drawText(
                            line,
                            at: CGPoint(x: 50, y: currentY),
                            attributes: [
                                .font: UIFont.systemFont(ofSize: 11),
                                .foregroundColor: UIColor.black
                            ]
                        )
                        currentY += 16
                    }

                    currentY += 8
                }
            }

            if let image = summary.heatmapSnapshot {
                ensurePageSpace(currentY: &currentY, minRequiredY: 620, context: context)
                image.draw(in: CGRect(x: 50, y: currentY, width: 495, height: 200))
                currentY += 220
            }

            let footerY = min(800, max(currentY + 20, 780))
            drawCentered(
                "Создано в iCriedToday",
                atY: footerY,
                in: pageBounds,
                attributes: [
                    .font: UIFont.systemFont(ofSize: 10),
                    .foregroundColor: UIColor.gray
                ]
            )

            _ = cgContext
        }
    }

    func generateCSV(entries: [TearEntry], tags: [TagItem], emojis: [EmojiIntensity]) async -> String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withFullDate, .withDashSeparatorInDate]

        let timeFormatter = DateFormatter()
        timeFormatter.locale = Locale(identifier: "en_US_POSIX")
        timeFormatter.dateFormat = "HH:mm:ss"

        let sortedEntries = entries.sorted { $0.date > $1.date }
        let header = "date,time,emoji,tag,note,emoji_opacity,emoji_order"

        let rows = sortedEntries.map { entry in
            let date = isoFormatter.string(from: entry.date)
            let time = timeFormatter.string(from: entry.date)
            let emoji = entry.emojiId?.emoji ?? ""
            let tag = entry.tagId?.name ?? ""
            let note = csvEscape(entry.note)
            let opacity = entry.emojiId.map { String($0.opacity) } ?? ""
            let order = entry.emojiId.map { String($0.order) } ?? ""
            return "\(date),\(time),\(emoji),\(tag),\(note),\(opacity),\(order)"
        }

        return ([header] + rows).joined(separator: "\n")
    }

    private func csvEscape(_ value: String) -> String {
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            return "\"\(escaped)\""
        }
        return value
    }

    private func drawCentered(_ text: String, atY y: CGFloat, in bounds: CGRect, attributes: [NSAttributedString.Key: Any]) {
        let attributed = NSAttributedString(string: text, attributes: attributes)
        let size = attributed.size()
        let rect = CGRect(
            x: bounds.midX - size.width / 2,
            y: y,
            width: size.width,
            height: size.height
        )
        attributed.draw(in: rect)
    }

    private func drawText(_ text: String, at point: CGPoint, attributes: [NSAttributedString.Key: Any]) {
        let attributed = NSAttributedString(string: text, attributes: attributes)
        attributed.draw(at: point)
    }

    private func ensurePageSpace(currentY: inout CGFloat, minRequiredY: CGFloat, context: UIGraphicsPDFRendererContext) {
        if currentY > minRequiredY {
            context.beginPage()
            currentY = 60
        }
    }

    private func compactNote(_ note: String) -> String {
        let singleLine = note
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if singleLine.count > 70 {
            return String(singleLine.prefix(67)) + "..."
        }
        return singleLine
    }
}
