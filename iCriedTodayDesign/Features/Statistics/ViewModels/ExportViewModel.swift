import Foundation

enum ExportError: LocalizedError {
    case noData
    case generationFailed

    var errorDescription: String? {
        switch self {
        case .noData:
            return "Нет данных для экспорта"
        case .generationFailed:
            return "Не удалось создать файл"
        }
    }
}

@MainActor
final class ExportViewModel: ObservableObject {
    @Published var isExporting = false
    @Published var exportError: ExportError?
    @Published var exportURL: URL?
    @Published var showingShareSheet = false

    private let dataManager: any StatisticsDataManaging
    private let reportGenerator: ReportGenerating

    init(dataManager: any StatisticsDataManaging, reportGenerator: ReportGenerating = ReportGenerator()) {
        self.dataManager = dataManager
        self.reportGenerator = reportGenerator
    }

    func exportPDF(filter: StatisticsFilter) async {
        let filteredEntries = dataManager.statisticsSnapshot(for: filter).diarySections.flatMap { $0.records }
        guard !filteredEntries.isEmpty else {
            exportError = .noData
            return
        }

        isExporting = true
        defer { isExporting = false }

        let summary = dataManager.buildExportSummary(filter: filter)
        let data = await reportGenerator.generatePDF(summary: summary, entries: filteredEntries)
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("iCriedToday_\(filter.year).pdf")

        do {
            try data.write(to: fileURL, options: .atomic)
            exportURL = fileURL
            showingShareSheet = true
        } catch {
            exportError = .generationFailed
        }
    }

    func exportCSV(filter: StatisticsFilter) async {
        let filteredEntries = dataManager.statisticsSnapshot(for: filter).diarySections.flatMap { $0.records }
        guard !filteredEntries.isEmpty else {
            exportError = .noData
            return
        }

        isExporting = true
        defer { isExporting = false }

        let csv = await reportGenerator.generateCSV(
            entries: filteredEntries,
            tags: dataManager.tags,
            emojis: dataManager.emojiIntensities
        )

        guard let data = csv.data(using: .utf8) else {
            exportError = .generationFailed
            return
        }

        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("iCriedToday_\(filter.year).csv")

        do {
            try data.write(to: fileURL, options: .atomic)
            exportURL = fileURL
            showingShareSheet = true
        } catch {
            exportError = .generationFailed
        }
    }

    func cleanupExportFile() {
        if let exportURL {
            try? FileManager.default.removeItem(at: exportURL)
        }
        exportURL = nil
    }
}
