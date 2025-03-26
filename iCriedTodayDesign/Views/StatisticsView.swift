import SwiftUI
import SwiftData
import Charts

struct StatisticsView: View {
    @Bindable var dataManager: TearDataManager
    @State private var selectedYear = Calendar.current.component(.year, from: Date())
    @State private var showingDeleteAlert = false
    @State private var entryToDelete: TearEntry?
    @State private var selectedTagIds: Set<UUID> = []
    @State private var selectedEmojiId: UUID? = nil
    @State private var selectedMonth: Date? = nil
    
    var body: some View {
        List {
            Section {
                yearHeader
                monthlyChartInteractive
                emojiStats
                tagsList
            }
            
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
    
    private var monthlyChartInteractive: some View {
        VStack(alignment: .leading, spacing: 10) {
            Chart {
                let tagIds = selectedTagIds.isEmpty ? nil : Array(selectedTagIds)
                let monthlyData = dataManager.monthlyDataByIntensity(for: selectedYear, emojiId: nil, tagIds: tagIds)
                
                ForEach(monthlyData, id: \.date) { item in
                    ForEach(Array(dataManager.emojiIntensities.enumerated()), id: \.element.id) { index, emojiIntensity in
                        if index < item.intensityCounts.count {
                            let startValue = index == 0 ? 0 : item.intensityCounts.prefix(index).reduce(0, +)
                            let endValue = startValue + item.intensityCounts[index]
                            
                            BarMark(
                                x: .value("Месяц", item.date, unit: .month),
                                yStart: .value("Начало", startValue),
                                yEnd: .value("Конец", endValue),
                                width: .ratio(0.65)
                            )
                            .foregroundStyle(emojiIntensity.color)
                            .opacity(getOpacity(for: item.date, emojiId: emojiIntensity.id))
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
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onEnded { value in
                                    selectMonth(from: value.location, in: proxy, geometry: geometry)
                                }
                        )
                }
            }
        }
    }
    
    private var emojiStats: some View {
        let tagIds = selectedTagIds.isEmpty ? nil : Array(selectedTagIds)
        let stats = dataManager.emojiStatistics(for: selectedYear, tagIds: tagIds)
        
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
                                selectedEmojiId = selectedEmojiId == emojiIntensity.id ? nil : emojiIntensity.id
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
        let filteredTags = dataManager.tagStatistics(for: selectedYear).filter { $0.count > 0 }
        
        return ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 10) {
                ForEach(filteredTags, id: \.tag) { stat in
                    if let tag = dataManager.tags.first(where: { $0.name == stat.tag }) {
                        TagButton(
                            tagName: stat.tag,
                            isSelected: selectedTagIds.contains(tag.id),
                            action: {
                                withAnimation {
                                    if selectedTagIds.contains(tag.id) {
                                        selectedTagIds.remove(tag.id)
                                    } else {
                                        selectedTagIds.insert(tag.id)
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
    
    // MARK: - Вспомогательные функции для интерактивной диаграммы
    
    private func getOpacity(for date: Date, emojiId: UUID) -> Double {
        if selectedMonth == nil && selectedEmojiId == nil { return 1.0 }
        
        let monthMatch = selectedMonth == nil || selectedMonthMatches(date)
        let emojiMatch = selectedEmojiId == nil || selectedEmojiId == emojiId
        
        return (monthMatch && emojiMatch) ? 1.0 : 0.3
    }
    
    private func selectMonth(from tapLocation: CGPoint, in proxy: ChartProxy, geometry: GeometryProxy) {
        let xPosition = tapLocation.x - geometry[proxy.plotAreaFrame].origin.x
        guard let tappedDate: Date = proxy.value(atX: xPosition) else { return }
        
        selectedMonth = selectedMonthMatches(tappedDate) ? nil : tappedDate
    }
    
    private func selectedMonthMatches(_ date: Date) -> Bool {
        guard let selectedMonth else { return false }
        return Calendar.current.isDate(selectedMonth, equalTo: date, toGranularity: .month)
    }
    
    
    // MARK: - Вспомогательные функции
    
    private func changeYear(by value: Int) {
        guard let currentIndex = dataManager.availableYears.firstIndex(of: selectedYear) else { return }
        
        let newIndex = currentIndex + value
        if newIndex >= 0, newIndex < dataManager.availableYears.count {
            selectedYear = dataManager.availableYears[newIndex]
            selectedMonth = nil
        }
    }
    
    private var groupedEntriesForYear: [(month: String, records: [TearEntry])] {
        let tagIds = selectedTagIds.isEmpty ? nil : Array(selectedTagIds)
        var entries = dataManager.entriesForYear(selectedYear, emojiId: selectedEmojiId, tagIds: tagIds)
        
        if let selectedMonth = selectedMonth {
            entries = entries.filter {
                Calendar.current.isDate($0.date, equalTo: selectedMonth, toGranularity: .month)
            }
        }
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "LLLL yyyy"
        
        let grouped = Dictionary(grouping: entries) { entry in
            formatter.string(from: entry.date)
        }
        
        return grouped.sorted { $0.key < $1.key }
            .map { (month: $0.key.uppercased(), records: $0.value) }
    }
    
    private var filteredEntriesCount: Int {
        let tagIds = selectedTagIds.isEmpty ? nil : Array(selectedTagIds)
        let entries = dataManager.entriesForYear(selectedYear, emojiId: selectedEmojiId, tagIds: tagIds)
        
        if let selectedMonth = selectedMonth {
            return entries.filter {
                Calendar.current.isDate($0.date, equalTo: selectedMonth, toGranularity: .month)
            }.count
        }
        
        return entries.count
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
    
}

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
    do {
        let container = try ModelContainer(for: TearEntry.self, EmojiIntensity.self, TagItem.self)
        let modelContext = ModelContext(container)
        let dataManager = TearDataManager(modelContext: modelContext)
        return NavigationStack {
            StatisticsView(dataManager: dataManager)
        }
    } catch {
        return Text("Ошибка при создании ModelContainer: \(error.localizedDescription)")
    }
}
