import SwiftUI

struct EmojiButton: View {
    let emoji: String
    let count: Int?
    let color: Color?
    let isSelected: Bool
    let action: () -> Void
    let isCountVisible: Bool
    let fontSize: CGFloat
    
    var body: some View {
        Button(action: action) {
            VStack {
                Text(emoji)
                    .font(.system(size: fontSize))
                
                if isCountVisible, let count = count {
                    Text("\(count)")
                        .font(.headline)
                        .foregroundColor(.black)
                }
            }
            .frame(width: 70, height: 70)
            .background(Circle().fill(isSelected ? Color.blue.opacity(0.2) : Color(.systemBackground)))
            .clipShape(Circle())
            .padding(5)
            .background(Color.clear)
            .shadow(color: .black.opacity(0.15), radius: 5)
        }
    }
}
