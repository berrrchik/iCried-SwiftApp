import SwiftUI

struct ContentView: View {
    @StateObject private var dataManager = TearDataManager()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationView {
                TearLogView(dataManager: dataManager)
            }
            .tabItem {
                Label("Дневник", systemImage: "drop.fill")
            }
            .tag(0)
            
            NavigationView {
                StatisticsView(dataManager: dataManager)
            }
            .tabItem {
                Label("Анализ", systemImage: "waveform.path.ecg")
            }
            .tag(1)
            
            NavigationView {
                SettingsView(dataManager: dataManager)
            }
            .tabItem {
                Label("Настройки", systemImage: "slider.horizontal.3")
            }
            .tag(2)
        }
        .onAppear {
            dataManager.load()
        }
    }
}

struct TearLogView: View {
    @ObservedObject var dataManager: TearDataManager
    @State private var showingAddTear = false
    @State private var showingDeleteAlert = false
    @State private var entryToDelete: TearEntry?
    
    var body: some View {
        VStack(spacing: -5) {
            headerView
            entriesList
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
                    .shadow(radius: 10)
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
                    ForEach(section.records.sorted(by: { $0.date > $1.date })) { entry in
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
    @ObservedObject var dataManager: TearDataManager
    @State private var showingEditSheet = false
    
    var body: some View {
        Button(action: { showingEditSheet = true }) {
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(dataManager.getEmoji(for: entry).emoji)
                                .font(.title)
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 5) {
                            ForEach(Array(entry.tags), id: \.self) { tag in
                                Text(tag)
//                                    .font(.caption)
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
                    Text(entry.date, style: .date)
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
    ContentView()
}
