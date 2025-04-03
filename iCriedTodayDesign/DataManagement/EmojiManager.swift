import Foundation
import SwiftData

@Observable
class EmojiIntensityManager {
    private let modelContext: ModelContext
    private(set) var emojiIntensities: [EmojiIntensity] = []
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadEmojiIntensities()
    }
    
//    private func loadEmojiIntensities() {
//        do {
//            let descriptor = FetchDescriptor<EmojiIntensity>(sortBy: [.init(\.order, order: .forward)])
//            emojiIntensities = try modelContext.fetch(descriptor)
//        } catch {
//            print("Ошибка при загрузке эмодзи: \(error)")
//        }
//    }
    
    // В EmojiIntensityManager.swift
    private func loadEmojiIntensities() {
        do {
            let descriptor = FetchDescriptor<EmojiIntensity>(sortBy: [.init(\.order, order: .forward)])
            let newEmojis = try modelContext.fetch(descriptor)
            print("Загружено эмодзи из базы: \(newEmojis.count)")
            emojiIntensities = newEmojis
        } catch {
            print("Ошибка при загрузке эмодзи: \(error)")
        }
    }
    
    func reloadEmojiIntensities() {
        loadEmojiIntensities()
        print("Эмодзи после перезагрузки: \(emojiIntensities.count)")
        save()
    }
    
    func addEmojiIntensity(_ emoji: EmojiIntensity) {
        if !emojiIntensities.contains(where: { $0.emoji == emoji.emoji }) {
            emoji.order = emojiIntensities.count
            modelContext.insert(emoji)
            emojiIntensities.append(emoji)
            save()
        } else {
            print("Эмодзи '\(emoji.emoji)' уже существует")
        }
    }
    
    func removeEmojiIntensity(at index: Int) {
        guard index >= 0 && index < emojiIntensities.count else { return }
        let emoji = emojiIntensities[index]
        modelContext.delete(emoji)
        emojiIntensities.remove(at: index)
        save()
    }
    
    func updateEmojiIntensity(_ updatedEmoji: EmojiIntensity, at index: Int) {
        guard index >= 0 && index < emojiIntensities.count else { return }
        let original = emojiIntensities[index]
        original.emoji = updatedEmoji.emoji
        original.colorHex = updatedEmoji.colorHex
        original.opacity = updatedEmoji.opacity
        save()
    }
    
    func moveEmojiIntensity(from source: IndexSet, to destination: Int) {
        emojiIntensities.move(fromOffsets: source, toOffset: destination)
        for (index, emoji) in emojiIntensities.enumerated() {
            emoji.order = index
        }
        save()
    }
    
    func save() {
        do {
            try modelContext.save()
        } catch {
            print("Ошибка при сохранении эмодзи: \(error)")
        }
    }
}
