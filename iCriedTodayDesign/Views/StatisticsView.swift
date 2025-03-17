import SwiftUI
import Charts

struct StatisticsView: View {
    @ObservedObject var dataManager: TearDataManager
    @State private var selectedYear = Calendar.current.component(.year, from: Date())
    @State private var showingDeleteAlert = false
    @State private var entryToDelete: TearEntry?
    @State private var selectedTagId: UUID? = nil
    @State private var selectedEmojiId: UUID? = nil
    @State private var selectedMonth: String? = nil
    
    var body: some View {
        List {
            Section {
                yearHeader
                monthlyChart
                emojiStats
                tagsList
            }
            
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
        .navigationTitle("Статистика")
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
            Text("\(filteredEntriesCount) \(formatCryingMoments(count: filteredEntriesCount))")
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
                let monthlyData = dataManager.monthlyDataByIntensity(for: selectedYear, emojiId: selectedEmojiId, tagId: selectedTagId)
                ForEach(monthlyData, id: \.date) { item in
                    ForEach(Array(dataManager.emojiIntensities.enumerated()).reversed(), id: \.element.id) { index, emojiIntensity in
                        if index < item.intensityCounts.count {
                            BarMark(
                                x: .value("Месяц", item.date, unit: .month),
                                y: .value("Количество", item.intensityCounts[index])
                            )
                            .foregroundStyle(emojiIntensity.color)
                        }
                    }
                }
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks(values: .stride(by: .month)) { _ in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: .dateTime.month(.narrow).locale(Locale(identifier: "ru_RU")))
                }
            }
        }
    }
    
    private var emojiStats: some View {
        let stats = dataManager.emojiStatistics(for: selectedYear)
        return ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 20) {
                ForEach(0..<min(stats.count, dataManager.emojiIntensities.count), id: \.self) { index in
                    let stat = stats[index]
                    let emojiIntensity = dataManager.emojiIntensities[index]
                    EmojiButton(
                        emoji: stat.emoji,
                        count: stat.count,
                        color: emojiIntensity.color,
                        isSelected: selectedEmojiId == emojiIntensity.id,
                        action: {
                            withAnimation {
                                if selectedEmojiId == emojiIntensity.id {
                                    selectedEmojiId = nil
                                } else {
                                    selectedEmojiId = emojiIntensity.id
                                    selectedTagId = nil
                                }
                            }
                        },
                        isCountVisible: true,
                        fontSize: 28
                    )
                }
            }
        }
        .padding(.horizontal)
    }
    
    private var tagsList: some View {
        let stats = dataManager.tagStatistics(for: selectedYear)
        
        let filteredTags = stats.filter { $0.count > 0 }
        
        return ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 10) {
                ForEach((filteredTags), id: \.tag) { stat in
                    if let tag = dataManager.tags.first(where: { $0.name == stat.tag }) {
                        TagButton(
                            tagName: stat.tag,
                            isSelected: selectedTagId == tag.id,
                            action: {
                                withAnimation {
                                    if selectedTagId == tag.id {
                                        selectedTagId = nil
                                    } else {
                                        selectedTagId = tag.id
                                        selectedEmojiId = nil
                                    }
                                }
                            }
                        )
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Вспомогательные функции
    
    private func changeYear(by value: Int) {
        guard let currentIndex = dataManager.availableYears.firstIndex(of: selectedYear) else { return }
        
        let newIndex = currentIndex + value
        if newIndex >= 0, newIndex < dataManager.availableYears.count {
            selectedYear = dataManager.availableYears[newIndex]
        }
    }
    
    private var groupedEntriesForYear: [(month: String, records: [TearEntry])] {
        let entriesForYear = dataManager.entriesForYear(selectedYear, emojiId: selectedEmojiId, tagId: selectedTagId)
        let grouped = Dictionary(grouping: entriesForYear) { entry in
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "ru_RU")
            formatter.dateFormat = "LLLL yyyy"
            return formatter.string(from: entry.date)
        }
        return grouped.sorted { $0.key < $1.key }
            .map { (month: $0.key.uppercased(), records: $0.value) }
    }
    
    func formatCryingMoments(count: Int) -> String {
        let lastDigit = count % 10
        let lastTwoDigits = count % 100
        
        if lastTwoDigits >= 11 && lastTwoDigits <= 19 {
            return "Моментов грусти"
        } else if lastDigit == 1 {
            return "Момент грусти"
        } else if lastDigit >= 2 && lastDigit <= 4 {
            return "Момента грусти"
        } else {
            return "Моментов грусти"
        }
    }
    
    private var filteredEntriesCount: Int {
        dataManager.entriesForYear(selectedYear, emojiId: selectedEmojiId, tagId: selectedTagId).count
    }

}

// MARK: - Вспомогательные компоненты

private struct YearButton: View {
    let systemName: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .foregroundColor(.blue)
        }
        .buttonStyle(PlainButtonStyle())
        .contentShape(Rectangle())
    }
}

#Preview {
    NavigationView {
        StatisticsView(dataManager: TearDataManager())
    }
}
