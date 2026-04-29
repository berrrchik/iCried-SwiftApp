import SwiftUI
import SwiftData

struct SettingsView: View {
    @ObservedObject var dataManager: TearDataManager

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
        }
        .navigationTitle("Настройки")
    }
} 
