import SwiftUI

struct SettingsView: View {
    @ObservedObject var dataManager: TearDataManager

    var body: some View {
        List {
            Section("О приложении") {
                Text("Это приложение помогает отслеживать моменты грусти и эмоционального напряжения. Вы можете записывать, когда испытывали грустные эмоции, с какой интенсивностью и по какой причине, а затем анализировать эти данные для лучшего понимания своего эмоционального состояния.")
                    .font(.subheadline)
                    .foregroundStyle(.primary)
            }

            Section("Данные") {
                NavigationLink(destination: TagManagementView(dataManager: dataManager)) {
                    Label("Управление тегами", systemImage: "tag")
                }
            }
        }
        .navigationTitle("Настройки")
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
        return "\(version) (\(build))"
    }
}
