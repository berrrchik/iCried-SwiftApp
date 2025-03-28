import SwiftUI
import SwiftData

@Model
final class EmojiIntensity {
    var id: UUID = UUID()
    var emoji: String = "🥲"
    var colorHex: String = "#0000FF"
    var opacity: Double = 1.0
    var order: Int = 0

    var color: Color {
        (Color(hex: colorHex) ?? .blue).opacity(opacity)
    }

    init(emoji: String, color: Color, opacity: Double = 1.0, order: Int = 0) {
        self.id = UUID()
        self.emoji = emoji
        self.colorHex = color.toHex() ?? "#0000FF"
        self.opacity = opacity
        self.order = order
    }
}

// Расширения для работы с цветами
extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        self.init(
            .sRGB,
            red: Double((rgb & 0xFF0000) >> 16) / 255.0,
            green: Double((rgb & 0x00FF00) >> 8) / 255.0,
            blue: Double(rgb & 0x0000FF) / 255.0,
            opacity: 1.0
        )
    }
    
    func toHex() -> String? {
        guard let components = UIColor(self).cgColor.components, components.count >= 3 else {
            return nil
        }
        
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        
        return String(format: "#%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
    }
}
