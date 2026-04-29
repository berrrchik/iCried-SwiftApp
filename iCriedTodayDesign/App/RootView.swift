import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var dataManager: TearDataManager?
    @State private var selectedTab = 0
    
    var body: some View {
        Group {
            if let dataManager {
                TabView(selection: $selectedTab) {
                    NavigationStack {
                        DiaryView(dataManager: dataManager)
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

#Preview {
    RootView()
}
