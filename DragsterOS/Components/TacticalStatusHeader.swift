import SwiftUI

// MARK: - 🚨 COMPONENT: TACTICAL STATUS HEADER
struct TacticalStatusHeader: View {
    @State private var isPulsing = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("DRAGSTER OS // v2.3")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(ColorTheme.textMuted)
                    
                    Text("COMMAND CENTER")
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .foregroundStyle(ColorTheme.textPrimary)
                }
                
                Spacer()
                
                // Pulsing Live Indicator
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 6, height: 6)
                        .opacity(isPulsing ? 1.0 : 0.3)
                    
                    Text("LIVE LINK")
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                        .foregroundStyle(ColorTheme.textPrimary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(ColorTheme.surface)
                .clipShape(Capsule())
            }
            .padding(.horizontal)
            .padding(.top, 10)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }
            
            // Subtle "Scanner" line at bottom of header
            Rectangle()
                .fill(LinearGradient(colors: [ColorTheme.prime.opacity(0.5), .clear], startPoint: .leading, endPoint: .trailing))
                .frame(height: 1)
                .padding(.top, 12)
        }
    }
}
