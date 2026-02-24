import SwiftUI
import Charts

// 🎨 THE CANVAS: The Performance Evolution Chart
struct PerformanceEvolutionCard: View {
    let data: [TelemetrySnapshot]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("7-DAY EVOLUTION")
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .tracking(1.5)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Text("TRENDING UP")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.green)
            }
            
            Chart(data) { snapshot in
                // The glowing area underneath
                AreaMark(
                    x: .value("Day", snapshot.day),
                    y: .value("Readiness", snapshot.readiness)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.green.opacity(0.3), Color.clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                // The crisp neon line
                LineMark(
                    x: .value("Day", snapshot.day),
                    y: .value("Readiness", snapshot.readiness)
                )
                .interpolationMethod(.catmullRom)
                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                .foregroundStyle(Color.green)
                
                // Data points
                PointMark(
                    x: .value("Day", snapshot.day),
                    y: .value("Readiness", snapshot.readiness)
                )
                .foregroundStyle(Color.white)
                .symbolSize(30)
            }
            .frame(height: 120)
            .chartXAxis {
                AxisMarks() { _ in
                    AxisValueLabel()
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.gray)
                }
            }
            .chartYAxis(.hidden) // Hide Y axis for a cleaner, minimalist look
        }
        .padding(20)
        .background(Color(white: 0.08)) // Matched to your other cards
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
    }
}
