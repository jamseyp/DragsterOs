import SwiftUI

// 🎨 ARCHITECTURE: A highly bespoke, fluid gauge for visualizing the daily Readiness Score.
// Built for pure black dark-mode with neon accents for immediate visual hierarchy.

struct ReadinessGauge: View {
    var score: Double // The target score (0 to 100)
    
    // State to drive our fluid animations
    @State private var animatedScore: Double = 0
    @State private var isPulsing: Bool = false
    
    // 🎨 THE DESIGN: We use a premium color palette.
    // Cyan feels more modern and "electric" than a standard green for high performance.
    private var gaugeColor: Color {
        switch score {
        case 80...100: return .cyan      // Optimal / Prime
        case 50..<80: return .yellow     // Baseline / Maintenance
        default: return .red             // Depleted / High Fatigue
        }
    }
    
    var body: some View {
        ZStack {
            // 1. The Background Track
            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: 18)
            
            // 2. The Animated Telemetry Ring
            Circle()
                .trim(from: 0, to: CGFloat(animatedScore / 100.0))
                .stroke(
                    gaugeColor,
                    style: StrokeStyle(lineWidth: 18, lineCap: .round)
                )
                .rotationEffect(.degrees(-90)) // Start from the 12 o'clock position
                // The neon glow effect that breathes when optimal
                .shadow(color: gaugeColor.opacity(0.6), radius: isPulsing ? 12 : 4)
            
            // 3. Central Typography
            VStack(spacing: 2) {
                Text("\(Int(animatedScore))")
                    // Heavy, rounded typography for numbers makes data feel substantial
                    .font(.system(size: 64, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    // ✨ THE POLISH: iOS 17+ smooth numeric counting transition
                    .contentTransition(.numericText())
                
                Text("READINESS")
                    // Monospaced fonts for labels give that clinical, data-driven aesthetic
                    .font(.system(.caption, design: .monospaced, weight: .bold))
                    .foregroundStyle(.white.opacity(0.6))
                    .tracking(2.0) // Added tracking (letter spacing) for elegance
            }
        }
        .frame(width: 240, height: 240)
        .padding()
        .onAppear {
            triggerFluidAnimation()
        }
    }
    
    // ✨ THE POLISH: Bringing the data to life
    private func triggerFluidAnimation() {
        // Prepare the mechanical haptic engine
        let impact = UIImpactFeedbackGenerator(style: .rigid)
        impact.prepare()
        
        // 1. The Spring Fill: A highly damped spring so it flies up and settles firmly
        withAnimation(.spring(response: 1.2, dampingFraction: 0.75, blendDuration: 0)) {
            animatedScore = score
        }
        
        // 2. The Neon Pulse: If the score is high, give it a subtle breathing glow
        if score >= 80 {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                isPulsing.toggle()
            }
        }
        
        // 3. The Tactile Feedback: Fire a rigid 'click' right as the animation settles
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            impact.impactOccurred(intensity: 0.9)
        }
    }
}

// MARK: - Canvas Preview
#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack(spacing: 40) {
            ReadinessGauge(score: 88) // Test Optimal
            ReadinessGauge(score: 65) // Test Baseline
        }
    }
}
