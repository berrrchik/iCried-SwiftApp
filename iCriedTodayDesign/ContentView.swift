import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var dataManager: TearDataManager
    @State private var selectedTab = 0
    
    init(modelContext: ModelContext) {
        _dataManager = State(initialValue: TearDataManager(modelContext: modelContext))
        UITabBar.appearance().backgroundColor = UIColor.white
    }
    
    var body: some View {
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
        .onAppear {
            dataManager.removeDuplicates()
        }
    }
}

struct TearLogView: View {
    @Bindable var dataManager: TearDataManager
    @State private var showingAddTear = false
    @State private var showingDeleteAlert = false
    @State private var entryToDelete: TearEntry?
    
    @State private var isRefreshing = false
    
    init(dataManager: TearDataManager) {
        self.dataManager = dataManager
    }
    
    var body: some View {
        VStack(spacing: -5) {
            headerView
            entriesList
                .refreshable {
                    isRefreshing = true
                    await dataManager.syncWithCloudKit()
                    isRefreshing = false
                }
        }
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
            ForEach(dataManager.groupedEntries, id: \.month) { section in
                Section(header: Text(section.month)
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
