import Foundation
import SwiftData

@Model
final class TagItem {
    var id: UUID = UUID()
    var name: String = ""
    var order: Int = 0
    @Relationship(deleteRule: .nullify, inverse: \TearEntry.tagId) var entries: [TearEntry]? = []
    
    init(name: String, order: Int = 0) {
        let nameData = name.lowercased().data(using: .utf8)!
        self.id = UUID(uuidString: nameData.base64EncodedString()) ?? UUID()
        self.name = name
        self.order = order
    }
}
