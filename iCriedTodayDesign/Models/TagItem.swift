import Foundation
import SwiftData

@Model
final class TagItem {
    var id: UUID = UUID()
    var name: String = ""
    var order: Int = 0
    @Relationship(deleteRule: .nullify, inverse: \TearEntry.tagId) var entries: [TearEntry]? = []
    
    init(name: String, order: Int = 0) {
        self.id = stableUUID(from: name.lowercased())
        self.name = name
        self.order = order
    }
}
