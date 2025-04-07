import Foundation
import SwiftData

@Observable
class TagManager {
    private let modelContext: ModelContext
    private(set) var tags: [TagItem] = []
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadTags()
    }
    
    private func loadTags() {
        do {
            let descriptor = FetchDescriptor<TagItem>(sortBy: [.init(\.order, order: .forward)])
            let newTags = try modelContext.fetch(descriptor)
            print("Загружено тегов из базы: \(newTags.count)")
            tags = newTags
        } catch {
            print("Ошибка при загрузке тегов: \(error)")
        }
    }
    
    func reloadTags() {
        loadTags()
        print("Тегов после перезагрузки: \(tags.count)")
        save()
    }
    
    func addTag(_ name: String) {
        let normalizedName = name.trimmingCharacters(in: .whitespaces)
        if !tags.contains(where: { $0.name.lowercased() == normalizedName.lowercased() }) {
            let tag = TagItem(name: normalizedName)
            tag.order = tags.count
            modelContext.insert(tag)
            tags.append(tag)
            save()
        } else {
            print("Тег '\(name)' уже существует")
        }
    }
    
    func removeTag(_ tagId: UUID) {
        if let tag = tags.first(where: { $0.id == tagId }) {
            modelContext.delete(tag)
            tags.removeAll { $0.id == tagId }
            save()
        }
    }
    
    func moveTag(from source: IndexSet, to destination: Int) {
        tags.move(fromOffsets: source, toOffset: destination)
        for (index, tag) in tags.enumerated() {
            tag.order = index
        }
        save()
    }
    
    func save() {
        do {
            try modelContext.save()
        } catch {
            print("Ошибка при сохранении тегов: \(error)")
        }
    }
}
