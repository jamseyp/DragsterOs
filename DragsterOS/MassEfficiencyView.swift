import SwiftUI
import SwiftData
import Charts

struct MassEfficiencyView: View {
    // 🗄️ PERSISTENCE
    @Query(sort: \ChassisLog.date, order: .forward) private var history: [ChassisLog]
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                
                if history.isEmpty {
                    ContentUnavailableView(
                        "NO HARDWARE SCANS DETECTED",
                        systemImage: "chart.xyaxis.line",
                        description: Text("Initiate a Hardware Scan from the Chassis Log to generate performance vectors.")
                    )
                    .foregroundStyle(ColorTheme.prime)
                    .padding(.top, 100)
                } else {
                    
                    // 📊 1. POWER TO WEIGHT VECTOR
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("POWER:MASS RATIO TREND")
                                .font(.system(size: 10, weight: .black, design: .monospaced))
                                .foregroundStyle(ColorTheme.textMuted)
                            Spacer()
                            if let latest = history.last {
                                Text(String(format: "CURRENT: %.2f W/kg", latest.powerToWeight))
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundStyle(.orange)
                            }
                        }
                        
                        Chart(history) { log in
                            LineMark(
                                x: .value("Date", log.date),
                                y: .value("W/kg", log.powerToWeight)
                            )
                            .interpolationMethod(.monotone)
                            .foregroundStyle(.orange)
                            .lineStyle(StrokeStyle(lineWidth: 3))
                            
                            PointMark(
                                x: .value("Date", log.date),
                                y: .value("W/kg", log.powerToWeight)
                            )
                            .foregroundStyle(ColorTheme.background)
                            .symbolSize(60)
                            .annotation(position: .top) {
                                Text(String(format: "%.1f", log.powerToWeight))
                                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                                    .foregroundStyle(ColorTheme.textMuted)
                            }
                        }
                        .frame(height: 200)
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .day, count: 7)) { value in
                                AxisGridLine().foregroundStyle(ColorTheme.surfaceBorder)
                                AxisValueLabel(format: .dateTime.month().day(), centered: true)
                                    .foregroundStyle(ColorTheme.textMuted)
                            }
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading) { value in
                                AxisGridLine().foregroundStyle(ColorTheme.surfaceBorder)
                                AxisValueLabel().foregroundStyle(ColorTheme.textMuted)
                            }
                        }
                    }
                    .padding()
                    .background(ColorTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    // 📊 2. STRUCTURAL SYMMETRY (PARITY)
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("STRUCTURAL SYMMETRY (L/R)")
                                .font(.system(size: 10, weight: .black, design: .monospaced))
                                .foregroundStyle(ColorTheme.textMuted)
                            Spacer()
                            if let latest = history.last {
                                Text(String(format: "CURRENT: %.1f%%", latest.parityIndex))
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundStyle(latest.parityIndex > 95 ? .green : ColorTheme.critical)
                            }
                        }
                        
                        Chart(history) { log in
                            BarMark(
                                x: .value("Date", log.date),
                                y: .value("Parity", log.parityIndex)
                            )
                            .foregroundStyle(log.parityIndex > 95 ? Color.green.gradient : ColorTheme.critical.gradient)
                            .cornerRadius(4)
                            
                            // A target line representing perfect 100% symmetry
                            RuleMark(y: .value("Target", 100))
                                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                                .foregroundStyle(ColorTheme.prime)
                        }
                        .frame(height: 180)
                        .chartYScale(domain: 80...100) // Zoom in to make small imbalances visible
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                                AxisValueLabel(format: .dateTime.month().day(), centered: true)
                                    .foregroundStyle(ColorTheme.textMuted)
                            }
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading, values: [80, 85, 90, 95, 100]) { value in
                                AxisGridLine().foregroundStyle(ColorTheme.surfaceBorder)
                                AxisValueLabel().foregroundStyle(ColorTheme.textMuted)
                            }
                        }
                    }
                    .padding()
                    .background(ColorTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 20)
        }
        // ✨ THE WRAPPER IN ACTION (Handles background, header, and back button)
        .applyTacticalOS(title: "MASS & EFFICIENCY", showBack: true)
    }
}
