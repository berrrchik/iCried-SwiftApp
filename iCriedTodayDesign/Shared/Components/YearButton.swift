import SwiftUI

struct YearButton: View {
    let systemName: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .foregroundColor(.blue)
        }
        .buttonStyle(PlainButtonStyle())
        .contentShape(Rectangle())
    }
}
