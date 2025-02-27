import Foundation

struct TearEntry: Identifiable, Codable {
    var id: UUID
    var date: Date
    var intensity: Int
    var tags: Set<String>
    var note: String
    
    init(id: UUID = UUID(), date: Date = Date(), intensity: Int = 1, tags: Set<String> = [], note: String = "") {
        self.id = id
        self.date = date
        self.intensity = intensity
        self.tags = tags
        self.note = note
    }
} 