import SwiftUI
import Charts

struct EnergyBalanceWidget: View {
    @State private var intake: Double = 0
    @State private var burned: Double = 0
    @State private var net: Double = 0
    @State private var history: [DailyEnergyRecord] = []
    @State private var isLoading = true
    
    private var healthManager = HealthKitManager.shared
    
    // 🧠 LOGIC: Determine the state of the fuel line
    private var fuelStatus: (label: String, color: Color, isWarning: Bool) {
        if net >= -50 { return ("MAINTENANCE", .green, false) }
        if net < -50 && net >= -500 { return ("OPTIMAL CUT", .cyan, false) }
        return ("CRITICAL DEFICIT", ColorTheme.critical, true)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("THERMODYNAMIC STATUS")
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundStyle(ColorTheme.prime)
                Spacer()
                
                // Dynamic Status Label
                Text(fuelStatus.label)
                    .font(.system(size: 8, weight: .black, design: .monospaced))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(fuelStatus.color.opacity(0.1))
                    .foregroundStyle(fuelStatus.color)
                    .clipShape(Capsule())
            }
            
            if isLoading {
                ProgressView().tint(ColorTheme.prime).frame(maxWidth: .infinity, minHeight: 150)
            } else {
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(Int(net))")
                            .font(.system(size: 36, weight: .heavy, design: .rounded))
                            .foregroundStyle(fuelStatus.color)
                        Text("NET KCAL BALANCE")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(ColorTheme.textMuted)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 8) {
                        HStack(spacing: 12) {
                            ThermodynamicIndicator(label: "INTAKE", value: "\(Int(intake))", color: .green)
                            ThermodynamicIndicator(label: "BURN", value: "\(Int(burned))", color: .orange)
                        }
                    }
                }
                
                Divider().background(ColorTheme.surfaceBorder)
                
                // 📊 14-DAY TREND CHART WITH AXIS INDICATORS
                VStack(alignment: .leading, spacing: 8) {
                    Text("14-DAY THERMODYNAMIC TREND")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundStyle(ColorTheme.textMuted)
                    
                    Chart {
                        ForEach(history) { record in
                            BarMark(
                                x: .value("Day", record.date, unit: .day),
                                y: .value("Net", record.net)
                            )
                            .foregroundStyle(record.net < -500 ? ColorTheme.critical.gradient : (record.net < -50 ? Color.cyan.gradient : Color.green.gradient))
                            .cornerRadius(2)
                        }
                        
                        // ✨ Reference Line for Safe Cut Threshold (-500)
                        RuleMark(y: .value("Threshold", -500))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
                            .foregroundStyle(ColorTheme.critical.opacity(0.3))
                            .annotation(position: .leading, alignment: .trailing) {
                                Text("-500")
                                    .font(.system(size: 7, weight: .bold, design: .monospaced))
                                    .foregroundStyle(ColorTheme.textMuted)
                                    .padding(.trailing, 4)
                            }
                    }
                    .frame(height: 100)
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day, count: 3)) { _ in
                            AxisGridLine().foregroundStyle(ColorTheme.surfaceBorder)
                            AxisValueLabel(format: .dateTime.day())
                                .foregroundStyle(ColorTheme.textMuted)
                        }
                    }
                    .chartYAxis {
                        AxisMarks(values: [0, -1000, -2000]) { value in
                            AxisGridLine().foregroundStyle(ColorTheme.surfaceBorder)
                            AxisValueLabel()
                                .foregroundStyle(ColorTheme.textMuted)
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(ColorTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .task {
            let data = await healthManager.fetchEnergyBalance()
            let historicalData = await healthManager.fetchHistoricalEnergyBalance(daysBack: 14)
            await MainActor.run {
                self.intake = data.intake
                self.burned = data.burned
                self.net = data.net
                self.history = historicalData.map { DailyEnergyRecord(date: $0.date, net: $0.net) }
                self.isLoading = false
            }
        }
    }
}
struct ThermodynamicIndicator: View {
    var label: String
    var value: String
    var color: Color
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(label)
                .font(.system(size: 8, weight: .black, design: .monospaced))
                .foregroundStyle(ColorTheme.textMuted)
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundStyle(color)
        }
    }
}

// ✨ FIXED: Struct defined at top-level for scope visibility
struct DailyEnergyRecord: Identifiable {
    let id = UUID()
    let date: Date
    let net: Double
}
