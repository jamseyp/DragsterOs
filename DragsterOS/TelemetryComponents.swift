import SwiftUI

struct SystemReadinessHeader: View {
    let score: Int
    let status: String // e.g., "OPTIMAL", "RECOVERY REQUIRED"
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("SYSTEM READINESS")
                .font(.system(size: 14, weight: .black, design: .monospaced))
                .foregroundColor(.gray)
            
            HStack(alignment: .lastTextBaseline) {
                Text("\(score)")
                    .font(.system(size: 80, weight: .heavy, design: .monospaced))
                    .foregroundColor(score > 70 ? .green : (score > 40 ? .yellow : .red))
                
                Text("%")
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                    .foregroundColor(.gray)
                
                Spacer()
                
                Text(status)
                    .font(.system(size: 12, weight: .bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(4)
            }
        }
        .padding()
        .background(Color.black)
    }
}
