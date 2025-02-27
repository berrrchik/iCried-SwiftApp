//import SwiftUI
//
//struct ContentView: View {
//    @StateObject private var dataManager = TearDataManager()
//    @State private var selectedTab = 0
//    @State private var showingAddTear = false
//    
//    var body: some View {
//        ZStack {
//            TabView(selection: $selectedTab) {
//                NavigationView {
//                    TearLogView(entries: dataManager.entries, dataManager: dataManager)
//                }
//                .tabItem {
//                    Image(systemName: "drop.fill")
//                    Text("Дневник")
//                }
//                .tag(0)
//                
//                NavigationView {
//                    StatisticsView(dataManager: dataManager)
//                }
//                .tabItem {
//                    Image(systemName: "waveform.path.ecg")
//                    Text("Анализ")
//                }
//                .tag(1)
//                
//                NavigationView {
//                    SettingsView()
//                }
//                .tabItem {
//                    Image(systemName: "slider.horizontal.3")
//                    Text("Настройки")
//                }
//                .tag(2)
//            }
//            
//        }
//        .sheet(isPresented: $showingAddTear) {
//            AddTearView(dataManager: dataManager)
//        }
//        .onAppear {
//            dataManager.load()
//        }
//    }
//}
//
//struct TearLogView: View {
//    let entries: [TearEntry]
//    @ObservedObject var dataManager: TearDataManager
//    @State private var showingAddTear = false
//    @State private var showingDeleteAlert = false
//    @State private var entryToDelete: TearEntry?
//
//    var groupedEntries: [(month: String, records: [TearEntry])] {
//            let grouped = Dictionary(grouping: entries) { entry in
//                let formatter = DateFormatter()
//                formatter.locale = Locale(identifier: "ru_RU")
//                formatter.dateFormat = "LLLL yyyy"
//                return formatter.string(from: entry.date)
//            }
//            return grouped.sorted { $0.key < $1.key }
//                .map { (month: $0.key.uppercased(), records: $0.value) }
//        }
//    
//    var body: some View {
//        VStack(spacing: -5) {
//            HStack {
//                Text("Мой Дневник")
//                    .font(.title)
//                    .fontWeight(.bold)
//                Spacer()
//                Button(action: { showingAddTear = true }) {
//                    Image(systemName: "plus")
//                        .font(.title2)
//                        .foregroundColor(.white)
//                        .frame(width: 44, height: 44)
//                        .background(Circle().fill(Color.blue))
//                        .shadow(radius: 10)
//                }
//            }
//            .padding()
//            
//            List {
//                ForEach(groupedEntries, id: \.month) { section in
//                    Section(header: Text(section.month).font(.headline).foregroundColor(.gray)) {
//                        ForEach(section.records.sorted(by: { $0.date > $1.date })) { entry in
//                            TearCard(entry: entry, dataManager: dataManager)
//                                .swipeActions(allowsFullSwipe: false) {
//                                    Button() {
//                                        entryToDelete = entry
//                                        showingDeleteAlert = true
//                                    } label: {
//                                        Label("Удалить", systemImage: "trash")
//                                    }
//                                    .tint(.red)
//                                }
//                        }
//                    }
//                }
//            }
//            .listStyle(InsetGroupedListStyle())
//            
//            
//        }
//        .sheet(isPresented: $showingAddTear) {
//            AddTearView(dataManager: dataManager)
//        }
//        .alert("Удалить запись?", isPresented: $showingDeleteAlert) {
//            Button("Отмена", role: .cancel) {}
//            Button("Удалить", role: .destructive) {
//                if let entry = entryToDelete {
//                    dataManager.deleteEntry(entry)
//                }
//                entryToDelete = nil
//            }
//        } message: {
//            Text("Это действие нельзя отменить")
//        }
//    }
//    
//    private func deleteEntry(at offsets: IndexSet) {
//        for index in offsets {
//            let entry = entries[index]
//            entryToDelete = entry
//        }
//    }
//    
////    private let monthYearFormatter: DateFormatter = {
////        let formatter = DateFormatter()
//////        formatter.dateFormat = "MMMM yyyy"
////        formatter.locale = Locale(identifier: "ru_RU")
////        formatter.dateFormat = "MMMM yyyy"
////        return formatter
////    }()
//}
//
//
//struct TearCard: View {
//    
//    let entry: TearEntry
//    @ObservedObject var dataManager: TearDataManager
//    @State private var showingEditSheet = false
//    
//    var body: some View {
//        Button(action: { showingEditSheet = true }) {
//            VStack(alignment: .leading, spacing: 5) {
//                HStack {
//                    Text(["🥲", "😢", "😭"][entry.intensity])
//                        .font(.title)
//                    ScrollView(.horizontal, showsIndicators: false) {
//                        LazyHStack(spacing: 5) {
//                            ForEach(Array(entry.tags), id: \.self) { tag in
//                                Text(tag)
//                                    .font(.caption)
//                                    .padding(.horizontal, 12)
//                                    .padding(.vertical, 6)
//                                    .background(
//                                        Capsule()
//                                            .fill(Color.blue.opacity(0.1))
//                                    )
//                                    .foregroundColor(.blue)
//                            }
//                        }
//                    }
//                    Text(entry.date, style: .date)
//                        .font(.caption)
//                        .foregroundColor(.secondary)
//                }
//                
//                Text(entry.note)
//                    .font(.subheadline)
//                    .foregroundColor(.primary)
//                
//            }
//            .padding(.vertical, 6)
//        }
//        .buttonStyle(PlainButtonStyle())
//        .sheet(isPresented: $showingEditSheet) {
//            EditTearView(dataManager: dataManager, entry: entry)
//        }
//    }
//}
//
//struct SettingsView: View {
//    var body: some View {
//        List {
//            Section {
//                NavigationLink(destination: Text("Профиль")) {
//                    Label("Профиль", systemImage: "person.circle")
//                }
//                NavigationLink(destination: Text("Уведомления")) {
//                    Label("Уведомления", systemImage: "bell")
//                }
//            }
//            
//            Section {
//                NavigationLink(destination: Text("О приложении")) {
//                    Label("О приложении", systemImage: "info.circle")
//                }
//                NavigationLink(destination: Text("Поддержка")) {
//                    Label("Поддержка", systemImage: "questionmark.circle")
//                }
//            }
//        }
//        .navigationTitle("Настройки")
//    }
//}
//
//#Preview {
//    ContentView()
//}

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
                SettingsView()
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
                    Text(["🥲", "😢", "😭"][entry.intensity])
                        .font(.title)
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 5) {
                            ForEach(Array(entry.tags), id: \.self) { tag in
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

struct SettingsView: View {
    var body: some View {
        List {
            Section {
                NavigationLink(destination: Text("Профиль")) {
                    Label("Профиль", systemImage: "person.circle")
                }
                NavigationLink(destination: Text("Уведомления")) {
                    Label("Уведомления", systemImage: "bell")
                }
            }
            
            Section {
                NavigationLink(destination: Text("О приложении")) {
                    Label("О приложении", systemImage: "info.circle")
                }
                NavigationLink(destination: Text("Поддержка")) {
                    Label("Поддержка", systemImage: "questionmark.circle")
                }
            }
        }
        .navigationTitle("Настройки")
    }
}

#Preview {
    ContentView()
}
