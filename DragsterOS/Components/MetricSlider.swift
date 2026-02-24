import SwiftUI

struct MetricSlider: View {
    let label: String
    @Binding var value: Double
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(label, systemImage: icon)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(ColorTheme.textSecondary)
            
            HStack {
                Slider(value: $value, in: 1...10, step: 0.5)
                    .accentColor(ColorTheme.textPrimary)
                
                Text(String(format: "%.1f", value))
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(ColorTheme.textPrimary)
                    .frame(width: 50)
                    .padding(.vertical, 5)
                    .background(ColorTheme.panel)
                    .cornerRadius(5)
            }
        }
        .padding(.vertical, 5)
    }
}
