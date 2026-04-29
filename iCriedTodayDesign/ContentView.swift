import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var dataManager: TearDataManager?
    @State private var selectedTab = 0
    
    var body: some View {
        Group {
            if let dataManager {
                TabView(selection: $selectedTab) {
                    NavigationStack {
                        TearLogView(dataManager: dataManager)
                    }
                    .tabItem {
                        Label("Дневник", systemImage: "drop.fill")
                    }
                    .tag(0)
                    
                    NavigationStack {
                        StatisticsView(dataManager: dataManager)
                    }
                    .tabItem {
                        Label("Анализ", systemImage: "waveform.path.ecg")
                    }
                    .tag(1)
                    
                    NavigationStack {
                        SettingsView(dataManager: dataManager)
                    }
                    .tabItem {
                        Label("Настройки", systemImage: "slider.horizontal.3")
                    }
                    .tag(2)
                }
            } else {
                ProgressView("Загрузка...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task {
            UITabBar.appearance().backgroundColor = UIColor.white
            
            guard dataManager == nil else { return }
            
            let manager = TearDataManager(modelContext: modelContext)
            dataManager = manager
        }
    }
}

struct TearLogView: View {
    @Bindable var dataManager: TearDataManager
    @Query(sort: \TearEntry.date, order: .reverse) private var entries: [TearEntry]
    @State private var showingAddTear = false
    @State private var showingDeleteAlert = false
    @State private var entryToDelete: TearEntry?
    
    var body: some View {
        VStack(spacing: -5) {
            headerView
            
            if entries.isEmpty {
                EmptyStateView(
                    title: "Начните свой путь",
                    subtitle: "Запишите свой первый момент грусти и начните путешествие к самопознанию",
                    icon: "drop.fill",
                    buttonTitle: "Добавить запись",
                    action: { showingAddTear = true }
                )
                .transition(.opacity)
            } else {
                entriesList
                    .refreshable {
                        await dataManager.refreshData()
                    }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: entries.isEmpty)
        .sheet(isPresented: $showingAddTear) {
            AddTearView(dataManager: dataManager)
        }
        .alert("Удалить запись?", isPresented: $showingDeleteAlert) {
            Button("Отмена", role: .cancel) { }
            Button("Удалить", role: .destructive) {
                if let entry = entryToDelete {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        dataManager.deleteEntry(entry)
                    }
                }
                entryToDelete = nil
            }
        } message: {
            Text("Это действие нельзя отменить")
        }
    }
    
    private var headerView: some View {
        HStack {
            Text("Мой Дневник")
                .font(.title)
                .fontWeight(.bold)
            Spacer()
            Button(action: { showingAddTear = true }) {
                Image(systemName: "plus")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.blue))
            }
        }
        .padding()
    }
    
    private var entriesList: some View {
        List {
            ForEach(groupedEntries, id: \.month) { section in
                entriesSection(for: section)
            }
        }
        .listStyle(InsetGroupedListStyle())
        .id(dataManager.refreshTrigger)
    }
    
    private var groupedEntries: [(month: String, records: [TearEntry])] {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ru_RU")
        dateFormatter.dateFormat = "LLLL yyyy"
        
        let grouped = Dictionary(grouping: entries) { entry in
            dateFormatter.string(from: entry.date)
        }
        
        return grouped.map { (month: $0.key, records: $0.value.sorted { $0.date > $1.date }) }
            .sorted { $0.records.first?.date ?? Date() > $1.records.first?.date ?? Date() }
    }
    
    private func entriesSection(for section: (month: String, records: [TearEntry])) -> some View {
        Section(header: Text(section.month)
            .font(.headline)
            .foregroundColor(.gray)) {
                ForEach(section.records) { entry in
                    entryRow(for: entry)
                        .transition(.opacity)
                }
                .animation(.easeInOut(duration: 0.3), value: section.records)
            }
    }
    
    private func entryRow(for entry: TearEntry) -> some View {
        TearCard(entry: entry, dataManager: dataManager)
            .id(entry.id)
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

#Preview {
    ContentView()
}
