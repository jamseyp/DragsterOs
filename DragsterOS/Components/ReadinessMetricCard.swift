import SwiftUI

// 🎨 READINESS: Numeric high-fidelity readout
struct ReadinessMetricCard: View {
    let score: Int
    var color: Color { score > 70 ? .green : (score > 45 ? .yellow : .red) }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("READINESS")
                .font(.system(size: 10, weight: .black, design: .monospaced))
                .tracking(1.5)
                .foregroundColor(.gray)
            
            Spacer(minLength: 4)
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(score)")
                    .font(.system(size: 44, weight: .heavy, design: .monospaced))
                    .foregroundColor(.white)
                Text("%")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(color)
            }
            
            Spacer(minLength: 4)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(score > 70 ? "OPTIMAL" : (score > 45 ? "STABLE" : "RECOVERY"))
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(color)
                
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.1)).frame(height: 3)
                    Capsule()
                        .fill(color)
                        .frame(width: 40, height: 3) // Static for now
                }
            }
        }
        .padding(16)
        .frame(height: 140) // Anchored to match Efficiency
        .background(Color(white: 0.08))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
    }
}

