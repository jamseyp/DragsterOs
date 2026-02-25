import SwiftUI

// MARK: - 🔋 COMPONENT: READINESS BATTERY BAR
struct ReadinessBatteryBar: View {
    var score: Double
    
    private var batteryColor: Color {
        switch score {
        case 80...100: return ColorTheme.recovery
        case 50..<80: return ColorTheme.warning
        default: return ColorTheme.critical
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("SYSTEM READINESS")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(ColorTheme.textMuted)
                Spacer()
                Text("\(Int(score))%")
                    .font(.system(size: 12, weight: .heavy, design: .monospaced))
                    .foregroundStyle(batteryColor)
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Empty Track
                    RoundedRectangle(cornerRadius: 6)
                        .fill(ColorTheme.surfaceBorder)
                        .frame(height: 12)
                    
                    // Dynamic Fill
                    RoundedRectangle(cornerRadius: 6)
                        .fill(batteryColor)
                        .frame(width: max(0, geo.size.width * CGFloat(score / 100.0)), height: 12)
                        .animation(.spring(response: 0.8, dampingFraction: 0.7), value: score)
                        // Neon glow when fully charged
                        .shadow(color: batteryColor.opacity(0.6), radius: score > 80 ? 6 : 0)
                }
            }
            .frame(height: 12)
        }
        .padding(16)
        .background(ColorTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
