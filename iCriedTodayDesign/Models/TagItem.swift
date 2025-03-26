import Foundation
import SwiftData

@Model
final class TagItem {
    var id: UUID
    var name: String
    var order: Int

    init(name: String, order: Int = 0) {
        self.id = UUID()
        self.name = name
        self.order = order
    }
}
