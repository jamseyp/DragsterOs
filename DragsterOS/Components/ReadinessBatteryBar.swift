import SwiftUI

/// 🎨 THE CANVAS: A high-contrast visualization of Central Nervous System (CNS) Readiness.
/// Fully conforms to the Dragster OS ColorTheme engine for seamless Light/Dark mode transitions.
struct ReadinessBatteryBar: View {
    let score: Double
    
    // Internal state to trigger the fluid fill animation upon rendering
    @State private var animatedScore: Double = 0.0
    
    // 📐 ARCHITECTURE: Semantic color mapping powered by ColorTheme
    private var batteryColor: Color {
        switch score {
        case 0..<40: return ColorTheme.critical     // Critical systemic fatigue
        case 40..<75: return ColorTheme.warning     // Moderate mechanical load
        default: return ColorTheme.recovery         // Peak Kinetic Readiness / Tapered
        }
    }
    
    private var statusText: String {
        switch score {
        case 0..<40: return "SYSTEM OVERRIDE REQUIRED"
        case 40..<75: return "NOMINAL FATIGUE DETECTED"
        default: return "PEAK KINETIC READINESS"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            
            // HEADER: Monospaced typography for a telemetry-terminal aesthetic
            HStack(alignment: .bottom) {
                Text("CNS READINESS")
                    .font(.system(.caption, design: .monospaced, weight: .heavy))
                    .foregroundStyle(ColorTheme.textMuted) // ✨ Dynamically shifts
                
                Spacer()
                
                Text("\(Int(animatedScore))")
                    .font(.system(.title, design: .monospaced, weight: .black))
                    .foregroundStyle(batteryColor)
                + Text(" / 100")
                    .font(.system(.caption, design: .monospaced, weight: .bold))
                    .foregroundStyle(ColorTheme.textMuted) // ✨ Dynamically shifts
            }
            
            // THE BAR: The physical battery track
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background Track
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(ColorTheme.surfaceBorder) // ✨ Blends seamlessly into the theme
                        .frame(height: 12)
                    
                    // Active Energy Level
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(batteryColor)
                        .frame(width: max(0, geometry.size.width * CGFloat(animatedScore / 100.0)), height: 12)
                        // ✨ THE POLISH: A neon glow effect that scales gracefully
                        .shadow(color: batteryColor.opacity(0.6), radius: animatedScore > 75 ? 8 : 2, x: 0, y: 0)
                }
            }
            .frame(height: 12)
            
            // FOOTER: Status Subtitle
            Text(statusText)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(batteryColor.opacity(0.8))
        }
        .padding()
        // ✨ THE UPGRADE: Dynamic Surface mapping instead of hardcoded .black
        .background(ColorTheme.surface)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(ColorTheme.surfaceBorder, lineWidth: 1) // ✨ Dynamic subtle border
        )
        .onAppear {
            triggerFluidAnimation()
        }
    }
    
    // MARK: - Mechanical Micro-Interactions
    private func triggerFluidAnimation() {
        // Reset to 0 if re-rendering, then spring to the actual score
        animatedScore = 0.0
        
        // A bouncy, fluid spring that feels organic yet precise
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6, blendDuration: 0.1)) {
            animatedScore = score
        }
        
        // A subtle, rigid haptic click to confirm the data has finished rendering
        let impact = UIImpactFeedbackGenerator(style: .rigid)
        impact.impactOccurred()
    }
}
