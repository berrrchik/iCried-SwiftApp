import Foundation

struct TagItem: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    
    init(name: String) {
        self.name = name
    }
} 
