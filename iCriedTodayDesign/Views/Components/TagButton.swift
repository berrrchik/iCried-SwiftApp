import SwiftUI
import SwiftData

struct TagButton: View {
    let tagName: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                Text(tagName)
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(isSelected ? Color.blue : Color.blue.opacity(0.1))
                    )
                    .foregroundColor(isSelected ? .white : .blue)
                
            }
            .background(Color.clear)
            .shadow(color: .black.opacity(0.15), radius: 5)
        }
    }
}
