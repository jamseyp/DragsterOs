import SwiftUI

import SwiftUI

struct MetricCard: View {
    let title: String
    let value: String
    let color: Color // Used for the functional status accent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header: The functional label
            Text(title.uppercased())
                .font(.system(size: 10, weight: .black, design: .monospaced))
                .tracking(1.5)
                .foregroundColor(.gray)
            
            Spacer()
            
            // Value: The high-fidelity data point
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 18, weight: .heavy, design: .monospaced))
                    .foregroundColor(.white)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
                
                // Functional Accent: A small status bar at the base of the value
                Rectangle()
                    .fill(color)
                    .frame(width: 24, height: 2)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 100) // Fixed height for a perfect grid
        .background(Color(white: 0.08))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}
