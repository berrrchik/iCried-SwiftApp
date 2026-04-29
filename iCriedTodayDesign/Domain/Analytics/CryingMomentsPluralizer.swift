import Foundation

enum CryingMomentsPluralizer {
    static func label(for count: Int) -> String {
        let lastDigit = count % 10
        let lastTwoDigits = count % 100
        
        if (11...19).contains(lastTwoDigits) {
            return "Моментов грусти"
        }
        
        switch lastDigit {
        case 1:
            return "Момент грусти"
        case 2...4:
            return "Момента грусти"
        default:
            return "Моментов грусти"
        }
    }
}
