import SwiftUI
import Charts

struct StatisticsView: View {
    @ObservedObject var dataManager: TearDataManager
    @StateObject private var viewModel: StatisticsViewModel
    @StateObject private var exportViewModel: ExportViewModel
    @State private var showingHeatmap = false
    
    init(dataManager: TearDataManager) {
        self.dataManager = dataManager
        _viewModel = StateObject(wrappedValue: StatisticsViewModel(dataManager: dataManager))
        _exportViewModel = StateObject(wrappedValue: ExportViewModel(dataManager: dataManager))
    }
    
    var body: some View {
        Group {
            if viewModel.isEmpty {
                EmptyStateView(
                    title: "Нет данных для анализа",
                    subtitle: "Добавьте свой первый момент грусти, чтобы начать отслеживать свои эмоции",
                    icon: "chart.bar.fill",
                    buttonTitle: "Добавить запись",
                    action: { viewModel.showingAddTear = true }
                )
            } else {
                List {
                    Section {
                        yearHeader
                        monthlyChartInteractive
                        emojiStats
                        tagsList
                    }
                    
                    ForEach(viewModel.snapshot.diarySections) { section in
                        Section(header: Text(section.monthTitle)
                            .font(.headline)
                            .foregroundColor(.gray)) {
                                ForEach(section.records) { entry in
                                    TearCard(entry: entry, dataManager: dataManager)
                                        .swipeActions(allowsFullSwipe: false) {
                                            Button() {
                                                viewModel.presentDelete(for: entry)
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
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showingHeatmap = true
                        } label: {
                            Image(systemName: "calendar.badge.clock")
                        }
                        .accessibilityLabel("Открыть календарь")
                        .accessibilityIdentifier("statistics_heatmap_button")
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        ExportMenu(
                            onExportPDF: {
                                Task { await exportViewModel.exportPDF(filter: currentFilter) }
                            },
                            onExportCSV: {
                                Task { await exportViewModel.exportCSV(filter: currentFilter) }
                            }
                        )
                        .disabled(viewModel.isEmpty)
                    }
                }
            }
        }
        .navigationTitle("Статистика")
        .overlay {
            if exportViewModel.isExporting {
                ProgressView("Создаём файл…")
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(.regularMaterial))
            }
        }
        .sheet(isPresented: $showingHeatmap) {
            HeatmapView(dataManager: dataManager)
        }
        .sheet(isPresented: $exportViewModel.showingShareSheet, onDismiss: {
            exportViewModel.cleanupExportFile()
        }) {
            if let url = exportViewModel.exportURL {
                ShareSheet(activityItems: [url])
            }
        }
        .sheet(isPresented: $viewModel.showingAddTear) {
            AddTearView(
                availableTags: viewModel.availableTags,
                availableEmojiIntensities: viewModel.availableEmojiIntensities,
                onSave: { newEntry in
                    viewModel.addEntry(newEntry)
                }
            )
        }
        .alert("Удалить запись?", isPresented: $viewModel.showingDeleteAlert) {
            Button("Отмена", role: .cancel) { }
            Button("Удалить", role: .destructive) {
                viewModel.confirmDelete()
            }
        } message: {
            Text("Это действие нельзя отменить")
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
        .onAppear {
            viewModel.syncFromDataManager()
        }
        .onChange(of: dataManager.refreshTrigger) { _ in
            viewModel.syncFromDataManager()
        }
    }
    
    private var yearHeader: some View {
        HStack {
            Text("\(viewModel.snapshot.filteredEntriesCount) \(viewModel.cryingMomentsLabel())")
                .font(.title2.bold())
            
            Spacer()
            
            HStack(spacing: 4) {
                YearButton(systemName: "chevron.left") {
                    viewModel.changeYear(by: -1)
                }
                
                Text(String(format: "%d", viewModel.selectedYear))
                    .foregroundColor(.secondary)
                
                YearButton(systemName: "chevron.right") {
                    viewModel.changeYear(by: 1)
                }
            }
        }
    }
    
    private var monthlyChartInteractive: some View {
        VStack(alignment: .leading, spacing: 10) {
            Chart {
                ForEach(viewModel.snapshot.monthPoints) { item in
                    let reversedIntensityCounts = Array(item.intensityCounts.reversed())
                    ForEach(Array(viewModel.availableEmojiIntensities.reversed().enumerated()), id: \.element.id) { index, emojiIntensity in
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
                            .opacity(viewModel.opacity(for: item.monthStart, emojiID: emojiIntensity.id))
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
                ForEach(viewModel.snapshot.emojiItems) { stat in
                    if let emojiIntensity = viewModel.availableEmojiIntensities.first(where: { $0.id == stat.emojiID }) {
                        EmojiButton(
                            emoji: stat.emoji,
                            count: stat.count,
                            color: emojiIntensity.color,
                            isSelected: viewModel.selectedEmojiID == emojiIntensity.id,
                            action: {
                                withAnimation {
                                    viewModel.toggleEmoji(emojiIntensity.id)
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
                ForEach(viewModel.snapshot.tagItems.filter { $0.count > 0 }) { stat in
                    if let tag = viewModel.availableTags.first(where: { $0.id == stat.tagID }) {
                        TagButton(
                            tagName: stat.name,
                            isSelected: viewModel.selectedTagIDs.contains(tag.id),
                            action: {
                                withAnimation {
                                    viewModel.toggleTag(tag.id)
                                }
                            }
                        )
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    private func selectMonth(from tapLocation: CGPoint, in proxy: ChartProxy, geometry: GeometryProxy) {
        let xPosition = tapLocation.x - geometry[proxy.plotAreaFrame].origin.x
        guard let tappedDate: Date = proxy.value(atX: xPosition) else { return }
        
        viewModel.toggleMonth(tappedDate)
    }

    private var currentFilter: StatisticsFilter {
        StatisticsFilter(
            year: viewModel.selectedYear,
            selectedMonth: viewModel.selectedMonth,
            selectedEmojiID: viewModel.selectedEmojiID,
            selectedTagIDs: viewModel.selectedTagIDs
        )
    }
}
