import SwiftUI

struct HeatmapView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var dataManager: TearDataManager
    @StateObject private var viewModel: HeatmapViewModel

    init(dataManager: TearDataManager) {
        self.dataManager = dataManager
        _viewModel = StateObject(wrappedValue: HeatmapViewModel(dataManager: dataManager))
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                headerRow
                Divider()

                ScrollView {
                    VStack(spacing: 16) {
                        monthPicker
                        HeatmapMonthGrid(
                            daySummaries: viewModel.daySummaries,
                            year: viewModel.selectedYear,
                            month: viewModel.selectedMonth,
                            onDayTap: viewModel.selectDay
                        )
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 24)
                                .onEnded { value in
                                    if value.translation.width < -40 {
                                        viewModel.goToNextMonth()
                                    } else if value.translation.width > 40 {
                                        viewModel.goToPreviousMonth()
                                    }
                                }
                        )

                        HeatmapLegend()
                            .padding(.horizontal)
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $viewModel.showingDayDetail) {
            dayDetailSheet
                .presentationDetents([.medium, .large])
        }
        .onAppear { viewModel.syncFromDataManager() }
        .onChange(of: dataManager.refreshTrigger) { _ in
            viewModel.syncFromDataManager()
        }
    }

    private var headerRow: some View {
        HStack {
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

            Spacer()

            Text("Календарь")
                .font(.headline)

            Spacer()

            Button("Закрыть") {
                dismiss()
            }
            .font(.body)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    private var monthPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(viewModel.availableMonths, id: \.self) { month in
                    Button(monthTitle(for: month)) {
                        viewModel.selectMonth(month)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(viewModel.selectedMonth == month ? Color.accentColor.opacity(0.18) : Color(.systemGray6))
                    )
                }
            }
            .padding(.horizontal)
        }
    }

    private var dayDetailSheet: some View {
        NavigationView {
            List {
                if dayEntries.isEmpty {
                    EmptyStateView(
                        title: "Нет записей за этот день",
                        subtitle: "",
                        icon: "moon.zzz",
                        buttonTitle: "Закрыть",
                        action: viewModel.dismissDayDetail
                    )
                } else {
                    ForEach(dayEntries) { entry in
                        TearCard(entry: entry, dataManager: dataManager)
                    }
                }
            }
            .navigationTitle(selectedDayTitle)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Закрыть") {
                        viewModel.dismissDayDetail()
                    }
                }
            }
        }
    }

    private var dayEntries: [TearEntry] {
        viewModel.entriesForSelectedDay()
    }

    private var selectedDayTitle: String {
        guard let day = viewModel.selectedDay else { return "День" }
        return day.formatted(.dateTime.day().month(.wide).year().locale(Locale(identifier: "ru_RU")))
    }

    private func monthTitle(for month: Int) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "LLL"
        guard let date = Calendar.current.date(from: DateComponents(year: viewModel.selectedYear, month: month, day: 1)) else {
            return ""
        }
        return formatter.string(from: date).capitalized
    }

}
