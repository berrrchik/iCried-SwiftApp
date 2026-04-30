import SwiftUI

struct SettingsView: View {
    @ObservedObject var dataManager: TearDataManager
    @StateObject private var exportViewModel: ExportViewModel
    @StateObject private var shareCardViewModel: ShareCardViewModel

    init(dataManager: TearDataManager) {
        self.dataManager = dataManager
        _exportViewModel = StateObject(wrappedValue: ExportViewModel(dataManager: dataManager))
        _shareCardViewModel = StateObject(wrappedValue: ShareCardViewModel(dataManager: dataManager))
    }

    var body: some View {
        List {
            Section("О приложении") {
                Text("Это приложение помогает отслеживать моменты грусти и эмоционального напряжения. Вы можете записывать, когда испытывали грустные эмоции, с какой интенсивностью и по какой причине, а затем анализировать эти данные для лучшего понимания своего эмоционального состояния.")
                    .font(.subheadline)
                    .foregroundStyle(.primary)
            }

            Section("Данные") {
                NavigationLink(destination: TagManagementView(dataManager: dataManager)) {
                    Label("Управление тегами", systemImage: "tag")
                }
            }

            Section("Экспорт и карточки") {
                Button {
                    Task { await exportViewModel.exportPDF(filter: exportFilter) }
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        actionTitle("Сформировать PDF отчёт", systemImage: "doc.richtext")
                        Text("Эта кнопка создаст подробный PDF-отчёт со статистикой и записями по месяцам.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .disabled(dataManager.entries.isEmpty || exportViewModel.isExporting || shareCardViewModel.isGenerating)

                Button {
                    Task { await exportViewModel.exportCSV(filter: exportFilter) }
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        actionTitle("Сформировать CSV файл", systemImage: "tablecells")
                        Text("Эта кнопка создаст таблицу CSV со всеми записями за выбранный период.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .disabled(dataManager.entries.isEmpty || exportViewModel.isExporting || shareCardViewModel.isGenerating)

                Button {
                    shareCardViewModel.presentCardSelector()
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        actionTitle("Поделиться Insight-карточкой", systemImage: "rectangle.portrait.and.arrow.right")
                        Text("Эта кнопка откроет выбор шаблона и создаст карточку для шаринга.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .disabled(dataManager.entries.isEmpty || exportViewModel.isExporting || shareCardViewModel.isGenerating)
            }
        }
        .navigationTitle("Настройки")
        .overlay {
            if exportViewModel.isExporting {
                ProgressView("Создаём файл…")
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(.regularMaterial))
            }
            if shareCardViewModel.isGenerating {
                ProgressView("Создаём карточку…")
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(.regularMaterial))
            }
        }
        .sheet(isPresented: $exportViewModel.showingShareSheet, onDismiss: {
            exportViewModel.cleanupExportFile()
        }) {
            if let url = exportViewModel.exportURL {
                ShareSheet(activityItems: [url])
            }
        }
        .sheet(isPresented: $shareCardViewModel.showingCardSelector) {
            CardTemplateSelector { type in
                Task { await shareCardViewModel.generateCard(type: type, filter: exportFilter) }
            }
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $shareCardViewModel.showingShareSheet, onDismiss: {
            shareCardViewModel.dismissShareSheet()
        }) {
            if let image = shareCardViewModel.generatedCard {
                ShareSheet(activityItems: [image])
            }
        }
        .alert(
            "Ошибка экспорта",
            isPresented: Binding(
                get: { exportViewModel.exportError != nil },
                set: { if !$0 { exportViewModel.exportError = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(exportViewModel.exportError?.localizedDescription ?? "")
        }
        .alert(
            "Ошибка генерации",
            isPresented: Binding(
                get: { shareCardViewModel.generationError != nil },
                set: { if !$0 { shareCardViewModel.generationError = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(shareCardViewModel.generationError ?? "")
        }
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
        return "\(version) (\(build))"
    }

    private var exportFilter: StatisticsFilter {
        StatisticsFilter(
            year: dataManager.availableYears.last ?? Calendar.current.component(.year, from: Date()),
            selectedMonth: nil,
            selectedEmojiID: nil,
            selectedTagIDs: []
        )
    }

    private func actionTitle(_ title: String, systemImage: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .foregroundColor(.blue)
            Text(title)
                .foregroundColor(.primary)
        }
        .font(.body)
    }
}
