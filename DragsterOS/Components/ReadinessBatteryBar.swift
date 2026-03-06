import SwiftUI

/// 🎨 THE CANVAS: A gamified, high-contrast visualization of Central Nervous System (CNS) Readiness.
struct NeuralReadinessWidget: View {
    let score: Double
    
    // Internal state to trigger the fluid fill animation upon rendering
    @State private var animatedScore: Double = 0.0
    
    // 📐 ARCHITECTURE: Semantic color mapping
    private var readinessColor: Color {
        switch score {
        case 0..<40: return ColorTheme.critical     // High CNS fatigue - requires active recovery
        case 40..<75: return .cyan                  // Moderate load - adaptive phase
        default: return .green                      // Peak Kinetic Readiness
        }
    }
    
    private var statusText: String {
        switch score {
        case 0..<40: return "STRATEGIC RECOVERY PROTOCOL"
        case 40..<75: return "MODERATE NEURAL LOAD"
        default: return "PRIME KINETIC STATE"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            // --- 1. HEADER ---
            HStack(alignment: .bottom) {
                Text("NEURAL READINESS")
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundStyle(ColorTheme.textMuted)
                
                Spacer()
                
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(Int(animatedScore))")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundStyle(readinessColor)
                        .contentTransition(.numericText())
                    
                    Text("/ 100")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(ColorTheme.textMuted)
                }
            }
            
            // --- 2. 🧬 THE ARRAY ---
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 4) {
                    ForEach(0..<20, id: \.self) { index in
                        NeuralNode(
                            index: index,
                            animatedScore: animatedScore,
                            activeColor: readinessColor
                        )
                    }
                }
                
                // STATUS SUBTITLE
                Text(statusText)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(readinessColor.opacity(0.8))
            }
            
            // --- 3. ✨ NEW: PHYSIOLOGICAL INSIGHT BOX ---
            VStack(alignment: .leading, spacing: 6) {
                Text("SYSTEM INSIGHT: NEURAL STATE")
                    .font(.system(size: 9, weight: .black, design: .monospaced))
                    .foregroundStyle(ColorTheme.prime)
                
                Text("This metric fuses your autonomic nervous system (HRV/RHR) with sleep architecture to gauge systemic recovery. High scores authorize high-intensity threshold work for your 4:59 min/km target. Lower scores indicate active adaptation—when fatigued, prioritize your 215g protein floor and execute strategic recovery without guilt.")
                    .font(.system(size: 11, weight: .medium, design: .default))
                    .foregroundStyle(ColorTheme.textMuted)
                    .lineSpacing(2)
            }
            .padding(.leading, 12)
            .padding(.top, 4)
            .overlay(
                Rectangle()
                    .fill(ColorTheme.prime.opacity(0.5))
                    .frame(width: 2),
                alignment: .leading
            )
        }
        .padding(16)
        .background(ColorTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(ColorTheme.surfaceBorder, lineWidth: 1)
        )
        .onAppear {
            triggerFluidAnimation()
        }
    }
    
    // MARK: - Mechanical Micro-Interactions
    private func triggerFluidAnimation() {
        animatedScore = 0.0
        
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7, blendDuration: 0.1)) {
            animatedScore = score
        }
        
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
    }
}

// MARK: - 🧱 SUB-COMPONENT: NEURAL NODE
struct NeuralNode: View {
    let index: Int
    let animatedScore: Double
    let activeColor: Color
    
    private var isActive: Bool {
        animatedScore > (Double(index) * 5.0)
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: 2, style: .continuous)
            .fill(isActive ? activeColor : ColorTheme.surfaceBorder)
            .frame(maxWidth: .infinity) // ✨ Restored height constraint!
            .opacity(isActive ? 1.0 : 0.3)
            .shadow(color: isActive ? activeColor.opacity(0.4) : .clear, radius: 2, x: 0, y: 0)
    }
}
