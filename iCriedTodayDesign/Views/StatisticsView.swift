import SwiftUI
import Charts

struct StatisticsView: View {
    @ObservedObject var dataManager: TearDataManager
    @State private var selectedYear = Calendar.current.component(.year, from: Date())
    @State private var showingDeleteAlert = false
    @State private var entryToDelete: TearEntry?
    
    var body: some View {
        List {
            Section {
                yearHeader
                monthlyChart
                emojiStats
                tagsList
            }
            .listRowSeparator(.hidden)
            
            // Список записей
            ForEach(groupedEntriesForYear, id: \.month) { section in
                Section(header: Text(section.month)
                    .font(.headline)
                    .foregroundColor(.gray)) {
                    ForEach(section.records.sorted(by: { $0.date > $1.date })) { entry in
                        TearCard(entry: entry, dataManager: dataManager)
                            .swipeActions(allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    entryToDelete = entry
                                    showingDeleteAlert = true
                                } label: {
                                    Label("Удалить", systemImage: "trash")
                                }
                            }
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Statistics")
        .alert("Удалить запись?", isPresented: $showingDeleteAlert) {
            Button("Отмена", role: .cancel) { }
            Button("Удалить", role: .destructive) {
                if let entry = entryToDelete {
                    dataManager.deleteEntry(entry)
                }
                entryToDelete = nil
            }
        } message: {
            Text("Это действие нельзя отменить")
        }
    }
    
    // MARK: - Вспомогательные представления
    
    private var yearHeader: some View {
        HStack {
            Text("\(dataManager.totalEntriesForYear(selectedYear)) Crying Moments")
                .font(.title2.bold())
            
            Spacer()
            
            HStack(spacing: 4) {
                YearButton(systemName: "chevron.left") {
                    changeYear(by: -1)
                }
                
                Text(String(format: "%d", selectedYear))
                    .foregroundColor(.secondary)
                
                YearButton(systemName: "chevron.right") {
                    changeYear(by: 1)
                }
            }
        }
    }
    
    private var monthlyChart: some View {
        VStack(alignment: .leading, spacing: 10) {
            Chart {
                let monthlyData = dataManager.monthlyDataByIntensity(for: selectedYear)
                ForEach(monthlyData, id: \.date) { item in
                    BarMark(
                        x: .value("Месяц", item.date, unit: .month),
                        y: .value("Количество", item.intensityCounts[2])
                    )
                    .foregroundStyle(Color.blue)

                    BarMark(
                        x: .value("Месяц", item.date, unit: .month),
                        y: .value("Количество", item.intensityCounts[1])
                    )
                    .foregroundStyle(Color.blue.opacity(0.7))

                    BarMark(
                        x: .value("Месяц", item.date, unit: .month),
                        y: .value("Количество", item.intensityCounts[0])
                    )
                    .foregroundStyle(Color.blue.opacity(0.4))
                }
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks(values: .stride(by: .month)) { _ in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: .dateTime.month(.narrow))
                }
            }
        }
    }
    
    private var emojiStats: some View {
        HStack(spacing: 20) {
            ForEach(dataManager.emojiStatistics(for: selectedYear), id: \.emoji) { stat in
                EmojiStatCard(emoji: stat.emoji, count: stat.count)
            }
        }
        .padding(.horizontal)
    }
    
    private var tagsList: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 10) {
                ForEach(dataManager.tagStatistics(for: selectedYear), id: \.tag) { tagStat in
                    TagStatView(tag: tagStat.tag)
                }
            }
        }
    }
    
    // MARK: - Вспомогательные функции
    
    private func changeYear(by value: Int) {
        selectedYear += value
    }
    
    private var groupedEntriesForYear: [(month: String, records: [TearEntry])] {
        let entriesForYear = dataManager.entriesForYear(selectedYear)
        let grouped = Dictionary(grouping: entriesForYear) { entry in
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "ru_RU")
            formatter.dateFormat = "LLLL yyyy"
            return formatter.string(from: entry.date)
        }
        return grouped.sorted { $0.key < $1.key }
            .map { (month: $0.key.uppercased(), records: $0.value) }
    }
}

// MARK: - Вспомогательные компоненты

private struct YearButton: View {
    let systemName: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .foregroundColor(.orange)
        }
        .buttonStyle(PlainButtonStyle())
        .contentShape(Rectangle())
    }
}

private struct EmojiStatCard: View {
    let emoji: String
    let count: Int
    
    var body: some View {
        VStack {
            Text(emoji)
                .font(.title)
            Text("\(count)")
                .font(.headline)
        }
        .frame(width: 90, height: 60)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.1), radius: 5)
    }
}

private struct TagStatView: View {
    let tag: String
    
    var body: some View {
        Text(tag)
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.blue.opacity(0.1))
            )
            .foregroundColor(.blue)
    }
}

#Preview {
    StatisticsView(dataManager: TearDataManager())
}
