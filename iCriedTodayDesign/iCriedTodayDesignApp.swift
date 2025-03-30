import SwiftUI
import SwiftData
import CloudKit

@main
struct iCriedTodayDesignApp: App {
    let container: ModelContainer
    
    init() {
        do {
            let schema = Schema([
                TagItem.self,
                EmojiIntensity.self,
                TearEntry.self
            ])
            
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .private("iCloud.com.berchik.iCriedTodayDesign")
            )
            
            container = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Не удалось инициализировать ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(modelContext: ModelContext(container))
                .preferredColorScheme(.light)
        }
        .modelContainer(container)
    }
}
