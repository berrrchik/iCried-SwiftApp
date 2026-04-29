import Foundation
import SwiftData

@MainActor
final class TagRepository: TagRepositoryProtocol {
    private let modelContext: ModelContext
    private(set) var tags: [TagItem] = []
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        reloadTags()
    }
    
    func reloadTags() {
        do {
            let descriptor = FetchDescriptor<TagItem>(sortBy: [.init(\.order, order: .forward)])
            let newTags = try modelContext.fetch(descriptor)
            debugLog("Загружено тегов из базы: \(newTags.count)")
            tags = newTags
            debugLog("Тегов после перезагрузки: \(tags.count)")
        } catch {
            debugLog("Ошибка при загрузке тегов: \(error)")
        }
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
            debugLog("Тег '\(name)' уже существует")
        }
    }
    
    func updateTag(withId tagId: UUID, newName: String) {
        let normalizedName = newName.trimmingCharacters(in: .whitespaces)
        guard normalizedName.count >= 2 else { return }
        
        guard let tag = tags.first(where: { $0.id == tagId }) else { return }
        let hasConflict = tags.contains { existing in
            existing.id != tagId && existing.name.lowercased() == normalizedName.lowercased()
        }
        
        guard !hasConflict else {
            debugLog("Тег '\(normalizedName)' уже существует")
            return
        }
        
        tag.name = normalizedName
        save()
    }
    
    func removeTag(_ tagId: UUID) {
        guard let tag = tags.first(where: { $0.id == tagId }) else { return }
        
        modelContext.delete(tag)
        tags.removeAll { $0.id == tagId }
        save()
    }
    
    func moveTag(from source: IndexSet, to destination: Int) {
        tags.move(fromOffsets: source, toOffset: destination)
        for (index, tag) in tags.enumerated() {
            tag.order = index
        }
        save()
    }
    
    private func save() {
        do {
            try modelContext.save()
        } catch {
            debugLog("Ошибка при сохранении тегов: \(error)")
        }
    }
}
