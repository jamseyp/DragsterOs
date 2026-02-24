import SwiftUI

struct TelemetryDashboardView: View {
    @StateObject var engine = TelemetryManager()
    @Environment(\.dismiss) var dismiss
    
    let currentTask = HMTask(
        date: .now,
        activity: "Intervals: 8x600m",
        intensity: "315W - 330W",
        coachNote: "CADENCE REWIRE. 170+ SPM. Do not stomp.",
        fuelTier: "🟡 MED"
    )
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // 1. NAVIGATION
                    HStack {
                        Button(action: { dismiss() }) {
                            HStack(spacing: 6) {
                                Image(systemName: "chevron.left").font(.system(size: 14, weight: .bold))
                                Text("DASHBOARD").font(.system(size: 12, weight: .bold, design: .monospaced))
                            }
                            .foregroundColor(.gray)
                        }
                        Spacer()
                    }.padding(.top, 10)
                    
                    // 2. HEADER
                    VStack(alignment: .leading, spacing: 4) {
                        Text("SYSTEM TELEMETRY")
                            .font(.system(size: 24, weight: .black, design: .monospaced))
                            .foregroundColor(.white)
                        Rectangle().fill(Color.cyan).frame(width: 40, height: 3)
                    }
                    
                    // 3. THE PERFORMANCE GRID (Horizontal Parity)
                    performanceGrid
                    
                    // 4. DAILY MISSION
                    DailyMissionRow(task: currentTask)
                    
                    // 5. SECONDARY SENSORS
                    VStack(alignment: .leading, spacing: 12) {
                        Text("SENSORS & BIOMETRICS")
                            .font(.system(size: 10, weight: .black, design: .monospaced))
                            .tracking(1.5)
                            .foregroundColor(.gray)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            MetricCard(title: "RESTING HR", value: "\(engine.currentReport.restingHR) BPM", color: .red)
                            MetricCard(title: "HRV BIAS", value: engine.currentReport.hrvStatus, color: .blue)
                            MetricCard(title: "TOP PACE", value: engine.currentReport.intervalPace, color: .yellow)
                            MetricCard(title: "CADENCE", value: "\(engine.currentReport.averageCadence) SPM", color: .purple)
                        }
                    }
                    
                    Spacer(minLength: 50)
                }
                .padding(.horizontal)
            }
        }
        .navigationBarHidden(true)
    }
    
    // 📐 THE BALANCED GRID LOGIC
    private var performanceGrid: some View {
        HStack(alignment: .center, spacing: 12) {
            // Left: Efficiency Card
            EfficiencyCoefficientCard(
                ratio: PerformanceEngine.calculatePowerToWeight(power: Double(engine.currentReport.maxPower), weight: 96.7),
                weight: 96.7,
                watts: engine.currentReport.maxPower
            )
            .frame(maxWidth: .infinity)
            
            // Right: New Numeric Readiness Card (Replacing the Gauge)
            ReadinessMetricCard(score: Int(engine.currentReport.readinessScore))
                .frame(maxWidth: .infinity)
        }
    }
}
