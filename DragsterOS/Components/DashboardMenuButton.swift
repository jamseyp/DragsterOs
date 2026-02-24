import SwiftUI

struct DashboardMenuButton: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 30)
            Text(title)
            Spacer()
            Image(systemName: "chevron.right")
                .opacity(0.5)
        }
        .font(.system(size: 14, weight: .bold, design: .monospaced))
        .foregroundColor(color)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}
