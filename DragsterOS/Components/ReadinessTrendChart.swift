import SwiftUI
import Charts
import SwiftData

// MARK: - 📈 COMPONENT: READINESS TREND CHART
struct ReadinessTrendChart: View {
    var logs: [TelemetryLog]
    
    // The segmented picker state
    @State private var timeHorizon: Int = 30
    
    // Computed property to filter and chronologically sort the logs
    private var chartData: [TelemetryLog] {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -timeHorizon, to: .now)!
        return logs
            .filter { $0.date >= cutoffDate }
            .sorted { $0.date < $1.date }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            // --- HEADER & TIME SELECTOR ---
            HStack {
                Text("MACRO-CYCLE TREND")
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundStyle(ColorTheme.textMuted)
                
                Spacer()
                
                // The 30/60/90 Segmented Control
                Picker("Horizon", selection: $timeHorizon) {
                    Text("30D").tag(30)
                    Text("60D").tag(60)
                    Text("90D").tag(90)
                }
                .pickerStyle(.segmented)
                .frame(width: 150)
            }
            
            // --- THE PLOT ---
            if chartData.count < 2 {
                VStack(spacing: 8) {
                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 24))
                        .foregroundStyle(ColorTheme.surfaceBorder)
                    
                    Text("CALIBRATING BASELINE")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(ColorTheme.prime)
                    
                    Text("Requires 2+ days of telemetry to plot trend.")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundStyle(ColorTheme.textMuted)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 140)
                
            } else {
                Chart(chartData) { log in
                    // 1. Glowing area underneath
                    AreaMark(
                        x: .value("Date", log.date),
                        y: .value("Readiness", log.readinessScore)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [ColorTheme.prime.opacity(0.4), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    
                    // 2. Solid tactical line
                    LineMark(
                        x: .value("Date", log.date),
                        y: .value("Readiness", log.readinessScore)
                    )
                    .foregroundStyle(ColorTheme.prime)
                    .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                    
                    // 3. Tactical dots
                    PointMark(
                        x: .value("Date", log.date),
                        y: .value("Readiness", log.readinessScore)
                    )
                    .foregroundStyle(ColorTheme.prime)
                    .symbolSize(30)
                }
                .chartYScale(domain: 0...100)
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                        AxisGridLine().foregroundStyle(ColorTheme.surfaceBorder)
                        AxisValueLabel(format: .dateTime.month().day(), centered: false)
                            .foregroundStyle(ColorTheme.textMuted)
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                    }
                }
                .chartYAxis {
                    AxisMarks(values: [0, 50, 100]) { value in
                        AxisGridLine().foregroundStyle(ColorTheme.surfaceBorder)
                        AxisValueLabel()
                            .foregroundStyle(ColorTheme.textMuted)
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                    }
                }
                .frame(height: 140)
            }
            
            // --- ✨ NEW: TACTICAL EXPLAINER BOX ---
            VStack(alignment: .leading, spacing: 6) {
                Text("SYSTEM NOTE: MACRO-CYCLE ANALYSIS")
                    .font(.system(size: 9, weight: .black, design: .monospaced))
                    .foregroundStyle(ColorTheme.prime)
                
                Text("This plot visualizes your systemic recovery capacity over the selected horizon. Sustained downward gradients indicate accumulating central nervous system (CNS) fatigue. Consider reducing kinetic load if the baseline drops below 40%.")
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
    }
}
