import SwiftData

@MainActor
func makePreviewDataManager() -> TearDataManager {
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: TearEntry.self,
        EmojiIntensity.self,
        TagItem.self,
        configurations: configuration
    )
    
    return TearDataManager(modelContext: ModelContext(container))
}
