import SwiftUI
import Charts
import SwiftData

// MARK: - 📈 AXIOM COMPONENT: NEURAL TREND
struct NeuralTrendWidget: View {
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
                Text("NEURAL ADAPTATION TREND")
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
                    
                    // 2. Clinical trend line
                    LineMark(
                        x: .value("Date", log.date),
                        y: .value("Readiness", log.readinessScore)
                    )
                    .foregroundStyle(ColorTheme.prime)
                    .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                    
                    // 3. Data points
                    PointMark(
                        x: .value("Date", log.date),
                        y: .value("Readiness", log.readinessScore)
                    )
                    .foregroundStyle(ColorTheme.prime)
                    .symbolSize(30)
                }
                .chartYScale(domain: 0...100)
                // ✨ THE POLISH: Fluid chart morphing when changing time horizons
                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: timeHorizon)
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
            
            // --- ✨ THE POLISH: PHYSIOLOGICAL INSIGHT BOX ---
            VStack(alignment: .leading, spacing: 6) {
                Text("SYSTEM INSIGHT: ADAPTATION HORIZON")
                    .font(.system(size: 9, weight: .black, design: .monospaced))
                    .foregroundStyle(ColorTheme.prime)
                
                Text("This plot maps your systemic recovery capacity. Sustained downward gradients indicate active neuro-muscular adaptation. If the baseline drops below 40%, deploy strategic recovery protocols to secure your gains and protect the 4:59 min/km pace target.")
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
