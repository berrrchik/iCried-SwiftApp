import SwiftUI
import Charts

struct StatisticsView: View {
    @Bindable var dataManager: TearDataManager
    @State private var selectedYear = Calendar.current.component(.year, from: Date())
    @State private var showingDeleteAlert = false
    @State private var entryToDelete: TearEntry?
    @State private var selectedTags: Set<TagItem> = []
    @State private var selectedEmoji: EmojiIntensity? = nil
    @State private var selectedMonth: Date? = nil
    @State private var showingAddTear = false
    
    var body: some View {
        Group {
            if dataManager.entries.isEmpty {
                EmptyStateView(
                    title: "Нет данных для анализа",
                    subtitle: "Добавьте свой первый момент грусти, чтобы начать отслеживать свои эмоции",
                    icon: "chart.bar.fill",
                    buttonTitle: "Добавить запись",
                    action: { showingAddTear = true }
                )
            } else {
                List {
                    Section {
                        yearHeader
                        monthlyChartInteractive
                        emojiStats
                        tagsList
                    }
                    
                    ForEach(statisticsSnapshot.diarySections) { section in
                        Section(header: Text(section.monthTitle)
                            .font(.headline)
                            .foregroundColor(.gray)) {
                                ForEach(section.records) { entry in
                                    TearCard(entry: entry, dataManager: dataManager)
                                        .swipeActions(allowsFullSwipe: false) {
                                            Button() {
                                                entryToDelete = entry
                                                showingDeleteAlert = true
                                            } label: {
                                                Label("Удалить", systemImage: "trash")
                                            }
                                            .tint(.red)
                                        }
                                }
                            }
                    }
                }
                .listStyle(InsetGroupedListStyle())
                .background(Color(.systemGroupedBackground))
                .id(dataManager.refreshTrigger)
            }
        }
        .navigationTitle("Статистика")
        .sheet(isPresented: $showingAddTear) {
            AddTearView(dataManager: dataManager)
        }
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
    
    private var yearHeader: some View {
        HStack {
            Text("\(statisticsSnapshot.filteredEntriesCount) \(dataManager.cryingMomentsLabel(for: statisticsSnapshot.filteredEntriesCount))")
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
                ForEach(statisticsSnapshot.monthPoints) { item in
                    let reversedIntensityCounts = Array(item.intensityCounts.reversed())
                    ForEach(Array(dataManager.emojiIntensities.reversed().enumerated()), id: \.element.id) { index, emojiIntensity in
                        if index < reversedIntensityCounts.count {
                            let startValue = index == 0 ? 0 : reversedIntensityCounts.prefix(index).reduce(0, +)
                            let endValue = startValue + reversedIntensityCounts[index]
                            
                            BarMark(
                                x: .value("Месяц", item.monthStart, unit: .month),
                                yStart: .value("Начало", startValue),
                                yEnd: .value("Конец", endValue),
                                width: .ratio(0.65)
                            )
                            .foregroundStyle(emojiIntensity.color)
                            .opacity(getOpacity(for: item.monthStart, emoji: emojiIntensity))
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
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 20) {
                ForEach(statisticsSnapshot.emojiItems) { stat in
                    if let emojiIntensity = dataManager.emojiIntensities.first(where: { $0.id == stat.emojiID }) {
                        EmojiButton(
                            emoji: stat.emoji,
                            count: stat.count,
                            color: emojiIntensity.color,
                            isSelected: selectedEmoji?.id == emojiIntensity.id,
                            action: {
                                withAnimation {
                                    selectedEmoji = (selectedEmoji?.id == emojiIntensity.id) ? nil : emojiIntensity
                                }
                            },
                            isCountVisible: true,
                            fontSize: 28
                        )
                    }
                }
            }
        }
        .padding(.horizontal)
    }
    
    private var tagsList: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 10) {
                ForEach(statisticsSnapshot.tagItems.filter { $0.count > 0 }) { stat in
                    if let tag = dataManager.tags.first(where: { $0.id == stat.tagID }) {
                        TagButton(
                            tagName: stat.name,
                            isSelected: selectedTags.contains { $0.id == tag.id },
                            action: {
                                withAnimation {
                                    if selectedTags.contains(where: { $0.id == tag.id }) {
                                        selectedTags.remove(tag)
                                    } else {
                                        selectedTags.insert(tag)
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
    
    private func getOpacity(for date: Date, emoji: EmojiIntensity) -> Double {
        if selectedMonth == nil && selectedEmoji == nil { return 1.0 }
        
        let monthMatch = selectedMonth == nil || dataManager.selectedMonthMatches(date, selectedMonth: selectedMonth)
        let emojiMatch = selectedEmoji == nil || selectedEmoji?.id == emoji.id
        
        return (monthMatch && emojiMatch) ? 1.0 : 0.3
    }
    
    private func selectMonth(from tapLocation: CGPoint, in proxy: ChartProxy, geometry: GeometryProxy) {
        let xPosition = tapLocation.x - geometry[proxy.plotAreaFrame].origin.x
        guard let tappedDate: Date = proxy.value(atX: xPosition) else { return }
        
        selectedMonth = dataManager.toggledMonthSelection(current: selectedMonth, tappedDate: tappedDate)
    }
    
    private func changeYear(by value: Int) {
        guard let currentIndex = dataManager.availableYears.firstIndex(of: selectedYear) else { return }
        
        let newIndex = currentIndex + value
        if newIndex >= 0, newIndex < dataManager.availableYears.count {
            selectedYear = dataManager.availableYears[newIndex]
            selectedMonth = nil
        }
    }
    
    private var statisticsSnapshot: StatisticsSnapshot {
        dataManager.statisticsSnapshot(
            for: StatisticsFilter(
                year: selectedYear,
                selectedMonth: selectedMonth,
                selectedEmojiID: selectedEmoji?.id,
                selectedTagIDs: Set(selectedTags.map(\.id))
            )
        )
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
