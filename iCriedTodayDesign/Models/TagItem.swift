import Foundation
import SwiftData

@Model
final class TagItem {
    var id: UUID = UUID()
    var name: String = ""
    var order: Int = 0

    init(name: String, order: Int = 0) {
        self.id = UUID()
        self.name = name
        self.order = order
    }
}
