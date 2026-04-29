import SwiftUI

struct EmptyStateView: View {
    let title: String
    let subtitle: String
    let icon: String
    let buttonTitle: String
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text(subtitle)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button(action: action) {
                Text(buttonTitle)
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(height: 50)
                    .frame(width: 160)
                    .background(Color.blue)
                    .cornerRadius(10)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    EmptyStateView(
        title: "Начните свой путь",
        subtitle: "Запишите свой первый момент грусти и начните путешествие к самопознанию",
        icon: "drop.fill",
        buttonTitle: "Добавить запись",
        action: {}
    )
} 
