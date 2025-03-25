import SwiftUI
import SwiftData

struct SettingsView: View {
    @Bindable var dataManager: TearDataManager

    var body: some View {
        List {
            Section {
                NavigationLink(destination: TagManagementView(dataManager: dataManager)) {
                    Label("Управление тегами", systemImage: "tag")
                }
                NavigationLink(destination: EmojiManagementView(dataManager: dataManager)) {
                    Label("Управление эмодзи", systemImage: "face.smiling")
                }
            }
            
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
