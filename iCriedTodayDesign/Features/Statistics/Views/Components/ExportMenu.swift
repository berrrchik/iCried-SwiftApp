import SwiftUI

struct ExportMenu: View {
    let onExportPDF: () -> Void
    let onExportCSV: () -> Void

    var body: some View {
        Menu {
            Button {
                onExportPDF()
            } label: {
                Label("PDF отчёт", systemImage: "doc.richtext")
            }

            Button {
                onExportCSV()
            } label: {
                Label("CSV таблица", systemImage: "tablecells")
            }
        } label: {
            Image(systemName: "square.and.arrow.up")
        }
        .accessibilityLabel("Экспорт данных")
        .accessibilityIdentifier("statistics_export_button")
    }
}
