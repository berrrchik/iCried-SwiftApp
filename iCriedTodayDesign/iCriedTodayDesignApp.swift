import SwiftUI
import SwiftData

@main
struct iCriedTodayDesignApp: App {
    let container: ModelContainer
    
    init() {
        do {
            container = try ModelContainer(
                for: TearEntry.self, EmojiIntensity.self, TagItem.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: false)
            )
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
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
