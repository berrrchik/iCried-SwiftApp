import SwiftUI

struct CardTemplateSelector: View {
    @Environment(\.dismiss) private var dismiss
    let onSelect: (InsightType) -> Void

    var body: some View {
        NavigationView {
            List {
                ForEach(InsightType.allCases) { type in
                    Button {
                        onSelect(type)
                    } label: {
                        HStack {
                            Image(systemName: type.systemImageName)
                                .foregroundColor(.blue)
                                .frame(width: 28)
                            VStack(alignment: .leading) {
                                Text(type.displayTitle)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text(type.displaySubtitle)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .accessibilityIdentifier("card_template_\(String(describing: type))")
                }
            }
            .navigationTitle("Выбери карточку")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Закрыть") {
                        dismiss()
                    }
                }
            }
        }
    }
}
