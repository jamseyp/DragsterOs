import SwiftUI
import Charts

// MARK: - 📊 COMPONENT: TIME-SERIES CHART
struct TelemetryChartCard: View {
    let title: String
    let icon: String
    let data: [(date: Date, value: Double)]
    let color: Color
    let unit: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(title)
                Spacer()
                if !data.isEmpty {
                    Text("MAX: \(Int(data.map { $0.value }.max() ?? 0)) \(unit)")
                }
            }
            .font(.system(size: 10, weight: .black, design: .monospaced))
            .foregroundStyle(color)
            
            // Chart Canvas
            if data.isEmpty {
                VStack {
                    Image(systemName: "sensor.tag.drop")
                        .font(.system(size: 20))
                    Text("NO SENSOR DATA DETECTED")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                }
                .foregroundStyle(ColorTheme.surfaceBorder)
                .frame(maxWidth: .infinity)
                .frame(height: 120)
            } else {
                Chart(data, id: \.date) { point in
                    LineMark(
                        x: .value("Time", point.date),
                        y: .value("Metric", point.value)
                    )
                    .foregroundStyle(color)
                    .lineStyle(StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
                    
                    AreaMark(
                        x: .value("Time", point.date),
                        y: .value("Metric", point.value)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [color.opacity(0.3), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                .chartXAxis(.hidden)
                .chartYAxis {
                    AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { value in
                        AxisGridLine().foregroundStyle(ColorTheme.surfaceBorder)
                        AxisValueLabel()
                            .foregroundStyle(ColorTheme.textMuted)
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                    }
                }
                .frame(height: 120)
            }
        }
        .padding(16)
        .background(ColorTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
