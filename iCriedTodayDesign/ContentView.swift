import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var dataManager: TearDataManager
    @State private var selectedTab = 0
    @State private var isSyncing = false
    
    init(modelContext: ModelContext) {
        _dataManager = State(initialValue: TearDataManager(modelContext: modelContext))
        UITabBar.appearance().backgroundColor = UIColor.white
    }
    
    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                NavigationStack {
                    TearLogView(dataManager: dataManager, modelContext: modelContext)
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
            
            if isSyncing {
                Color.gray.opacity(0.4)
                    .ignoresSafeArea()
                    .overlay(
                        VStack {
                            ProgressView("Синхронизация данных...")
                                .progressViewStyle(CircularProgressViewStyle())
                                .font(.title2)
                                .padding()
                                .background(Color.white.opacity(0.9))
                                .cornerRadius(10)
                        }
                    )
            }
        }
        .onAppear {
            dataManager.removeDuplicates()
            Task {
                isSyncing = true
                await dataManager.syncWithCloudKit()
                isSyncing = false
            }
        }
    }
}

struct TearLogView: View {
    @Bindable var dataManager: TearDataManager
    let modelContext: ModelContext
    @Query(sort: \TearEntry.date, order: .reverse) private var entries: [TearEntry]
    @State private var showingAddTear = false
    @State private var showingDeleteAlert = false
    @State private var entryToDelete: TearEntry?
    @State private var isRefreshing = false
    
    init(dataManager: TearDataManager, modelContext: ModelContext) {
        self.dataManager = dataManager
        self.modelContext = modelContext
        _entries = Query(sort: [SortDescriptor(\TearEntry.date, order: .reverse)], animation: .default)
    }
    
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
                        isRefreshing = true
                        await dataManager.syncWithCloudKit()
                        isRefreshing = false
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
                        modelContext.delete(entry)
                        try? modelContext.save()
                        dataManager.updateAnalyzer()
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

struct TearCard: View {
    let entry: TearEntry
    @Bindable var dataManager: TearDataManager
    @State private var showingEditSheet = false
    
    init(entry: TearEntry, dataManager: TearDataManager) {
        self.entry = entry
        self.dataManager = dataManager
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "d MMMM"
        return formatter.string(from: entry.date)
    }
    
    var body: some View {
        Button(action: { showingEditSheet = true }) {
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(dataManager.getEmoji(for: entry).emoji)
                        .font(.title)
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 5) {
                            ForEach(Array(arrayLiteral: entry.tagId), id: \.self) { tagId in
                                if let tag = dataManager.getTag(for: entry) {
                                    Text(tag.name)
                                        .font(.subheadline)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(
                                            Capsule()
                                                .fill(Color.blue.opacity(0.1))
                                        )
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                    Text(formattedDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Text(entry.note)
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
            .padding(.vertical, 6)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingEditSheet) {
            EditTearView(dataManager: dataManager, entry: entry)
        }
    }
}

#Preview {
    do {
        let container = try ModelContainer(for: TearEntry.self, EmojiIntensity.self, TagItem.self)
        let modelContext = ModelContext(container)
        return ContentView(modelContext: modelContext)
    } catch {
        return Text("Ошибка при создании ModelContainer: \(error.localizedDescription)")
    }
}
