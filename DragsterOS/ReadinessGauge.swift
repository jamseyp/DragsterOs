import SwiftUI

struct ReadinessGauge: View {
    let score: Double // Expecting 0.0 to 10.0
    
    // Logic to determine the "System Status" color
    var statusColor: Color {
        if score >= 8 { return .green }
        if score >= 6 { return .yellow }
        return .red
    }
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                // Background Track (The "Housing")
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 15)
                
                // Active Telemetry (The "Needle")
                Circle()
                    .trim(from: 0, to: CGFloat(score / 10.0))
                    .stroke(
                        statusColor,
                        style: StrokeStyle(lineWidth: 15, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    // Pure black dashboard glow
                    .shadow(color: statusColor.opacity(0.3), radius: 10, x: 0, y: 0)
                
                // Digital Readout
                VStack(spacing: -5) {
                    Text("\(Int(score))")
                        .font(.system(size: 54, weight: .black, design: .monospaced))
                        .foregroundColor(.white)
                    
                    Text("READINESS")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.gray)
                }
            }
            .frame(width: 180, height: 180)
            
            // Status Label
            Text(score >= 7 ? "SYSTEMS NOMINAL" : "RECOVERY REQUIRED")
                .font(.system(size: 12, weight: .black))
                .foregroundColor(statusColor)
                .tracking(2)
        }
    }
}
