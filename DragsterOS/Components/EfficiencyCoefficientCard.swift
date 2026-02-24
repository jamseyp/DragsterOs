import SwiftUI

// 🎨 EFFICIENCY: Power-to-weight calculation
struct EfficiencyCoefficientCard: View {
    let ratio: Double
    let weight: Double
    let watts: Int
    var onUpdateTap: () -> Void // 👈 THE NEW INTERACTIVE HOOK
    
    var body: some View {
        Button(action: onUpdateTap) {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                Text("EFFICIENCY")
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .tracking(1.5)
                    .foregroundColor(.gray)
                
                Spacer(minLength: 4)
                
                // The Hero Ratio
                VStack(alignment: .leading, spacing: -2) {
                    Text(String(format: "%.2f", ratio))
                        .font(.system(size: 38, weight: .heavy, design: .monospaced))
                        .foregroundColor(.white)
                        .minimumScaleFactor(0.8)
                    
                    Text("W/KG")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.cyan)
                }
                
                Spacer(minLength: 4)
                
                // Footnote Stats
                HStack(spacing: 8) {
                    Label("\(String(format: "%.1f", weight))kg", systemImage: "scalemass")
                    Spacer()
                    Label("\(watts)W", systemImage: "bolt.fill")
                }
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(.gray)
            }
            .padding(16)
            .frame(height: 140)
            .background(Color(white: 0.08))
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
        }
        .buttonStyle(PlainButtonStyle()) // 👈 Prevents SwiftUI from turning the text blue
    }
}
